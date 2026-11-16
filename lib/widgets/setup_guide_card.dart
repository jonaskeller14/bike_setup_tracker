import 'dart:async';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/catalog_labels.dart';
import '../l10n/enum_labels.dart';
import '../l10n/l10n.dart';
import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/component/preset_spec_keys.dart';
import '../models/component/setup_guide.dart';
import '../theme.dart';
import '../utils/adjustment_role.dart';
import '../utils/automation_ids.dart';
import '../utils/localized_number.dart';
import '../utils/number_input_formatters.dart';
import '../utils/setup_guide_actions.dart';
import '../utils/unit_conversion.dart';
import 'hint_card_parts.dart';
import 'rolling_value_text.dart';
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
/// Tapping a row applies its value; [onApplyAll] applies every one. Tapping
/// an applied row again, before its value is changed, undoes it. A row that
/// waits for a catalog detail of its component asks for it.
class SetupGuideCard extends StatefulWidget {
  final List<SetupGuideSection> sections;
  final GuideInputs inputs;
  final void Function(GuideRecommendation recommendation) onApply;

  /// The adjusters whose applied value can still be undone.
  final Set<String> undoableIds;
  final void Function(GuideRecommendation recommendation)? onUndo;

  /// Null while there is nothing left to apply.
  final VoidCallback? onApplyAll;

  /// Shown in place of the weight line while no riding weight is recorded.
  final GuideWeightInput? weightInput;

  /// Asks for the [GuideRecommendation.missingAxes] of a section's
  /// recommendations, those of the tapped row first.
  final void Function(SetupGuideSection section, List<String> axisIds)? onCompleteDetails;
  final bool initiallyExpanded;

  const SetupGuideCard({
    super.key,
    required this.sections,
    required this.inputs,
    required this.onApply,
    required this.onApplyAll,
    this.undoableIds = const {},
    this.onUndo,
    this.weightInput,
    this.onCompleteDetails,
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
                      key: ValueKey(recommendation.adjustment.id),
                      recommendation: recommendation,
                      component: section.guided.component,
                      hasRiderWeight: inputs.riderWeight != null,
                      riderWeightUnit: inputs.riderWeightUnit,
                      onApply: widget.onApply,
                      onUndo: widget.undoableIds.contains(recommendation.adjustment.id) ? widget.onUndo : null,
                      onCompleteDetails: switch (widget.onCompleteDetails) {
                        final onCompleteDetails? when recommendation.missingAxes.isNotEmpty => () => onCompleteDetails(
                          section,
                          {
                            ...recommendation.missingAxes,
                            for (final other in section.recommendations) ...other.missingAxes,
                          }.toList(),
                        ),
                        _ => null,
                      },
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
                          child: Semantics(
                            identifier: AutomationIds.setupGuideApplyAll,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: hint.accent, foregroundColor: hint.onAccent),
                              onPressed: widget.onApplyAll,
                              icon: const Icon(Icons.done_all),
                              label: Text(context.l10n.guideCardApplyAll),
                            ),
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
  static const _pounds = KnownUnit(quantity: UnitQuantity.mass, unitId: 'pounds');
  static const _kilograms = KnownUnit(quantity: UnitQuantity.mass, unitId: 'kilograms');

  late final _controller = TextEditingController(text: _format(widget.input.weight));

  /// What the field shows; the weight is still reported in [GuideWeightInput.unit].
  late KnownUnit _displayUnit = widget.input.unit;

  KnownUnit get _otherUnit => widget.input.unit == _pounds ? _kilograms : _pounds;

  double _toStorage(double weight) => convertUnit(weight, _displayUnit, widget.input.unit);

  String _format(double? weight) {
    if (weight == null) return '';
    final locale = context.l10n.localeName;
    if (_displayUnit == widget.input.unit) return localizeDecimalSeparator(formatSpecNumber(weight), locale: locale);
    final shown = convertUnit(weight, widget.input.unit, _displayUnit);
    return formatLocalizedDouble(double.parse(shown.toStringAsFixed(1)), locale: locale);
  }

  void _toggleUnit() {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _displayUnit = _displayUnit == widget.input.unit ? _otherUnit : widget.input.unit;
      _controller.text = _format(widget.input.weight);
    });
  }

  @override
  void didUpdateWidget(covariant _WeightField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The weight may also change on the Rider tab.
    if (widget.input.weight == oldWidget.input.weight) return;
    final typed = parseLocalizedDouble(_controller.text);
    final weight = widget.input.weight;
    final matches = typed == null || weight == null ? typed == weight : (_toStorage(typed) - weight).abs() < 1e-9;
    if (!matches) _controller.text = _format(weight);
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
    final hintStyle = textTheme.bodySmall?.copyWith(color: hint.onContainer.withValues(alpha: 0.75));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: Text(
                [
                  context.l10n.guideCardRidingWeight,
                  if (widget.ridingStyle case final style?) style.label(context.l10n),
                ].join(" · "),
                style: textTheme.bodyMedium?.copyWith(color: hint.onContainer),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 150,
              child: Semantics(
                identifier: AutomationIds.setupGuideWeight,
                child: TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: textTheme.bodyLarge?.copyWith(color: hint.onContainer),
                  cursorColor: hint.accent,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: context.l10n.setNumericalHint,
                    hintStyle: TextStyle(color: hint.onContainer.withValues(alpha: 0.6)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    // Always shown, unlike `suffix`, so the empty field already says what it takes.
                    suffixIcon: Align(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: _toggleUnit,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4, right: 12, top: 4, bottom: 4),
                          child: Text(
                            _displayUnit.label,
                            style: TextStyle(color: hint.onContainer.withValues(alpha: 0.8)),
                          ),
                        ),
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(minHeight: 40, minWidth: 0),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: hint.onContainer.withValues(alpha: 0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: hint.accent, width: 2)),
                  ),
                  // The iOS number pad has no Done key and would keep covering Apply all.
                  onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  onChanged: (text) {
                    final weight = parseLocalizedDouble(text);
                    input.onChanged(weight != null && weight > 0 ? _toStorage(weight) : null);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        if (onAddToRider == null)
          Text(input.hint, style: hintStyle)
        else
          HintLearnMoreText(
            text: input.hint,
            linkText: input.addToRiderLabel ?? context.l10n.guideCardAddWeightDefault,
            style: hintStyle,
            onLearnMore: onAddToRider,
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
/// whether the two agree. Tapping applies the recommendation, or undoes it
/// while it is still the applied value.
class _RecommendationRow extends StatelessWidget {
  final GuideRecommendation recommendation;
  final Component component;
  final bool hasRiderWeight;
  final KnownUnit riderWeightUnit;
  final void Function(GuideRecommendation recommendation) onApply;

  /// Null where the value was not applied here or has changed since.
  final void Function(GuideRecommendation recommendation)? onUndo;

  /// Set while the row waits for a catalog detail it can ask for.
  final VoidCallback? onCompleteDetails;

  const _RecommendationRow({
    super.key,
    required this.recommendation,
    required this.component,
    required this.hasRiderWeight,
    required this.riderWeightUnit,
    required this.onApply,
    required this.onUndo,
    required this.onCompleteDetails,
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
    // A guide that now recommends something else is applied rather than undone.
    final onUndo = value != null && current == value ? this.onUndo : null;
    final note = recommendation.rule.note;
    final reverseLookup = hasRiderWeight ? null : _reverseLookupText(recommendation, riderWeightUnit, context.l10n);
    final band = _bandText(recommendation, context.l10n);
    final detail = guideDetailText(recommendation, component, context.l10n);
    final onCompleteDetails = value == null ? this.onCompleteDetails : null;

    return InkWell(
      onTap: switch (onUndo) {
        final onUndo? => () => onUndo(recommendation),
        null when canApply => () => onApply(recommendation),
        null => onCompleteDetails,
      },
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
              if (onCompleteDetails == null)
                Text(detail, style: mutedStyle)
              else
                HintLearnMoreText(
                  text: detail,
                  linkText: context.l10n.guideCardChooseDetail,
                  style: mutedStyle,
                  onLearnMore: onCompleteDetails,
                ),
              if (reverseLookup != null) Text(reverseLookup, style: mutedStyle),
              if (note != null) Text(note, style: mutedStyle),
            ],
          ),
          now: RollingValueText(
            current == null ? "–" : guideValueText(adjustment, current, context.l10n),
            value: switch (current) {
              NumericalValue(:final value) => value,
              StepValue(:final value) => value.toDouble(),
              _ => null,
            },
            format: switch (current) {
              NumericalValue() => (value) => guideValueText(adjustment, NumericalValue(value), context.l10n),
              StepValue() => (value) => guideValueText(adjustment, StepValue(value.round()), context.l10n),
              _ => null,
            },
            style: textTheme.bodyMedium?.copyWith(color: hint.onContainer.withValues(alpha: 0.75)),
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
      if (recommendation.followsSpring case final spring?) l10n.guideDetailFollowsSpring(spring),
      if (recommendation.interpolated) l10n.guideDetailInterpolated,
      if (recommendation.converted) l10n.guideDetailConverted,
    ];
    return basis.isEmpty ? l10n.guideDetailFixed : basis.join(" · ");
  }
  return switch (issue) {
    GuideIssue.missingInput when recommendation.missingAxes.isNotEmpty => l10n.guideIssueNeedsSpec(
      recommendation.missingAxes.map((id) => _catalogTerm(id, l10n)).join(', '),
    ),
    GuideIssue.missingInput => switch (recommendation.rule.input) {
      RiderGuideInput(key: GuideInputKey.riderWeight) => l10n.guideIssueNeedsWeight,
      RiderGuideInput(key: GuideInputKey.ridingStyle) => l10n.guideIssueNeedsStyle,
      AdjusterGuideInput(:final adjusterId) => l10n.guideIssueNeedsAdjuster(
        component.adjustments.firstWhereOrNull((a) => adjustmentRole(a) == adjusterId)?.name ?? adjusterId,
      ),
      PresetGuideInput(:final id) => l10n.guideIssueNeedsSpec(_catalogTerm(id, l10n)),
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

/// A catalog spec or option axis by its name; an unregistered id as written.
String _catalogTerm(String id, AppLocalizations l10n, {bool capitalised = false}) =>
    switch ((PresetSpecKeys.byId(id), PresetOptionAxes.byId(id))) {
      (final spec?, _) => capitalised ? spec.name(l10n) : spec.inSentence(l10n),
      (_, final axis?) => capitalised ? axis.name(l10n) : axis.inSentence(l10n),
      _ => id.replaceAll('_', ' '),
    };

/// The looked-up input with its name, e.g. "Riding weight 140 kg" or
/// "Pressure 120 psi"; an adjuster's [GuideRecommendation.inputText] has its
/// name already, as has the spring a rule follows.
String? _outsideRangeInput(GuideRecommendation recommendation, AppLocalizations l10n) {
  final text = recommendation.inputText;
  if (text == null) return null;
  if (recommendation.followsSpring != null) return text;
  return switch (recommendation.rule.input) {
    RiderGuideInput(key: GuideInputKey.riderWeight) => "${l10n.guideCardRidingWeight} $text",
    PresetGuideInput(:final id) => "${_catalogTerm(id, l10n, capitalised: true)} $text",
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
