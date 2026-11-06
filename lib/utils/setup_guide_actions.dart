import 'package:collection/collection.dart';

import '../l10n/enum_labels.dart';
import '../l10n/l10n.dart';
import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/component/setup_guide.dart';
import '../models/person.dart';
import 'adjustment_role.dart';
import 'component_preset_resolver.dart';
import 'localized_number.dart';
import 'setup_guide_evaluator.dart';

/// A component on the setup page whose catalog product has a setup guide.
class GuidedComponent {
  final Component component;
  final ResolvedPreset preset;

  const GuidedComponent(this.component, this.preset);

  SetupGuide get guide => preset.product!.guide!;

  List<GuideRecommendation> evaluate(GuideInputs inputs, Map<String, AdjustmentValue> currentValues, AppLocalizations l10n) =>
      evaluateSetupGuide(preset, component.adjustments, inputs, currentValues, l10n);
}

/// The components of [components] linked to a catalog product with a guide;
/// a link that stops at a group doesn't count, see [evaluateSetupGuide].
/// [resolve] reads a preset from the loaded catalog; null while it isn't loaded.
List<GuidedComponent> guidedComponents(
  Iterable<Component> components, {
  required ResolvedPreset? Function(Component component) resolve,
}) => [
  for (final component in components)
    if (component.preset != null)
      if (resolve(component) case final preset? when preset.product?.guide != null) GuidedComponent(component, preset),
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
    CategoricalValue(:final options) when options.length == 1 => guideRidingStyleOfOption(options.single),
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
  AppLocalizations l10n,
) {
  final targets = guided.evaluate(inputs, currentValues, l10n).map((r) => r.adjustment.id).toSet();
  final untouched = {
    for (final entry in currentValues.entries)
      if (!targets.contains(entry.key)) entry.key: entry.value,
  };
  return {
    for (final recommendation in guided.evaluate(inputs, untouched, l10n)) recommendation.adjustment: ?recommendation.value,
  };
}

/// The setup notes line **Apply all** leaves: `Started from recommended values
/// (FOX 38 owner's manual (2027)) · 82 kg`, in the language of [l10n]. The line
/// is stored with the notes like typed text, so it keeps the language it was
/// written in. With [sourceLabels] the guides are named by their English label,
/// as a line written before the catalog changed language names them.
String guideNotesLine(
  Iterable<SetupGuide> guides,
  GuideInputs inputs,
  AppLocalizations l10n, {
  bool sourceLabels = false,
}) {
  final weight = inputs.riderWeight;
  return [
    l10n.guideNotesLine(guides.map((guide) => sourceLabels ? guide.sourceLabel : guide.label).toSet().join(', ')),
    if (weight != null)
      '${formatLocalizedDouble(double.parse(weight.toStringAsFixed(1)), locale: l10n.localeName)} ${inputs.riderWeightUnit.label}',
  ].join(' · ');
}

/// [notes] with [line] on a line of its own, unless it already ends with it or
/// with one of its [equivalents] (the same line in another language).
String appendNotesLine(String notes, String line, {Iterable<String> equivalents = const []}) {
  final trimmed = notes.trimRight();
  if ([line, ...equivalents].any(trimmed.endsWith)) return notes;
  return trimmed.isEmpty ? line : '$trimmed\n$line';
}
