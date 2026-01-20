import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import "../set_adjustment/set_adjustment.dart";

class DisplayDurationAdjustmentWidget extends StatelessWidget {
  final DurationAdjustment adjustment;
  final Duration? initialValue;
  final Duration? value;
  final bool highlighting;

  const DisplayDurationAdjustmentWidget({
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
                Icon(DurationAdjustment.iconData, color: highlightColor),
                nameNotesSetAdjustmentWidget(context: context, adjustment: adjustment, highlightColor: highlightColor),
              ],
            )
          ),
          Column(
            children: [
              SelectableText.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: Adjustment.formatValue(value),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: highlightColor,
                      ),
                    ),
                    TextSpan(
                      text: adjustment.unitSuffix(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: highlightColor,
                      ),
                    ),
                  ],
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
                      decorationThickness: 2,
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
