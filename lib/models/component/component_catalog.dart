import '../adjustment/adjustment.dart';
import 'component.dart';
import 'component_preset.dart';
import 'preset_spec_keys.dart';

/// In-memory model of the generic component catalog (`data/component_presets/`):
/// a node tree names the product, option axes configure it.

/// Defers instantiation to selection time
class PresetAdjustmentSpec {
  final Map<String, dynamic> raw;

  const PresetAdjustmentSpec(this.raw);

  Adjustment build() => Adjustment.fromYaml(raw);
}

/// One brand file, e.g. `fork/fox.yaml`.
class BrandCatalog {
  final String brand;

  /// Slug of [brand], persisted as [ComponentPreset.brand].
  final String id;
  final ComponentType componentType;
  final List<CatalogNode> nodes;

  const BrandCatalog({
    required this.brand,
    required this.id,
    required this.componentType,
    required this.nodes,
  });
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
  final String? years;
  final String? url;
  final String? note;

  const CatalogNode({
    required this.id,
    required this.label,
    required this.level,
    this.draft = false,
    this.specs = Specs.empty,
    this.category,
    this.years,
    this.url,
    this.note,
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
    super.note,
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
    super.note,
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

  const OptionValue({
    required this.id,
    required this.label,
    this.description,
    this.specs = Specs.empty,
    this.adjustments = const [],
  });
}

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
