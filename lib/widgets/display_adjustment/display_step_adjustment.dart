import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import "../set_adjustment/set_adjustment.dart";

class DisplayStepAdjustmentWidget extends StatelessWidget {
  final StepAdjustment adjustment;
  final int? initialValue;
  final int? value;
  final bool highlighting;

  const DisplayStepAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    this.highlighting = true,
  });

  @override
  Widget build(BuildContext context) {
    bool isChanged = false;
    bool isInitial = false;
    Color? highlightColor;
    if (highlighting) {
      isChanged = value != null && initialValue != value;
      isInitial = initialValue == null;
      highlightColor = isChanged ? (isInitial ? Colors.green : Colors.orange) : null;
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
          Column(
            children: [
              Text(
                Adjustment.formatValue(value) + adjustment.unitSuffix(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: highlightColor,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
              if (!isInitial && isChanged)
                Opacity(
                  opacity: 0.7,
                  child: Text(
                    Adjustment.formatValue(initialValue) + adjustment.unitSuffix(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.lineThrough,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
