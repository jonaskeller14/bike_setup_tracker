import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/feedback/custom_issue.dart';
import '../../models/feedback/feedback_vocabulary.dart';
import '../../theme.dart';

/// Follow-up on an open issue of the reference setup:
/// "Front: Harsh" next to Worse · Same · Better.
class FeedbackAspectRow extends StatelessWidget {
  final FeedbackIssue issue;
  final int? outcome;
  final ValueChanged<int?> onChanged;

  const FeedbackAspectRow({
    super.key,
    required this.issue,
    required this.outcome,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            issue.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          flex: 3,
          child: FeedbackOutcomeSelector(
            labels: FeedbackVocabulary.aspectOutcomeLabels,
            outcome: outcome,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

/// One face per outcome in a single row, worse (red) to better (green),
/// "Same" in grey, with the selected answer spelled out below. Tapping the
/// selected face clears the answer: every question of the form is optional.
class FeedbackOutcomeSelector extends StatelessWidget {
  /// Outcome → label, ordered worse to better.
  final Map<int, String> labels;
  final int? outcome;
  final ValueChanged<int?> onChanged;

  const FeedbackOutcomeSelector({
    super.key,
    required this.labels,
    required this.outcome,
    required this.onChanged,
  });

  int get _strongest => labels.keys.first.abs();

  bool _isStrong(int value) => value != 0 && value.abs() == _strongest;

  Color _scaleColor(FeedbackOutcomeColors colors, int value) => switch (value.sign) {
    0 => colors.neutral,
    final sign => sign > 0 ? colors.better : colors.worse,
  };

  IconData _face(int value) => switch (value) {
    0 => Icons.sentiment_neutral,
    _ when _isStrong(value) && _strongest > 1 =>
      value > 0 ? Icons.sentiment_very_satisfied : Icons.sentiment_very_dissatisfied,
    _ => value > 0 ? Icons.sentiment_satisfied : Icons.sentiment_dissatisfied,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = theme.extension<FeedbackOutcomeColors>()!;
    // The selected face pops and the answer below fades over; off with reduced motion.
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 150);

    // The unselected faces carry the scale's colour, fainter for the mild steps.
    Color faceColor(int value) =>
        _scaleColor(colors, value).withValues(alpha: _isStrong(value) || value == 0 ? 1 : 0.75);
    // SegmentedButton styles every selected segment alike; only one is selected.
    final (Color? selectedFill, Color? selectedFace) = switch (outcome) {
      null => (null, null),
      final value when _isStrong(value) => (_scaleColor(colors, value), colors.onOutcome),
      final value => (_scaleColor(colors, value).withValues(alpha: 0.3), scheme.onSurface),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        SegmentedButton<int>(
          segments: [
            for (final MapEntry(key: value, value: label) in labels.entries)
              ButtonSegment<int>(
                value: value,
                tooltip: label,
                label: AnimatedScale(
                  scale: outcome == value ? 1.15 : 1,
                  duration: duration,
                  curve: Curves.easeOutBack,
                  child: Icon(
                    _face(value),
                    size: 24,
                    color: outcome == value ? null : faceColor(value),
                    semanticLabel: label,
                  ),
                ),
              ),
          ],
          selected: {?outcome},
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          expandedInsets: EdgeInsets.zero,
          onSelectionChanged: (selection) {
            unawaited(HapticFeedback.selectionClick());
            onChanged(selection.firstOrNull);
          },
          style: ButtonStyle(
            padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
            minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected) ? selectedFill : null,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected) ? selectedFace : null,
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: duration,
          child: Text(
            outcome == null ? 'Tap a face' : labels[outcome]!,
            key: ValueKey(outcome),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: switch (outcome) {
                null => scheme.onSurfaceVariant,
                0 => scheme.onSurface,
                final value => _scaleColor(colors, value),
              },
            ),
          ),
        ),
      ],
    );
  }
}
