import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';
import "set_adjustment.dart";

class SetBooleanAdjustmentWidget extends StatelessWidget {
  final BooleanAdjustment adjustment;
  final bool? initialValue;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final bool highlighting;

  const SetBooleanAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
    this.highlighting = true,
  });

  @override
  Widget build(BuildContext context) {
    bool isChanged = false;
    bool isInitial = false;
    Color? highlightColor;
    if (highlighting) {
      isChanged = initialValue != value;
      isInitial = initialValue == null;
      highlightColor = isChanged ? (isInitial ? Colors.green : Colors.orange) : null;
    }

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
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(BooleanAdjustment.iconData, color: highlightColor),
                const SizedBox(width: 10),
                nameNotesSetAdjustmentWidget(context: context, adjustment: adjustment, highlightColor: highlightColor),
              ],
            )
          ),
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: value == null
                  ? OutlinedButton(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => onChanged(false),
                      child: const Text("Set value"),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(value: value!, onChanged: onChanged),
                        if (isInitial)
                          IconButton(
                            onPressed: () => onChanged(null), 
                            icon: const Icon(Icons.replay),
                            visualDensity: VisualDensity.compact,
                          ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
