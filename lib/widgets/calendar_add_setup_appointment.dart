import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarAddSetupSlot {
  const CalendarAddSetupSlot(this.date);

  final DateTime date;
}

class CalendarAddSetupAppointment extends StatelessWidget {
  final CalendarAppointmentDetails details;
  final CalendarAddSetupSlot slot;
  final void Function(DateTime date) addSetupAtDate;

  const CalendarAddSetupAppointment({super.key, required this.details, required this.slot, required this.addSetupAtDate});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showIcon = details.bounds.width >= 24 && details.bounds.height >= 18;
    final showLabel = showIcon && details.bounds.width >= 88;
    return Material(
      color: cs.primaryContainer,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.primary),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => addSetupAtDate(slot.date),
        child: !showIcon
            ? const SizedBox.expand()
            : Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 18, color: cs.onPrimaryContainer),
                    if (showLabel) ...[
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          'Add setup',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
