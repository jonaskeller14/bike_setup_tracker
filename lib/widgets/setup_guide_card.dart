import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/component/preset_spec_keys.dart';
import '../models/component/setup_guide.dart';
import '../theme.dart';
import '../utils/adjustment_role.dart';
import '../utils/setup_guide_actions.dart';
import 'setup_guide_status.dart';
import 'sheets/setup_guide_info_sheet.dart';

/// One guided component's recommendations on the card.
class SetupGuideSection {
  final GuidedComponent guided;
  final List<GuideRecommendation> recommendations;

  const SetupGuideSection(this.guided, this.recommendations);
}

/// A riding weight entered on the card while none is recorded yet.
class GuideWeightInput {
  final double? weight;
  final KnownUnit unit;
  final ValueChanged<double?> onChanged;

  /// Where the weight goes: saved with the setup, or only used here.
  final String hint;

  /// Adds a riding-weight attribute to the rider; null where there is no rider
  /// or it already has one.
  final VoidCallback? onAddToRider;
  final String? addToRiderLabel;

  const GuideWeightInput({
    required this.weight,
    required this.unit,
    required this.onChanged,
    required this.hint,
    this.onAddToRider,
    this.addToRiderLabel,
  });
}

/// Recommended first values for components linked to a catalog product with a
/// setup guide, styled like the app hints since it only shows until values are
/// recorded. Tapping a row applies its value; [onApplyAll] applies every one.
class SetupGuideCard extends StatelessWidget {
  final List<SetupGuideSection> sections;
  final GuideInputs inputs;
  final void Function(GuideRecommendation recommendation) onApply;

  /// Null while there is nothing left to apply.
  final VoidCallback? onApplyAll;

  /// Shown in place of the weight line while no riding weight is recorded.
  final GuideWeightInput? weightInput;

  const SetupGuideCard({
    super.key,
    required this.sections,
    required this.inputs,
    required this.onApply,
    required this.onApplyAll,
    this.weightInput,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();

    final hint = HintColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final onContainer = TextStyle(color: hint.onContainer);
    final weightInput = this.weightInput;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: hint.container, borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 4),
            child: Row(
              spacing: 6,
              children: [
                Icon(Icons.tips_and_updates_outlined, size: 16, color: hint.accent),
                Expanded(
                  child: Text(
                    "SETUP GUIDE",
                    style: textTheme.labelSmall?.copyWith(
                      color: hint.accent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => showSetupGuideInfoSheet(context, sections: sections),
                  icon: const Icon(Icons.info_outline_rounded),
                  iconSize: 18,
                  color: hint.accent,
                  tooltip: "About recommended values",
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Recommended first values",
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: hint.onContainer),
                ),
                if (weightInput == null)
                  Text(_inputsText(inputs), style: textTheme.bodyMedium?.merge(onContainer))
                else
                  _WeightField(input: weightInput, ridingStyle: inputs.ridingStyle),
              ],
            ),
          ),
          for (final (i, section) in sections.indexed) ...[
            _SectionHeader(section: section, first: i == 0),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: Text("A starting point, check your manual.", style: textTheme.bodySmall?.merge(onContainer)),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: hint.accent, foregroundColor: hint.onAccent),
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

class _WeightField extends StatefulWidget {
  final GuideWeightInput input;
  final GuideRidingStyle? ridingStyle;

  const _WeightField({required this.input, required this.ridingStyle});

  @override
  State<_WeightField> createState() => _WeightFieldState();
}

class _WeightFieldState extends State<_WeightField> {
  late final _controller = TextEditingController(text: _format(widget.input.weight));

  static String _format(double? weight) => weight == null ? '' : formatSpecNumber(weight);

  static double? _parse(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  @override
  void didUpdateWidget(covariant _WeightField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The weight may also change on the Rider tab.
    if (_parse(_controller.text) != widget.input.weight) _controller.text = _format(widget.input.weight);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hint = HintColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final input = widget.input;
    final onAddToRider = input.onAddToRider;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 8,
          children: [
            Flexible(
              child: Text(
                [
                  "Riding weight",
                  if (widget.ridingStyle case final style?) style.label,
                ].join(" · "),
                style: textTheme.bodyMedium?.copyWith(color: hint.onContainer),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64, maxWidth: 96),
              child: TextField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.end,
                style: textTheme.bodyLarge?.copyWith(color: hint.onContainer),
                cursorColor: hint.accent,
                decoration: InputDecoration(
                  isDense: true,
                  suffixText: " ${input.unit.label}",
                  suffixStyle: textTheme.bodyMedium?.copyWith(color: hint.onContainer),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: hint.accent.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: hint.accent, width: 2)),
                ),
                onChanged: (text) {
                  final weight = _parse(text);
                  input.onChanged(weight != null && weight > 0 ? weight : null);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(input.hint, style: textTheme.bodySmall?.copyWith(color: hint.onContainer.withValues(alpha: 0.75))),
        if (onAddToRider != null)
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: hint.accent, padding: EdgeInsets.zero),
            onPressed: onAddToRider,
            icon: const Icon(Icons.person_add_alt_outlined, size: 18),
            label: Text(input.addToRiderLabel ?? "Add riding weight to rider"),
          ),
      ],
    );
  }
}

/// A full-width band, so each component's rows read as one group.
class _SectionHeader extends StatelessWidget {
  final SetupGuideSection section;
  final bool first;

  const _SectionHeader({required this.section, required this.first});

  @override
  Widget build(BuildContext context) {
    final hint = HintColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final component = section.guided.component;
    return Container(
      margin: EdgeInsets.only(top: first ? 12 : 16, bottom: 4),
      color: Color.alphaBlend(hint.accent.withValues(alpha: 0.12), hint.container),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        spacing: 8,
        children: [
          Icon(component.componentType.getIconData(), size: 18, color: hint.onContainer),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component.name,
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: hint.onContainer),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Based on: ${section.guided.guide.label}",
                  style: textTheme.bodySmall?.copyWith(color: hint.onContainer.withValues(alpha: 0.75)),
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
    final hint = HintColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final mutedStyle = textTheme.bodySmall?.copyWith(color: hint.onContainer.withValues(alpha: 0.75));
    final adjustment = recommendation.adjustment;
    final value = recommendation.value;
    final shown = value ?? recommendation.unappliedValue;
    final canApply = value != null && recommendation.current != value;
    final note = recommendation.rule.note;
    final reverseLookup = hasRiderWeight ? null : _reverseLookupText(recommendation, riderWeightUnit);
    final status = GuideStatus.of(recommendation);
    final current = recommendation.current;
    final band = guideBandText(recommendation);
    final statusDetail = switch (status?.kind) {
      GuideStatusKind.inRange || GuideStatusKind.off when current != null => [
        "Now ${guideValueText(adjustment, current)}",
        if (band != null) "in range $band",
      ].join(" · "),
      _ => null,
    };

    return InkWell(
      onTap: canApply ? () => onApply(recommendation) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adjustment.name,
                    style: textTheme.bodyMedium?.copyWith(color: hint.onContainer),
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
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 2,
                children: [
                  Text(
                    shown == null ? "–" : guideValueText(adjustment, shown),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: value == null ? hint.onContainer.withValues(alpha: 0.6) : hint.onContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (status != null) GuideStatusPill(status),
                  if (statusDetail != null)
                    Text(
                      statusDetail,
                      style: mutedStyle,
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

/// The input the value was looked up for, or why there is none.
String guideDetailText(GuideRecommendation recommendation, Component component) {
  final issue = recommendation.issue;
  if (issue == null) {
    final basis = [
      ?recommendation.inputText,
      if (recommendation.interpolated) "interpolated",
      if (recommendation.converted) "converted to your dial",
    ];
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
    GuideIssue.directionUnknown => "Counted on the catalog's dial; set this adjuster's dial direction to apply",
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
