import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import "../set_adjustment/set_adjustment.dart";
import 'toggleable_unit_value.dart';

class DisplayStepAdjustmentWidget extends StatelessWidget {
  final StepAdjustment adjustment;
  final num? initialValue;
  final num? value;
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
    bool isChanged = false;
    bool isInitial = false;
    Color? highlightColor;
    final highlights = Theme.of(context).extension<ValueHighlightColors>();
    if (highlighting) {
      isChanged = value != null && initialValue != value;
      isInitial = initialValue == null;
      highlightColor = isChanged ? (isInitial ? highlights?.initial ?? Colors.green : highlights?.changed ?? Colors.orange) : null;
    }
    if (isError) {
      isChanged = false;
      isInitial = true;
      highlightColor = Theme.of(context).colorScheme.error;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 20,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              spacing: 10,
              children: [
                Icon(StepAdjustment.iconData, color: highlightColor),
                nameNotesSetAdjustmentWidget(context: context, adjustment: adjustment, highlightColor: highlightColor),
              ],
            )
          ),
          Flexible(
            child: ToggleableUnitValue(
              value: value,
              initialValue: initialValue,
              unit: adjustment.unit,
              highlightColor: highlightColor,
              showPreviousValue: !isInitial && isChanged,
              crossAxisAlignment: CrossAxisAlignment.end,
              trailing: [
                Text(
                  "[${Adjustment.formatValue(adjustment.min)}..${Adjustment.formatValue(adjustment.max)}]",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isError
                        ? highlightColor
                        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
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
}
