import '../models/adjustment.dart';
import 'package:flutter/material.dart';

class AdjustmentDisplayList extends StatelessWidget {
  final Map<Adjustment, dynamic> adjustmentValues;
  final Map<Adjustment, dynamic> previousAdjustmentValues;

  AdjustmentDisplayList({
    super.key,
    required this.adjustmentValues,
    Map<Adjustment, dynamic>? previousAdjustmentValues,
  }) : previousAdjustmentValues = previousAdjustmentValues ?? {};

  @override
  Widget build(BuildContext context) {
    final items = adjustmentValues.entries.toList();
    List<Widget> children = [];

    for (int index = 0; index < items.length; index++) {
      final entry = items[index];
      final adjustment = entry.key;
      final value = entry.value;
      final previousValue = previousAdjustmentValues[adjustment];

      children.add(
        _AdjustmentTableCell(
          adjustment: adjustment,
          value: value,
          previousValue: previousValue,
        ),
      );

      if (index != items.length - 1) {
        children.add(_VerticalDivider());
      }
    }

    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 12,
      runSpacing: 12,
      children: children,
    );
  }
}

class _AdjustmentTableCell extends StatelessWidget {
  final Adjustment adjustment;
  final dynamic value;
  final dynamic previousValue;

  const _AdjustmentTableCell({
    required this.adjustment,
    required this.value,
    required this.previousValue,
  });



  @override
  Widget build(BuildContext context) {
    final bool valueHasChanged = previousValue == null ? false : value != previousValue;
    bool isCrossed = false;
    String change = "";
    if (valueHasChanged) {
      if (value is String || value is bool) {
        isCrossed = true;
        change = Adjustment.formatValue(previousValue);
      } else {
        dynamic changeValue = value - previousValue;
        change = changeValue > 0? "+${Adjustment.formatValue(changeValue)}" : Adjustment.formatValue(changeValue);
      }
    }

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            adjustment.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: Adjustment.formatValue(value)),
                if (valueHasChanged) ... [
                  TextSpan(text: " "),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.top,
                    child: Transform.translate(
                      offset: const Offset(0, -6),
                      child: Text(
                        change,
                        style: TextStyle(
                          fontSize: 12, 
                          color: valueHasChanged ? Colors.red : Colors.grey,
                          decoration: isCrossed ? TextDecoration.lineThrough : TextDecoration.none,
                          decorationColor: Colors.red,
                        ),
                      ),
                    ),
                  )
                ],
                if (adjustment.unit != null) ... [
                  TextSpan(text: " ${adjustment.unit}"),
                ]
              ]
            )
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      width: 1,
      height: 40,
      color: Colors.grey.shade400,
    );
  }
}




