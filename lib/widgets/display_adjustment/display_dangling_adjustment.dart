import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import "../set_adjustment/set_adjustment.dart";

class DisplayDanglingAdjustmentWidget extends StatelessWidget {
  final String name;
  final dynamic value;
  final VoidCallback? onRemove;

  const DisplayDanglingAdjustmentWidget({
    super.key,
    required this.name,
    required this.value,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final highlightColor = Theme.of(context).colorScheme.error;
    
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
                Icon(Icons.question_mark, color: highlightColor),
                nameSetAdjustmentWidget(context: context, name: name, highlightColor: highlightColor),
              ],
            )
          ),
          Flexible(
            flex: 1,
            child: Column(
              children: [
                SelectableText(
                  Adjustment.formatValue(value),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: highlightColor,
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
