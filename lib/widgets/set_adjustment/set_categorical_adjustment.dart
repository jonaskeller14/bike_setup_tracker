import 'package:flutter/material.dart';
import '../../models/adjustment.dart';

class SetCategoricalAdjustmentWidget extends StatelessWidget {
  final CategoricalAdjustment adjustment;
  final String? initialValue;
  final String? value;
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
    final isChanged = initialValue != value;
    final isInitial = initialValue == null;
    final highlightColor = isChanged ? (isInitial ? Colors.green : Colors.orange) : null;
    final options = adjustment.options;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: isChanged
          ? BoxDecoration(color: highlightColor?.withValues(alpha: 0.08))
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.category, color: highlightColor),
          SizedBox(width: 10),
          Flexible(
            flex: 2,
            child: Text(
              adjustment.name,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor),
            ),
          ),
          SizedBox(width: 20),
          Flexible(
            flex: 3,
            child: DropdownButtonFormField<String>(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              initialValue: value,
              hint: const Text("Please select"),
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
