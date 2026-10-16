import 'package:collection/collection.dart';

import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/component/preset_spec_keys.dart';
import '../models/component/setup_guide.dart';
import '../models/person.dart';
import 'adjustment_role.dart';
import 'component_preset_resolver.dart';
import 'setup_guide_evaluator.dart';

/// A component on the setup page whose catalog product has a setup guide.
class GuidedComponent {
  final Component component;
  final ResolvedPreset preset;

  const GuidedComponent(this.component, this.preset);

  SetupGuide get guide => preset.node.guide!;

  List<GuideRecommendation> evaluate(GuideInputs inputs, Map<String, AdjustmentValue> currentValues) =>
      evaluateSetupGuide(preset, component.adjustments, inputs, currentValues);
}

/// The components of [components] linked to a catalog product with a guide.
/// [resolve] reads a preset from the loaded catalog; null while it isn't loaded.
List<GuidedComponent> guidedComponents(
  Iterable<Component> components, {
  required ResolvedPreset? Function(Component component) resolve,
}) => [
  for (final component in components)
    if (component.preset != null)
      if (resolve(component) case final preset? when preset.node.guide != null) GuidedComponent(component, preset),
];

/// The [guidedComponents] that get the setup guide card: those without any
/// recorded value yet, since the card is for setting the first values.
List<GuidedComponent> guidedComponentsWithoutValues(
  Iterable<Component> components, {
  required ResolvedPreset? Function(Component component) resolve,
  required Map<String, AdjustmentValue> previousValues,
}) => guidedComponents(
  components.where((component) => component.adjustments.none((a) => previousValues.containsKey(a.id))),
  resolve: resolve,
);

/// The rider's weight and riding style as [person]'s attributes hold them:
/// the value entered on this setup, else the last recorded one, else
/// [fallbackWeight] (kg), entered on the setup guide card only.
GuideInputs guideInputsFor(
  Person? person, {
  required Map<String, AdjustmentValue> values,
  required Map<String, AdjustmentValue> previousValues,
  double? fallbackWeight,
}) {
  AdjustmentValue? valueOf(String role) {
    final adjustment = person?.adjustments.firstWhereOrNull((a) => adjustmentRole(a) == role);
    return adjustment == null ? null : values[adjustment.id] ?? previousValues[adjustment.id];
  }

  final weightAdjustment = person?.adjustments.firstWhereOrNull((a) => adjustmentRole(a) == 'riding_weight');
  final weightUnit = switch (weightAdjustment?.unit) {
    final KnownUnit unit when unit.quantity == UnitQuantity.mass => unit,
    _ => null,
  };
  final recorded = weightUnit == null ? null : valueOf('riding_weight')?.asNum?.toDouble();
  final weight = recorded ?? fallbackWeight;
  final style = switch (valueOf(kRidingStyleKey)) {
    CategoricalValue(:final options) when options.length == 1 => GuideRidingStyle.values.firstWhereOrNull(
      (style) => style.label == options.single,
    ),
    _ => null,
  };
  return GuideInputs(
    riderWeight: weight,
    riderWeightUnit: (recorded == null && fallbackWeight != null ? null : weightUnit) ?? const GuideInputs().riderWeightUnit,
    ridingStyle: style,
  );
}

/// What **Apply all** writes for [guided]: every applicable recommendation.
///
/// The targets' own current values are left out of the evaluation, so a rule
/// reading another adjuster (rebound keyed by pressure) reads the pressure
/// being applied, not the one it replaces.
Map<Adjustment, AdjustmentValue> guideValuesToApply(
  GuidedComponent guided,
  GuideInputs inputs,
  Map<String, AdjustmentValue> currentValues,
) {
  final targets = guided.evaluate(inputs, currentValues).map((r) => r.adjustment.id).toSet();
  final untouched = {
    for (final entry in currentValues.entries)
      if (!targets.contains(entry.key)) entry.key: entry.value,
  };
  return {
    for (final recommendation in guided.evaluate(inputs, untouched)) recommendation.adjustment: ?recommendation.value,
  };
}

/// The setup notes line **Apply all** leaves: `Started from recommended values
/// (FOX 38 owner's manual (2027)) · 82 kg`.
String guideNotesLine(Iterable<SetupGuide> guides, GuideInputs inputs) {
  final weight = inputs.riderWeight;
  return [
    'Started from recommended values (${guides.map((guide) => guide.label).toSet().join(', ')})',
    if (weight != null) '${formatSpecNumber(double.parse(weight.toStringAsFixed(1)))} ${inputs.riderWeightUnit.label}',
  ].join(' · ');
}

/// [notes] with [line] on a line of its own, unless it already ends with it.
String appendNotesLine(String notes, String line) {
  final trimmed = notes.trimRight();
  if (trimmed.endsWith(line)) return notes;
  return trimmed.isEmpty ? line : '$trimmed\n$line';
}
