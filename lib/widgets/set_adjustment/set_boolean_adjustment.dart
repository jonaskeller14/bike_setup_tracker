import 'package:flutter/material.dart';
import '../../models/adjustment/adjustment.dart';

class SetBooleanAdjustmentWidget extends StatelessWidget {
  final BooleanAdjustment adjustment;
  final bool? initialValue;
  final bool? value;
  final ValueChanged<bool> onChanged;
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
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: adjustment.notes == null 
                        ? Text(adjustment.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor))
                        : Tooltip(
                            triggerMode: TooltipTriggerMode.tap,
                            preferBelow: false,
                            showDuration: const Duration(seconds: 5),
                            message: adjustment.notes!,
                            child: Text.rich(
                              TextSpan(
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: highlightColor),
                                children: [
                                  TextSpan(text: adjustment.name),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 2),
                                      child: Opacity(
                                        opacity: 0.5,
                                        child: Icon(
                                          Icons.info_outline,
                                          color: highlightColor,
                                          size: Theme.of(context).textTheme.bodyMedium?.fontSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            )
          ),
          Flexible(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: value == null
                  ? FilledButton(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => onChanged(false),
                      child: const Text("Set value"),
                    )
                  : Switch(
                      value: value!,
                      onChanged: onChanged,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
