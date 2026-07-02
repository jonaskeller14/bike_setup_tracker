import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import "../set_adjustment/set_adjustment.dart";

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
    if (highlighting) {
      isChanged = value != null && initialValue != value;
      isInitial = initialValue == null;
      highlightColor = isChanged ? (isInitial ? Colors.green : Colors.orange) : null;
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
            child: Row(
              mainAxisSize: MainAxisSize.max,
              spacing: 10,
              children: [
                Icon(NumericalAdjustment.iconData, color: highlightColor),
                nameNotesSetAdjustmentWidget(context: context, adjustment: adjustment, highlightColor: highlightColor),
              ],
            )
          ),
          Flexible(
            flex: 3,
            child: Column(
              children: [
                SelectableText.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: Adjustment.formatValue(value),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: highlightColor,
                          fontFeatures: [const FontFeature.tabularFigures()],
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
