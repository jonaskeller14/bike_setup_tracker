import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../l10n/enum_labels.dart';
import '../l10n/l10n.dart';
import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/component/preset_spec_keys.dart';
import '../models/component/setup_guide.dart';
import '../theme.dart';
import '../utils/adjustment_role.dart';
import '../utils/localized_number.dart';
import '../utils/number_input_formatters.dart';
import '../utils/setup_guide_actions.dart';
import 'hint_card_parts.dart';
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

/// Recommended values for components linked to a catalog product with a setup
/// guide, styled like the app hints. Collapsed unless [initiallyExpanded],
/// with the header icon in the status colours: orange while a value differs from
/// the guide, green while every value that has a recommendation follows it.
/// Tapping a row applies its value; [onApplyAll] applies every one.
class SetupGuideCard extends StatefulWidget {
  final List<SetupGuideSection> sections;
  final GuideInputs inputs;
  final void Function(GuideRecommendation recommendation) onApply;

  /// Null while there is nothing left to apply.
  final VoidCallback? onApplyAll;

  /// Shown in place of the weight line while no riding weight is recorded.
  final GuideWeightInput? weightInput;
  final bool initiallyExpanded;

  const SetupGuideCard({
    super.key,
    required this.sections,
    required this.inputs,
    required this.onApply,
    required this.onApplyAll,
    this.weightInput,
    this.initiallyExpanded = true,
  });

  @override
  State<SetupGuideCard> createState() => _SetupGuideCardState();
}

class _SetupGuideCardState extends State<SetupGuideCard> {
  /// Null until the rider toggles the card; until then it follows [SetupGuideCard.initiallyExpanded].
  bool? _expanded;

  @override
  Widget build(BuildContext context) {
    final sections = widget.sections;
    if (sections.isEmpty) return const SizedBox.shrink();

    final hint = HintColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final onContainer = TextStyle(color: hint.onContainer);
    final inputs = widget.inputs;
    final weightInput = widget.weightInput;
    final expanded = _expanded ?? widget.initiallyExpanded;
    final statuses = [
      for (final section in sections)
        for (final recommendation in section.recommendations) ?GuideStatus.of(recommendation, context.l10n),
    ];
    final summary = switch (statuses) {
      _ when statuses.any((s) => s.kind == GuideStatusKind.off) => const GuideStatus(GuideStatusKind.off),
      _ when statuses.isNotEmpty && statuses.every((s) => s.kind.isOnGuide) => const GuideStatus(
        GuideStatusKind.matches,
      ),
      _ => null,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: hint.container,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HintCardHeader(
                status: Icon(
                  Icons.tips_and_updates_outlined,
                  size: 18,
                  color: summary?.color(context) ?? hint.accent,
                  semanticLabel: summary?.label(context.l10n),
                ),
                title: context.l10n.guideCardTitle,
                expanded: expanded,
                onToggle: () => setState(() => _expanded = !expanded),
              ),
              if (expanded) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.guideCardHeadline,
                        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: hint.onContainer),
                      ),
                      if (weightInput == null)
                        Text(_inputsText(inputs, context.l10n), style: textTheme.bodyMedium?.merge(onContainer))
                      else
                        _WeightField(input: weightInput, ridingStyle: inputs.ridingStyle),
                    ],
                  ),
                ),
                for (final (i, section) in sections.indexed) ...[
                  _SectionHeader(section: section, first: i == 0),
                  const _ColumnsHeader(),
                  for (final recommendation in section.recommendations)
                    _RecommendationRow(
                      recommendation: recommendation,
                      component: section.guided.component,
                      hasRiderWeight: inputs.riderWeight != null,
                      riderWeightUnit: inputs.riderWeightUnit,
                      onApply: widget.onApply,
                    ),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 12,
                    children: [
                      Expanded(
                        flex: 3,
                        child: HintLearnMoreText(
                          text: context.l10n.guideCardStartingPoint,
                          style: textTheme.bodySmall?.merge(onContainer),
                          onLearnMore: () => showSetupGuideInfoSheet(context, sections: sections),
                        ),
                      ),
                      // Shrinks only where a long label or large text would squeeze the text out.
                      Flexible(
                        flex: 2,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: hint.accent, foregroundColor: hint.onAccent),
                            onPressed: widget.onApplyAll,
                            icon: const Icon(Icons.done_all),
                            label: Text(context.l10n.guideCardApplyAll),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
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

  String _format(double? weight) =>
      weight == null ? '' : localizeDecimalSeparator(formatSpecNumber(weight), locale: context.l10n.localeName);

  @override
  void didUpdateWidget(covariant _WeightField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The weight may also change on the Rider tab.
    if (parseLocalizedDouble(_controller.text) != widget.input.weight) _controller.text = _format(widget.input.weight);
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
                  context.l10n.guideCardRidingWeight,
                  if (widget.ridingStyle case final style?) style.label(context.l10n),
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
                  final weight = parseLocalizedDouble(text);
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
            label: Text(input.addToRiderLabel ?? context.l10n.guideCardAddWeightDefault),
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
                  context.l10n.guideCardBasedOn(section.guided.guide.label),
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

/// One adjuster: what it is, what is set now, what the guide recommends and
/// whether the two agree. Tapping applies the recommendation.
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
    final current = recommendation.current;
    final canApply = value != null && current != value;
    final note = recommendation.rule.note;
    final reverseLookup = hasRiderWeight ? null : _reverseLookupText(recommendation, riderWeightUnit, context.l10n);
    final band = _bandText(recommendation, context.l10n);

    return InkWell(
      onTap: canApply ? () => onApply(recommendation) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: _ColumnsLayout(
          name: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                adjustment.name,
                style: textTheme.bodyMedium?.copyWith(color: hint.onContainer),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(guideDetailText(recommendation, component, context.l10n), style: mutedStyle),
              if (reverseLookup != null) Text(reverseLookup, style: mutedStyle),
              if (note != null) Text(note, style: mutedStyle),
            ],
          ),
          now: Text(
            current == null ? "–" : guideValueText(adjustment, current, context.l10n),
            style: textTheme.bodyMedium?.copyWith(color: hint.onContainer.withValues(alpha: 0.75)),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          guide: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                shown == null ? "–" : guideValueText(adjustment, shown, context.l10n),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: value == null ? hint.onContainer.withValues(alpha: 0.6) : hint.onContainer,
                ),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (band != null)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(band, style: mutedStyle, maxLines: 1),
                ),
            ],
          ),
          status: _StatusIcon(recommendation: recommendation),
        ),
      ),
    );
  }
}

/// The "Now" and "Guide" captions above a section's rows.
class _ColumnsHeader extends StatelessWidget {
  const _ColumnsHeader();

  @override
  Widget build(BuildContext context) {
    final hint = HintColors.of(context);
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: hint.onContainer.withValues(alpha: 0.75),
      fontWeight: FontWeight.w600,
    );
    Widget caption(String text) =>
        Text(text, style: style, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: _ColumnsLayout(
        now: caption(context.l10n.guideCardColumnNow),
        guide: caption(context.l10n.guideCardColumnGuide),
      ),
    );
  }
}

/// Shared by [_ColumnsHeader] and [_RecommendationRow] so the columns line up.
class _ColumnsLayout extends StatelessWidget {
  final Widget? name;
  final Widget now;
  final Widget guide;
  final Widget? status;

  const _ColumnsLayout({this.name, required this.now, required this.guide, this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: name ?? const SizedBox.shrink()),
        Expanded(flex: 2, child: now),
        Expanded(flex: 2, child: guide),
        SizedBox(width: 24, child: status),
      ],
    );
  }
}

/// The status icon, or for a value that is off, which way to move it: one
/// chevron for a small step, two for a large one, measured against the row's
/// scale. The tooltip keeps the exact distance.
class _StatusIcon extends StatelessWidget {
  final GuideRecommendation recommendation;

  const _StatusIcon({required this.recommendation});

  /// Up to this share of the scale counts as a small step.
  static const _smallShare = 0.15;

  @override
  Widget build(BuildContext context) {
    final status = GuideStatus.of(recommendation, context.l10n);
    if (status == null) return const SizedBox.shrink();
    final delta = recommendation.deviation?.delta;
    final span = _scaleSpan(recommendation);
    final icon = switch ((status.kind, delta, span)) {
      (GuideStatusKind.off, final delta?, final span?) => switch ((delta < 0, delta.abs() / span <= _smallShare)) {
        (true, true) => Icons.keyboard_arrow_up,
        (true, false) => Icons.keyboard_double_arrow_up,
        (false, true) => Icons.keyboard_arrow_down,
        (false, false) => Icons.keyboard_double_arrow_down,
      },
      _ => status.icon,
    };
    return Tooltip(
      message: status.label(context.l10n),
      child: Icon(icon, size: 20, color: status.color(context), semanticLabel: status.label(context.l10n)),
    );
  }
}

/// How wide the scale is that a row's values are compared on: the adjuster's
/// range, widened to every value shown, or padded around the values where the
/// adjuster has no bounds. Null for options and switches, which have no scale.
double? _scaleSpan(GuideRecommendation recommendation) {
  final adjustment = recommendation.adjustment;
  if (adjustment is! StepAdjustment && adjustment is! NumericalAdjustment) return null;
  final current = recommendation.current?.asNum?.toDouble();
  final recommended = (recommendation.value ?? recommendation.unappliedValue)?.asNum?.toDouble();
  final band = recommendation.band;
  final points = [?current, ?recommended, ?band?.min, ?band?.max];
  if (points.isEmpty) return null;

  var low = points.reduce(math.min);
  var high = points.reduce(math.max);
  final pad = math.max((high - low) * 0.5, math.max(low.abs(), high.abs()) * 0.1);
  final (min, max) = switch (adjustment) {
    StepAdjustment(:final min, :final max) => (min.toDouble(), max.toDouble()),
    NumericalAdjustment(:final min, :final max) => (min, max),
    _ => (double.negativeInfinity, double.infinity),
  };
  final bounded = min.isFinite && max.isFinite && max > min;
  low = bounded ? math.min(low, min) : low - pad;
  high = bounded ? math.max(high, max) : high + pad;
  return high - low < 1e-9 ? 2 : high - low;
}

/// "−4…−3 clicks": an ellipsis, so negative ends don't run into a dash.
String? _bandText(GuideRecommendation recommendation, AppLocalizations l10n) {
  final band = recommendation.band;
  if (band == null) return null;
  String number(double value) =>
      formatLocalizedDouble(double.parse(value.toStringAsFixed(1)), locale: l10n.localeName);

  return "${number(band.min)}…${number(band.max)}${recommendation.adjustment.unitSuffix()}";
}

String _inputsText(GuideInputs inputs, AppLocalizations l10n) {
  final weight = inputs.riderWeight;
  if (weight == null) return l10n.guideCardEnterWeight;
  return [
    l10n.guideCardValuesFor(_number(weight), inputs.riderWeightUnit.label),
    ?inputs.ridingStyle?.label(l10n),
  ].join(" · ");
}

/// The input the value was looked up for, or why there is none.
String guideDetailText(GuideRecommendation recommendation, Component component, AppLocalizations l10n) {
  final issue = recommendation.issue;
  if (issue == null) {
    final basis = [
      ?recommendation.inputText,
      if (recommendation.interpolated) l10n.guideDetailInterpolated,
      if (recommendation.converted) l10n.guideDetailConverted,
    ];
    return basis.isEmpty ? l10n.guideDetailFixed : basis.join(" · ");
  }
  return switch (issue) {
    GuideIssue.missingInput => switch (recommendation.rule.input) {
      RiderGuideInput(key: GuideInputKey.riderWeight) => l10n.guideIssueNeedsWeight,
      RiderGuideInput(key: GuideInputKey.ridingStyle) => l10n.guideIssueNeedsStyle,
      AdjusterGuideInput(:final adjusterId) => l10n.guideIssueNeedsAdjuster(
        component.adjustments.firstWhereOrNull((a) => adjustmentRole(a) == adjusterId)?.name ?? adjusterId,
      ),
      PresetGuideInput(:final id) => l10n.guideIssueNeedsSpec(id.replaceAll('_', ' ')),
      null => l10n.guideIssueNeedsMore,
    },
    GuideIssue.outsideRange => switch (_outsideRangeInput(recommendation, l10n)) {
      final input? => l10n.guideIssueOutsideRangeFor(input),
      null => l10n.guideIssueOutsideRange,
    },
    GuideIssue.placeholderMax => l10n.guideIssuePlaceholderMax,
    GuideIssue.aboveMax => l10n.guideIssueAboveMax,
    GuideIssue.belowMin => l10n.guideIssueBelowMin,
    GuideIssue.incompatible => l10n.guideIssueIncompatible,
    GuideIssue.directionUnknown => l10n.guideIssueDirectionUnknown,
  };
}

/// The looked-up input with its name, e.g. "Riding weight 140 kg" or
/// "Pressure 120 psi"; an adjuster's [GuideRecommendation.inputText] has its name already.
String? _outsideRangeInput(GuideRecommendation recommendation, AppLocalizations l10n) {
  final text = recommendation.inputText;
  if (text == null) return null;
  return switch (recommendation.rule.input) {
    RiderGuideInput(key: GuideInputKey.riderWeight) => "${l10n.guideCardRidingWeight} $text",
    PresetGuideInput(:final id) => "${id.replaceAll('_', ' ')} $text",
    _ => text,
  };
}

/// "84 psi ≈ 86–91 kg": the rider weights the current value suits.
String? _reverseLookupText(GuideRecommendation recommendation, KnownUnit unit, AppLocalizations l10n) {
  final (range, current) = (recommendation.riderWeightRange, recommendation.current);
  if (range == null || current == null) return null;
  final weights = switch ((range.min.isFinite, range.max.isFinite)) {
    (true, true) when range.min.round() == range.max.round() => _number(range.min),
    (true, true) => "${_number(range.min)}–${_number(range.max)}",
    (true, false) => "${_number(range.min)}+",
    (false, true) => l10n.guideWeightUpTo(_number(range.max)),
    (false, false) => null,
  };
  if (weights == null) return null;
  return "${guideValueText(recommendation.adjustment, current, l10n)} ≈ $weights ${unit.label}";
}

String _number(double value) => value.round().toString();
