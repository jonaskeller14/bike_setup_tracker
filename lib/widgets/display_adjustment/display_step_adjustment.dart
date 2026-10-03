import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import '../../utils/value_delta.dart';
import '../lists/adjustment_compact_display/adjustment_cell_layout.dart';
import '../set_adjustment/set_step_adjustment_dial.dart';
import 'adjustment_icon_name_notes.dart';
import 'step_pips.dart';
import 'value_delta_chip.dart';

class DisplayStepAdjustmentWidget extends StatelessWidget {
  final StepAdjustment adjustment;
  final StepValue? initialValue;
  final StepValue? value;
  final bool highlighting;
  final bool isError;
  final VoidCallback? onRemove;

  const DisplayStepAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    this.highlighting = true,
    this.isError = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final highlights = theme.extension<ValueHighlightColors>();

    bool isChanged = false;
    bool isInitial = false;
    Color? highlightColor;
    if (highlighting) {
      isChanged = value != null && initialValue != value;
      isInitial = initialValue == null;
      highlightColor = isChanged
          ? (isInitial ? highlights?.initial ?? Colors.green : highlights?.changed ?? Colors.orange)
          : null;
    }
    if (isError) {
      isChanged = false;
      isInitial = true;
      highlightColor = scheme.error;
    }
    final previous = !isInitial && isChanged ? initialValue : null;
    final changeColor = highlights?.changed ?? Colors.orange;
    final accentColor = isError ? scheme.error : resolveStepAccentColor(context, adjustment);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        spacing: 20,
        children: [
          Expanded(
            flex: 5,
            child: AdjustmentIconNameNotes(adjustment: adjustment, value: value, color: highlightColor),
          ),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: _valueLine(context, previous: previous, highlightColor: highlightColor),
                      ),
                    ),
                    if (previous != null && value != null)
                      ValueDeltaChip(label: formatValueDelta(previous, value)!, color: changeColor),
                  ],
                ),
                StepPips(
                  adjustment: adjustment,
                  value: value,
                  previousValue: previous,
                  color: accentColor,
                  changeColor: changeColor,
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }

  /// `previous → value`, or `value` when nothing changed. The
  /// previous value is styled like `ToggleableUnitValue`'s.
  Widget _valueLine(BuildContext context, {required StepValue? previous, required Color? highlightColor}) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyLarge ?? const TextStyle();
    final valueStyle = base.copyWith(
      fontFamily: 'monospace',
      fontWeight: FontWeight.bold,
      color: highlightColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final small = theme.textTheme.bodySmall ?? const TextStyle();
    final previousColor = (small.color ?? theme.colorScheme.onSurface).withValues(alpha: 0.7);
    final previousStyle = small.copyWith(
      fontFamily: 'monospace',
      fontWeight: FontWeight.bold,
      color: previousColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Text.rich(
      TextSpan(
        children: [
          if (previous != null) ...[
            TextSpan(text: previous.display, style: previousStyle),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  cellChangeArrowIcon,
                  size: cellChangeArrowSizeFor(small.fontSize ?? 12),
                  color: previousColor,
                ),
              ),
            ),
          ],
          TextSpan(text: value?.display ?? '-', style: valueStyle),
        ],
      ),
      maxLines: 1,
    );
  }
}
