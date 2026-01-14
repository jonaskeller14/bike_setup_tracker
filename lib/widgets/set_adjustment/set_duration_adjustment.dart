import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment/adjustment.dart';
import "set_adjustment.dart";

class SetDurationAdjustmentWidget extends StatelessWidget {
  final DurationAdjustment adjustment;
  final Duration? initialValue;
  final Duration? value;
  final ValueChanged<Duration> onChanged;
  final bool highlighting;

  const SetDurationAdjustmentWidget({
    required super.key,
    required this.adjustment,
    required this.initialValue,
    required this.value,
    required this.onChanged,
    this.highlighting = true,
  });

  void _showTimerPickerBottomSheet(BuildContext context) async {
    return await showModalBottomSheet<void>(
      showDragHandle: true,
      useSafeArea: true,
      context: context,
      builder: (BuildContext context) {
        //TODO: Add option to remove/reset value (cross in the top right corner?)
        return SizedBox(
          height: 200,
          child: CupertinoTimerPicker(
            mode: CupertinoTimerPickerMode.hms,
            initialTimerDuration: value ?? Duration(),
            onTimerDurationChanged: (Duration newValue) {
              HapticFeedback.lightImpact();
              //FIXME: Add min/max validation --> Clamp duration and show snackbar
              onChanged(newValue);
            },
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    late bool isChanged;
    late bool isInitial;
    late Color? highlightColor; 
    if (highlighting) {
      isChanged = value == null ? false : initialValue != value;
      isInitial = initialValue == null;
      highlightColor = isChanged ? (isInitial ? Colors.green : Colors.orange) : null;
    } else {
      isChanged = false;
      isInitial = false;
      highlightColor = null;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isChanged ? highlightColor?.withValues(alpha: 0.08) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 20,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Icon(DurationAdjustment.iconData, color: highlightColor),
                SizedBox(width: 10),
                nameNotesSetAdjustmentWidget(context: context, adjustment: adjustment, highlightColor: highlightColor),
              ],
            )
          ),
          InkWell(
            onTap: () => _showTimerPickerBottomSheet(context),
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Adjustment.formatValue(value),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: highlightColor,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit, 
                  size: 20, 
                  color: highlightColor ?? Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
