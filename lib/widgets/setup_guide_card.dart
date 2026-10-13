import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/component/setup_guide.dart';
import '../theme.dart';
import '../utils/adjustment_role.dart';
import '../utils/setup_guide_actions.dart';
import '../utils/url.dart';
import 'dialogs/dialog_action.dart';
import 'items/card_header_tile.dart';

/// One guided component's recommendations on the card.
class SetupGuideSection {
  final GuidedComponent guided;
  final List<GuideRecommendation> recommendations;

  const SetupGuideSection(this.guided, this.recommendations);
}

/// Recommended first values for components linked to a catalog product with a
/// setup guide. Tapping a row applies its value; [onApplyAll] applies every one.
class SetupGuideCard extends StatelessWidget {
  final List<SetupGuideSection> sections;
  final GuideInputs inputs;
  final void Function(GuideRecommendation recommendation) onApply;

  /// Null while there is nothing left to apply.
  final VoidCallback? onApplyAll;

  const SetupGuideCard({
    super.key,
    required this.sections,
    required this.inputs,
    required this.onApply,
    required this.onApplyAll,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHeaderTile(
            color: scheme.surfaceContainerHighest,
            child: ListTile(
              leading: const Icon(Icons.tips_and_updates_outlined),
              title: const Text("Setup Guide", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_inputsText(inputs)),
              trailing: IconButton(
                onPressed: () => _showExplanation(context, sections),
                icon: const Icon(Icons.info_outline),
                tooltip: "About recommended values",
              ),
            ),
          ),
          for (final section in sections) ...[
            _SectionHeader(section: section),
            for (final recommendation in section.recommendations)
              _RecommendationRow(
                recommendation: recommendation,
                component: section.guided.component,
                hasRiderWeight: inputs.riderWeight != null,
                riderWeightUnit: inputs.riderWeightUnit,
                onApply: onApply,
              ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              spacing: 12,
              children: [
                Expanded(child: Text("A starting point, check your manual.", style: mutedStyle)),
                FilledButton.tonalIcon(
                  onPressed: onApplyAll,
                  icon: const Icon(Icons.done_all),
                  label: const Text("Apply all"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final SetupGuideSection section;

  const _SectionHeader({required this.section});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final component = section.guided.component;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        spacing: 8,
        children: [
          Icon(component.componentType.getIconData(), size: 18, color: theme.colorScheme.onSurfaceVariant),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component.name,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Based on: ${section.guided.guide.label}",
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  final GuideRecommendation recommendation;
  final Component component;
  final bool hasRiderWeight;
  final KnownUnit riderWeightUnit;
  final void Function(GuideRecommendation recommendation) onApply;

  const _RecommendationRow({
    required this.recommendation,
    required this.component,
    required this.hasRiderWeight,
    required this.riderWeightUnit,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final highlights = theme.extension<ValueHighlightColors>();
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final adjustment = recommendation.adjustment;
    final value = recommendation.value;
    final deviation = recommendation.deviation;
    final canApply = value != null && recommendation.current != value;
    final note = recommendation.rule.note;
    final reverseLookup = hasRiderWeight ? null : _reverseLookupText(recommendation, riderWeightUnit);

    final (String status, Color? statusColor) = switch ((value, deviation)) {
      (null, _) => ("", null),
      (_, null) => ("Not set", scheme.onSurfaceVariant),
      (_, GuideDeviation(onGuide: true)) => ("On guide", highlights?.initial),
      (_, GuideDeviation(:final delta)) => (
        "Now ${guideValueText(adjustment, recommendation.current!)}${delta == null ? '' : ' (${guideSignedDelta(delta)})'}",
        highlights?.changed,
      ),
    };

    return InkWell(
      onTap: canApply ? () => onApply(recommendation) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adjustment.name,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    guideDetailText(recommendation, component),
                    style: mutedStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (reverseLookup != null)
                    Text(reverseLookup, style: mutedStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (note != null) Text(note, style: mutedStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Flexible(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value == null ? "–" : guideValueText(adjustment, value),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (status.isNotEmpty)
                    Text(
                      status,
                      style: mutedStyle?.copyWith(color: statusColor),
                      maxLines: 2,
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _inputsText(GuideInputs inputs) {
  final weight = inputs.riderWeight;
  if (weight == null) return "Enter a riding weight on the Rider tab for weight-based values";
  return [
    "Recommended values for ${_number(weight)} ${inputs.riderWeightUnit.label}",
    ?inputs.ridingStyle?.label,
  ].join(" · ");
}

String guideValueText(Adjustment adjustment, AdjustmentValue value) => switch (value) {
  NumericalValue() || StepValue() => "${value.display}${adjustment.unitSuffix()}",
  _ => value.display,
};

/// The input the value was looked up for, or why there is none.
String guideDetailText(GuideRecommendation recommendation, Component component) {
  final issue = recommendation.issue;
  if (issue == null) {
    final basis = [?recommendation.inputText, if (recommendation.interpolated) "interpolated"];
    return basis.isEmpty ? "Fixed value" : basis.join(" · ");
  }
  return switch (issue) {
    GuideIssue.missingInput => switch (recommendation.rule.input) {
      RiderGuideInput(key: GuideInputKey.riderWeight) => "Needs your riding weight",
      RiderGuideInput(key: GuideInputKey.ridingStyle) => "Needs your riding style",
      AdjusterGuideInput(:final adjusterId) =>
        "Needs a value for ${component.adjustments.firstWhereOrNull((a) => adjustmentRole(a) == adjusterId)?.name ?? adjusterId}",
      PresetGuideInput(:final id) => "Needs the component's ${id.replaceAll('_', ' ')}",
      null => "Needs more information",
    },
    GuideIssue.outsideRange => "Outside the published range",
    GuideIssue.placeholderMax => "Enter your dial's click count (max) first",
    GuideIssue.aboveMax => "Above this adjuster's maximum",
    GuideIssue.belowMin => "Below this adjuster's minimum",
    GuideIssue.incompatible => "Doesn't fit this adjuster's type or unit",
  };
}

/// "84 psi ≈ 86–91 kg": the rider weights the current value suits.
String? _reverseLookupText(GuideRecommendation recommendation, KnownUnit unit) {
  final (range, current) = (recommendation.riderWeightRange, recommendation.current);
  if (range == null || current == null) return null;
  final weights = switch ((range.min.isFinite, range.max.isFinite)) {
    (true, true) when range.min.round() == range.max.round() => _number(range.min),
    (true, true) => "${_number(range.min)}–${_number(range.max)}",
    (true, false) => "${_number(range.min)}+",
    (false, true) => "up to ${_number(range.max)}",
    (false, false) => null,
  };
  if (weights == null) return null;
  return "${guideValueText(recommendation.adjustment, current)} ≈ $weights ${unit.label}";
}

String _number(double value) => value.round().toString();

String guideSignedDelta(double delta) {
  final rounded = double.parse(delta.toStringAsFixed(1));
  final text = rounded == rounded.roundToDouble() ? rounded.abs().round().toString() : rounded.abs().toString();
  return "${rounded < 0 ? '-' : '+'}$text";
}

Future<void> _showExplanation(BuildContext context, List<SetupGuideSection> sections) {
  final guides = {for (final section in sections) section.guided.guide.id: section.guided.guide}.values;
  return showDialog<void>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog.adaptive(
        title: const Text("Recommended values"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              const Text(
                "These values are looked up for your riding weight and component in the "
                "setup guide named below. They are a starting point, check your manual.",
              ),
              const Text(
                "Between two published rows the value is interpolated. Outside the published "
                "range there is no value. A value counts as on guide within half the step to "
                "the neighbouring row, inside a published band, or when it matches a fixed value.",
              ),
              for (final guide in guides)
                Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.menu_book_outlined),
                    title: Text("Based on: ${guide.label}"),
                    subtitle: Text(
                      shortenUrlForDisplay(guide.source),
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                    onTap: () => launchAppUrl(context, url: guide.source),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          adaptiveAction(
            context: context,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Got it"),
          ),
        ],
      );
    },
  );
}
