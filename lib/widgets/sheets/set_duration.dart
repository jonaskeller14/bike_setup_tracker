import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/adjustment/adjustment.dart';

void showSetDurationSheet({
  required BuildContext context, 
  required DurationAdjustment adjustment, 
  required Duration? value, 
  required ValueChanged<Duration> onChanged
}) async {
  Duration currentValue = value ?? Duration.zero;
  return await showModalBottomSheet<void>(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final bool isBelowMin = adjustment.min != null && currentValue < adjustment.min!;
          final bool isAboveMax = adjustment.max != null && currentValue > adjustment.max!;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (adjustment.min != null || adjustment.max != null)
                Row(
                  children: [
                    if (adjustment.min != null)
                      Expanded(
                        child: ListTile(
                          leading: Icon(
                            Icons.vertical_align_bottom, 
                            color: isBelowMin ? Theme.of(context).colorScheme.error : null,
                          ),
                          title: Text(
                            "Min: ${Adjustment.formatValue(adjustment.min)}",
                            style: TextStyle(color: isBelowMin ? Theme.of(context).colorScheme.error : null),
                          ),
                          dense: true,
                        ),
                      ),
                    if (adjustment.max != null)
                      Expanded(
                        child: ListTile(
                          leading: Icon(
                            Icons.vertical_align_top,
                            color: isAboveMax ? Theme.of(context).colorScheme.error : null,
                          ),
                          title: Text(
                            "Max: ${Adjustment.formatValue(adjustment.max)}",
                            style: TextStyle(color: isAboveMax ? Theme.of(context).colorScheme.error : null),
                          ),
                          dense: true,
                        ),
                      ),
                  ],
                ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: (isBelowMin || isAboveMax) 
                    ? ListTile(
                        leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                        title: Text(
                          isBelowMin ? "Selected duration is below the minimum" : "Selected duration exceeds the maximum",
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        dense: true,
                      )
                    : const SizedBox.shrink(),
              ),
              SizedBox(
                height: 200,
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hms,
                  initialTimerDuration: currentValue,
                  onTimerDurationChanged: (Duration newValue) {
                    HapticFeedback.lightImpact();
                    setSheetState(() {
                      currentValue = newValue;
                    });
                    
                    if (adjustment.isValidValue(newValue)) {
                      onChanged(newValue);
                      return;
                    }
              
                    if (adjustment.max != null && newValue > adjustment.max!) {
                      onChanged(adjustment.max!);
                    }
              
                    if (adjustment.min != null && newValue < adjustment.min!) {
                      onChanged(adjustment.min!);
                    }
                  },
                ),
              ),
            ],
          );
        }
      );
    }
  );
}