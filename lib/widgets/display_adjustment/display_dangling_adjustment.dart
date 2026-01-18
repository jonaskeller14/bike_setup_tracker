import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import "../set_adjustment/set_adjustment.dart";

class DisplayDanglingAdjustmentWidget extends StatelessWidget {
  final String name;
  final dynamic initialValue;
  final dynamic value;
  final bool highlighting;

  const DisplayDanglingAdjustmentWidget({
    super.key,
    required this.name,
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
                if (!isInitial && isChanged)
                  Opacity(
                    opacity: 0.7,
                    child: Text(
                      Adjustment.formatValue(initialValue),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
