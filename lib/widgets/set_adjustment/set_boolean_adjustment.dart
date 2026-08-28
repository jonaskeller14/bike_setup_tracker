import 'package:flutter/material.dart';

import '../../models/adjustment/adjustment.dart';
import '../../theme.dart';
import '../display_adjustment/adjustment_icon_name_notes.dart';

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
    final highlights = Theme.of(context).extension<ValueHighlightColors>();
    if (highlighting) {
      isChanged = initialValue != value;
      isInitial = initialValue == null;
      highlightColor = isChanged ? (isInitial ? highlights?.initial ?? Colors.green : highlights?.changed ?? Colors.orange) : null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isChanged ? (isInitial ? highlights?.initialFill ?? Colors.green.withValues(alpha: 0.08) : highlights?.changedFill ?? Colors.orange.withValues(alpha: 0.08)) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 20,
        children: [
          Flexible(
            flex: 3,
            child: AdjustmentIconNameNotes(adjustment: adjustment, color: highlightColor),
          ),
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: value == null
                  ? OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => onChanged(false),
                      child: const Text("Set value"),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch.adaptive(value: value!, onChanged: onChanged),
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
