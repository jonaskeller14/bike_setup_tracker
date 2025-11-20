import 'package:flutter/material.dart';
import '../../models/adjustment.dart';

class SetCategoricalAdjustmentWidget extends StatelessWidget {
  final CategoricalAdjustment adjustment;
  final String? initialValue;
  final String value;
  final ValueChanged<String?> onChanged;

  const SetCategoricalAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final changed = initialValue != value;
    final highlightColor = changed ? Colors.orange : null;
    final options = adjustment.options;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: changed
          ? BoxDecoration(color: highlightColor?.withValues(alpha: 0.08))
          : null,
      child: Row(
        children: [
          Icon(Icons.category, color: highlightColor),
          SizedBox(width: 10),
          Text(
            adjustment.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor),
          ),
          SizedBox(width: 30),
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              initialValue: value,
              items: options.map<DropdownMenuItem<String>>((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, overflow: TextOverflow.ellipsis,),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
