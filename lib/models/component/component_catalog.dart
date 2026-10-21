import '../adjustment/adjustment.dart';
import '../task/task_template.dart';
import 'component.dart';
import 'component_preset.dart';
import 'preset_spec_keys.dart';
import 'setup_guide.dart';
import 'year_span.dart';

/// In-memory model of the generic component catalog (`data/component_presets/`):
/// a node tree names the product, option axes configure it.

/// The id of the SAG adjuster the application injects for forks and shocks.
const String kSagAdjusterId = 'sag';

/// Defers instantiation to selection time
class PresetAdjustmentSpec {
  final Map<String, dynamic> raw;

  /// `<type>:<id>`, where the id is the authored `id:`, else the slug of `name`.
  /// The same key space as the generic templates (`fork:hsc`), stamped onto the
  /// built adjustment as [Adjustment.presetKey].
  final String presetKey;

  const PresetAdjustmentSpec(this.raw, {required this.presetKey});

  String get id => presetKey.substring(presetKey.indexOf(':') + 1);

  Adjustment build() =>
      Adjustment.fromYaml({...raw}..remove('id')).copyWith(presetKey: presetKey);

  /// [build] as it was, or will be, with [field] authored as [value].
  Adjustment buildWith(CatalogFixField field, Object? value) =>
      Adjustment.fromYaml({...raw, field.key: value}..remove('id')).copyWith(presetKey: presetKey);
}

/// One brand file, e.g. `fork/fox.yaml`.
class BrandCatalog {
  final String brand;

  /// Slug of [brand], persisted as [ComponentPreset.brand].
  final String id;
  final ComponentType componentType;
  final List<CatalogNode> nodes;

  /// Node paths that were restructured, see [MovedPath].
  final List<MovedPath> moved;

  /// The file's data revision, persisted on each component built from it.
  final int revision;

  /// What changed for components built from an older revision, oldest first.
  final List<CatalogChange> changes;

  const BrandCatalog({
    required this.brand,
    required this.id,
    required this.componentType,
    required this.nodes,
    this.moved = const [],
    this.revision = 1,
    this.changes = const [],
  });

  /// [ids] with the longest matching `moved:` prefix rewritten; null when no
  /// redirect applies.
  List<String>? redirect(List<String> ids) {
    MovedPath? best;
    for (final entry in moved) {
      if (entry.from.length > ids.length || (best != null && entry.from.length <= best.from.length)) continue;
      if (Iterable<int>.generate(entry.from.length).every((i) => entry.from[i] == ids[i])) best = entry;
    }
    return best == null ? null : [...best.to, ...ids.skip(best.from.length)];
  }
}

/// A `moved:` entry: the node path [from] no longer exists, [to] is where it
/// lives now. Both are node ids from the top-level node down; [from] may stop
/// at a group, which moves its whole subtree.
class MovedPath {
  final List<String> from;
  final List<String> to;

  const MovedPath({required this.from, required this.to});
}

/// A `changes:` entry: what [revision] of a brand file changed for the
/// components [when] matches, as the guide rules' `when:` does. An empty [when]
/// matches every component of the file.
sealed class CatalogChange {
  final int revision;
  final Map<String, List<Object>> when;

  const CatalogChange({required this.revision, this.when = const {}});
}

/// A correction of the adjustments built from [adjuster], applied without
/// asking. A result that would change an adjustment's identity or type, or
/// leave a recorded value outside its range, is discarded.
sealed class CatalogFix extends CatalogChange {
  final String adjuster;

  const CatalogFix({required super.revision, super.when, required this.adjuster});
}

/// Sets [field] to what the catalog builds from [to] wherever the rider's
/// adjustment still has what it built from [from].
final class CatalogFieldFix extends CatalogFix {
  final CatalogFixField field;
  final Object? from;
  final Object? to;

  const CatalogFieldFix({
    required super.revision,
    super.when,
    required super.adjuster,
    required this.field,
    required this.from,
    required this.to,
  });
}

/// A correction too involved for a field fix, written in Dart and registered
/// under [stepId] in `catalogMigrationSteps`.
final class CatalogStepFix extends CatalogFix {
  final String stepId;
  final CatalogMigrationStep step;

  const CatalogStepFix({
    required super.revision,
    super.when,
    required super.adjuster,
    required this.stepId,
    required this.step,
  });
}

/// The corrected [CatalogStepContext.adjustment], or null to leave it as it is.
typedef CatalogMigrationStep = Adjustment? Function(CatalogStepContext context);

/// What a [CatalogMigrationStep] decides on.
class CatalogStepContext {
  /// The rider's adjustment built from the fix's adjuster, possibly edited.
  final Adjustment adjustment;

  /// What the catalog builds for that adjuster now; its id is a fresh one.
  final Adjustment catalog;

  /// Every value recorded for [adjustment]; the result has to keep them valid.
  final List<AdjustmentValue> recorded;

  const CatalogStepContext({required this.adjustment, required this.catalog, required this.recorded});
}

/// A change the rider reviews in the merge sheet: a new adjuster, a range, a type.
final class CatalogReview extends CatalogChange {
  /// Rider-facing, shown with the update hint.
  final String summary;

  const CatalogReview({required super.revision, super.when, required this.summary});
}

/// Adjuster fields a [CatalogFieldFix] may change.
enum CatalogFixField {
  displayName('name'),
  notes('notes'),
  min('min'),
  max('max'),
  visualization('visualization'),
  dialColor('dialColor'),
  dialSize('dialSize');

  /// The adjustment key in the YAML.
  final String key;

  const CatalogFixField(this.key);

  /// Null where [adjustment] has no such field.
  Object? read(Adjustment adjustment) => switch ((this, adjustment)) {
    (displayName, _) => adjustment.name,
    (notes, _) => adjustment.notes,
    (min, final StepAdjustment step) => step.min,
    (min, final NumericalAdjustment numerical) => numerical.min,
    (max, final StepAdjustment step) => step.max,
    (max, final NumericalAdjustment numerical) => numerical.max,
    (visualization, final StepAdjustment step) => step.visualization,
    (dialColor, final StepAdjustment step) => step.dialColor,
    (dialSize, final StepAdjustment step) => step.dialSize,
    _ => null,
  };

  Adjustment write(Adjustment adjustment, Object? value) => switch ((this, adjustment)) {
    (displayName, _) => adjustment.copyWith(name: value),
    (notes, _) => adjustment.copyWith(notes: value),
    (min, final StepAdjustment step) => step.copyWith(min: value),
    (min, final NumericalAdjustment numerical) => numerical.copyWith(min: value),
    (max, final StepAdjustment step) => step.copyWith(max: value),
    (max, final NumericalAdjustment numerical) => numerical.copyWith(max: value),
    (visualization, final StepAdjustment step) => step.copyWith(visualization: value),
    (dialColor, final StepAdjustment step) => step.copyWith(dialColor: value),
    (dialSize, final StepAdjustment step) => step.copyWith(dialSize: value),
    _ => adjustment,
  };
}

/// One step of a brand's hierarchy (model, generation, trim, version, mount …).
///
/// Inheritable fields hold the effective value: the parser has already applied
/// the nearest declaration, and merged [specs] per key.
sealed class CatalogNode {
  /// Persisted as `<level>: <id>`, so both are frozen once rolled out.
  final String id;
  final String label;
  final String level;

  /// Hidden from selection, but still resolvable for a saved component.
  final bool draft;
  final Specs specs;
  final String? category;
  final YearSpan? years;
  final String? url;

  /// Official setup or tuning guide, the link the generated notes carry.
  final String? setupGuide;

  final SetupGuide? guide;
  final String? note;

  /// Adjusters the product is known to have but that cannot be declared yet;
  /// the rider is told to add them by hand.
  final List<String> missingAdjustments;

  /// Task template overrides by role key, inherited per key.
  final Map<String, TaskTemplateOverride> tasks;

  const CatalogNode({
    required this.id,
    required this.label,
    required this.level,
    this.draft = false,
    this.specs = Specs.empty,
    this.category,
    this.years,
    this.url,
    this.setupGuide,
    this.guide,
    this.note,
    this.missingAdjustments = const [],
    this.tasks = const {},
  });
}

final class CatalogGroup extends CatalogNode {
  final List<CatalogNode> children;

  const CatalogGroup({
    required super.id,
    required super.label,
    required super.level,
    super.draft,
    super.specs,
    super.category,
    super.years,
    super.url,
    super.setupGuide,
    super.guide,
    super.note,
    super.missingAdjustments,
    super.tasks,
    required this.children,
  });
}

/// A leaf node: what the user ends up selecting.
final class CatalogProduct extends CatalogNode {
  final List<PresetAdjustmentSpec> adjustments;

  /// Keyed by axis id, in authored order.
  final Map<String, OptionAxis> options;

  const CatalogProduct({
    required super.id,
    required super.label,
    required super.level,
    super.draft,
    super.specs,
    super.category,
    super.years,
    super.url,
    super.setupGuide,
    super.guide,
    super.note,
    super.missingAdjustments,
    super.tasks,
    this.adjustments = const [],
    this.options = const {},
  });
}

class OptionAxis {
  final OptionAxisKey key;
  final List<OptionValue> values;

  const OptionAxis({required this.key, required this.values});

  String get id => key.id;

  /// The adjustment list depends on the choice, so it cannot be skipped.
  bool get required => values.any((value) => value.adjustments.isNotEmpty);
}

class OptionValue {
  /// Persisted as `<axis id>: <id>`, so it is frozen once rolled out. A string
  /// for defined values and sizes (`grip_x2`, `210x55`), the spec value itself
  /// for literal axes (`160`).
  final Object id;
  final String label;
  final String? description;
  final Specs specs;
  final List<PresetAdjustmentSpec> adjustments;

  /// Adjusters the value is known to have but that cannot be declared yet; the
  /// rider is told to add them by hand.
  final List<String> missingAdjustments;

  /// Changes to the node's task overrides by role key; `null` restores the
  /// generic template.
  final Map<String, TaskTemplateOverride?> tasks;

  const OptionValue({
    required this.id,
    required this.label,
    this.description,
    this.specs = Specs.empty,
    this.adjustments = const [],
    this.missingAdjustments = const [],
    this.tasks = const {},
  });
}

/// [base] with [changes] applied per key; a `null` change removes the key.
Map<String, TaskTemplateOverride> mergeTaskOverrides(
  Map<String, TaskTemplateOverride> base,
  Map<String, TaskTemplateOverride?> changes,
) => {
  for (final MapEntry(:key, :value) in base.entries)
    if (!changes.containsKey(key)) key: value,
  for (final MapEntry(:key, :value) in changes.entries) key: ?value,
};

/// Form-fill data for a component created from the catalog.
class CatalogApplication {
  final String name;
  final ComponentType componentType;
  final String notes;
  final List<Adjustment> adjustments;

  /// What the component persists: the node path plus the chosen options.
  final ComponentPreset preset;

  const CatalogApplication({
    required this.name,
    required this.componentType,
    required this.notes,
    required this.adjustments,
    required this.preset,
  });
}
