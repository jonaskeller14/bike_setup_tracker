import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import '../set_adjustment/set_adjustment.dart';

class DisplayDurationAdjustmentWidget extends StatelessWidget {
  final DurationAdjustment adjustment;
  final Duration? initialValue;
  final Duration? value;
  final bool highlighting;
  final bool isError;
  final VoidCallback? onRemove;

  const DisplayDurationAdjustmentWidget({
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
                Icon(DurationAdjustment.iconData, color: highlightColor),
                nameNotesSetAdjustmentWidget(context: context, adjustment: adjustment, highlightColor: highlightColor),
              ],
            )
          ),
          Flexible(
            child: Column(
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
