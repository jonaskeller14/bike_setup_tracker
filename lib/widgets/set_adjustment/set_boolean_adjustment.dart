import 'package:flutter/material.dart';
import '../../models/adjustment.dart';

class SetBooleanAdjustmentWidget extends StatelessWidget {
  final BooleanAdjustment adjustment;
  final bool? initialValue;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SetBooleanAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isChanged = initialValue != value;
    final isInitial = initialValue == null;
    final highlightColor = isChanged ? (isInitial ? Colors.green : Colors.orange) : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: isChanged
          ? BoxDecoration(color: highlightColor?.withValues(alpha: 0.08))
          : null,
      child: Row(
        children: [
          Icon(Icons.toggle_on, color: highlightColor),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              adjustment.name,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor),
            ),
          ),
          SizedBox(width: 20),
          Align(
            alignment: Alignment.centerRight,
            child: Switch(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
