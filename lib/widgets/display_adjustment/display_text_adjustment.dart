import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import 'adjustment_icon_name_notes.dart';

class DisplayTextAdjustmentWidget extends StatelessWidget {
  final TextAdjustment adjustment;
  final String? initialValue;
  final String? value;
  final bool highlighting;
  final bool isError;
  final VoidCallback? onRemove;

  const DisplayTextAdjustmentWidget({
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
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.lineThrough,
                        decorationThickness: 2,
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
