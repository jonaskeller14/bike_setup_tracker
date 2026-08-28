import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import 'adjustment_icon_name_notes.dart';
import 'toggleable_unit_value.dart';

class DisplayNumericalAdjustmentWidget extends StatelessWidget {
  final NumericalAdjustment adjustment;
  final num? initialValue;
  final num? value;
  final bool highlighting;
  final bool isError;
  final VoidCallback? onRemove;

  const DisplayNumericalAdjustmentWidget({
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
          Flexible(
            flex: 2,
            child: AdjustmentIconNameNotes(adjustment: adjustment, color: highlightColor),
          ),
          Flexible(
            flex: 3,
            child: ToggleableUnitValue(
              value: value,
              initialValue: initialValue,
              unit: adjustment.unit,
              highlightColor: highlightColor,
              showPreviousValue: !isInitial && isChanged,
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
