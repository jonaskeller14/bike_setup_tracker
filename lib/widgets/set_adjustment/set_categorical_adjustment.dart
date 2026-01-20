import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import "set_adjustment.dart";

class SetCategoricalAdjustmentWidget extends StatelessWidget {
  final CategoricalAdjustment adjustment;
  final String? initialValue;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool highlighting;

  const SetCategoricalAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
    this.highlighting = true,
  });

  @override
  Widget build(BuildContext context) {
    late bool isChanged;
    late bool isInitial;
    late Color? highlightColor; 
    if (highlighting) {
      isChanged = initialValue != value;
      isInitial = initialValue == null;
      highlightColor = isChanged ? (isInitial ? Colors.green : Colors.orange) : null;
    } else {
      isChanged = false;
      isInitial = false;
      highlightColor = null;
    }
    final Set<String> options = adjustment.options;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isChanged ? highlightColor?.withValues(alpha: 0.08) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 20,
        children: [
          Flexible(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(CategoricalAdjustment.iconData, color: highlightColor),
                SizedBox(width: 10),
                nameNotesSetAdjustmentWidget(context: context, adjustment: adjustment, highlightColor: highlightColor),
              ],
            )
          ),
          Flexible(
            flex: 3,
            child: DropdownButtonFormField<String>(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              initialValue: options.contains(value) ? value : null,
              hint: const Text("Please select"),
              items: options.map<DropdownMenuItem<String>>((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(option, overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: highlighting && option != value
                              ? (initialValue != option) 
                                  ? ((initialValue == null) 
                                      ? Colors.green : Colors.orange).withValues(alpha: 0.16)
                                      : null
                              : null,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
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
