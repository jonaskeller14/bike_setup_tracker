import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import '../../utils/value_delta.dart';
import 'value_delta_chip.dart';

class PreviousValueLine extends StatelessWidget {
  final Adjustment adjustment;
  final AdjustmentValue previousValue;
  final AdjustmentValue value;

  const PreviousValueLine({
    super.key,
    required this.adjustment,
    required this.previousValue,
    required this.value,
  });

  /// Whether a row for [adjustment] that went from [previousValue] to [value]
  /// gets the line. A boolean never does: its previous value can only have been
  /// the other position.
  static bool appliesTo(Adjustment adjustment, AdjustmentValue? previousValue, AdjustmentValue? value) {
    if (adjustment is BooleanAdjustment || previousValue == null || value == null) return false;
    if (!previousValue.matches(adjustment.type) || !value.matches(adjustment.type)) return false;
    // The text field compares trimmed text, so whitespace alone is no change.
    if (previousValue is TextValue && value is TextValue) return previousValue.value.trim() != value.value.trim();
    return previousValue != value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta = formatValueDelta(previousValue, value);
    // The read-only rows set ordered values in monospace and words in the body
    // font; only the ordered types have a delta.
    final isOrdered = delta != null;

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 6,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Opacity(
          opacity: 0.7,
          child: Text(
            previousValue.display + adjustment.unitSuffix(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: isOrdered ? 'monospace' : null,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.lineThrough,
              decorationThickness: 2,
              fontFeatures: isOrdered ? const [FontFeature.tabularFigures()] : null,
            ),
          ),
        ),
        if (delta != null) ValueDeltaChip(label: delta, color: theme.extension<ValueHighlightColors>()!.changed),
      ],
    );
  }
}
