import '../adjustment/adjustment.dart';

/// A manufacturer's rider setup guide as catalog data: one rule per published
/// column, each recommending a value for one adjuster of the product.
class SetupGuide {
  final String id;
  final String label;
  final String source;

  /// In dependency order: a rule reading another adjuster as its input comes
  /// after every rule that targets that adjuster.
  final List<GuideRule> rules;

  const SetupGuide({
    required this.id,
    required this.label,
    required this.source,
    required this.rules,
  });
}

class GuideRule {
  /// Adjuster id within the product (`pressure`, `lsr`, `sag`).
  final String target;

  /// The unit [output] is authored in; null for clicks, counts and SAG in %.
  final AdjustmentUnit? unit;

  /// What [LookupOutput] rows are keyed by; null for [ConstantOutput] and
  /// [RangeOutput].
  final GuideInput? input;

  /// The unit numeric row keys are authored in, for inputs that have one.
  final KnownUnit? inputUnit;

  /// Preset-map key (level, option axis or `riding_style`) → accepted values.
  /// Empty matches every product the guide is attached to.
  final Map<String, List<Object>> when;
  final GuideOutput output;
  final String? note;

  const GuideRule({
    required this.target,
    this.unit,
    this.input,
    this.inputUnit,
    this.when = const {},
    required this.output,
    this.note,
  });

  /// Of two rules for one target that both match, the more specific wins.
  int get specificity => when.length;
}

/// The rider-side `when:` key and [GuideInputKey.ridingStyle]'s values.
const String kRidingStyleKey = 'riding_style';

/// Brand vocabularies are mapped onto these in the YAML. [label] is the
/// matching option of the `person:riding_style` template.
enum GuideRidingStyle {
  comfort('Comfort'),
  balanced('Balanced'),
  race('Race');

  final String label;
  const GuideRidingStyle(this.label);
}

sealed class GuideInput {
  const GuideInput();

  /// As authored under `input:`.
  String get id;

  /// Numeric inputs take brackets and points as row keys, the others only
  /// literal values.
  bool get numeric;
}

/// Something about the rider, entered on the setup page.
final class RiderGuideInput extends GuideInput {
  final GuideInputKey key;

  const RiderGuideInput(this.key);

  @override
  String get id => key.id;

  @override
  bool get numeric => key.numeric;
}

/// An option axis (`travel_mm`, `size`) or a numeric spec (`stroke_mm`) of
/// the configured product, as registered in `preset_spec_keys.dart`.
final class PresetGuideInput extends GuideInput {
  @override
  final String id;

  @override
  final bool numeric;

  const PresetGuideInput(this.id, {required this.numeric});
}

/// Reads the current value of another adjuster of the same component, e.g.
/// rebound keyed by air pressure.
final class AdjusterGuideInput extends GuideInput {
  final String adjusterId;

  const AdjusterGuideInput(this.adjusterId);

  @override
  String get id => adjusterId;

  @override
  bool get numeric => true;
}

/// The rider inputs.
enum GuideInputKey {
  riderWeight('rider_weight', numeric: true, quantity: UnitQuantity.mass),
  ridingStyle(kRidingStyleKey);

  final String id;
  final bool numeric;

  /// Rows keyed by this input name their unit in `input_unit`.
  final UnitQuantity? quantity;

  const GuideInputKey(this.id, {this.numeric = false, this.quantity});
}

sealed class GuideOutput {
  const GuideOutput();
}

/// A base tune or any other value that depends on no input.
final class ConstantOutput extends GuideOutput {
  final GuideCell value;

  const ConstantOutput(this.value);
}

final class LookupOutput extends GuideOutput {
  /// Sorted ascending for numeric inputs, in authored order otherwise.
  final List<GuideRow> rows;

  const LookupOutput(this.rows);
}

/// A band such as SAG 15–20 %. Its midpoint is applied, unless [comfortAt]
/// lets the riding style pick a point in it.
final class RangeOutput extends GuideOutput {
  final num min;
  final num max;

  /// The end a `comfort` rider gets (`race` the other, `balanced` the
  /// midpoint): [GuideAnchor.max] for SAG. Null where the style has no say.
  final GuideAnchor? comfortAt;

  const RangeOutput(this.min, this.max, {this.comfortAt});
}

class GuideRow {
  final GuideRowKey key;
  final GuideCell cell;

  const GuideRow(this.key, this.cell);
}

sealed class GuideRowKey {
  const GuideRowKey();
}

/// A half-open bracket `[from, to)`. A null end is open: `<to` or `from+`.
final class GuideBracket extends GuideRowKey {
  final num? from;
  final num? to;

  const GuideBracket(this.from, this.to);
}

/// A literal point: a number for numeric inputs, a value id otherwise.
final class GuidePoint extends GuideRowKey {
  final Object value;

  const GuidePoint(this.value);
}

/// An authored value in the source's terms. The evaluator turns it into an
/// `AdjustmentValue` of the target adjustment, so every cell can be applied.
sealed class GuideCell {
  const GuideCell();
}

/// A single position on a number scale: what a band end can be.
sealed class GuideScalar extends GuideCell {
  const GuideScalar();
}

final class GuideNumber extends GuideScalar {
  final num value;

  const GuideNumber(this.value);
}

enum GuideAnchor { min, max, mid }

/// A position relative to the target adjuster's range, resolved against the
/// rider's adjustment: `min+2`, `max-3`, `mid`. Fits any adjuster with a
/// published range, e.g. a damper dial's end stops (`22-Open` is `[22, max]`).
final class GuideRangeRef extends GuideScalar {
  final GuideAnchor anchor;

  /// Added to the anchor, in the rule's `unit`.
  final num offset;

  const GuideRangeRef(this.anchor, [this.offset = 0]);
}

/// A published band (`85-95 psi`, `22-Open` as `[22, max]`).
final class GuideBand extends GuideCell {
  final GuideScalar min;
  final GuideScalar max;

  const GuideBand(this.min, this.max);
}

/// An option of a categorical adjuster.
final class GuideOption extends GuideCell {
  final String option;

  const GuideOption(this.option);
}

/// The state of a boolean adjuster.
final class GuideBoolean extends GuideCell {
  final bool value;

  const GuideBoolean(this.value);
}
