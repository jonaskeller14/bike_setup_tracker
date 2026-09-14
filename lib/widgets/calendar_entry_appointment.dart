import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarEntryAppointment extends StatelessWidget {
  final CalendarAppointmentDetails details;
  final IconData icon;
  final String subject;
  final Color color;
  final Color contentColor;
  final bool ghost;

  const CalendarEntryAppointment({
    super.key,
    required this.details,
    required this.icon,
    required this.subject,
    required this.contentColor,
    required this.color,
    this.ghost=false
  });

  @override
  Widget build(BuildContext context) {
    final height = details.bounds.height;
    final width = details.bounds.width;
    // Decide what fits so a narrow column (many concurrent events) never
    // overflows: drop the label, then the icon, as space runs out. The label is
    // gated mainly on width, so it still shows in the short-but-wide month rows.
    final bool showIcon = width >= 16 && height >= 8;
    final bool showText = width >= 40 && height >= 9;
    final double baseIconSize = height < 16 ? 9 : (height < 20 ? 11 : 14);
    final double fontSize = height < 18 ? 9 : (height < 28 ? 10 : 12);
    // Slim parallel events (week view) can be narrow but tall: cap the icon to
    // the width left after padding — and the icon/label gap when text shows —
    // so a height-sized icon never spills past a thin column.
    final double iconBudget = showText ? width - 12 : width - 4;
    final double iconSize = iconBudget <= 0 ? 0 : (baseIconSize < iconBudget ? baseIconSize : iconBudget);

    // Calculate how many full text lines can physically fit.
    final double verticalPadding = height < 20 ? 0.0 : 4.0;
    final double availableHeight = height - verticalPadding;
    final double fontLineHeight = fontSize * 1.15;
    final int maxLines = (availableHeight / fontLineHeight).floor().clamp(1, 100);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: ghost ? Theme.of(context).colorScheme.surface : color,
        border: ghost ? Border.all(color: color) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: showText ? 4 : 2,
        vertical: verticalPadding / 2,
      ),
      alignment: Alignment.centerLeft,
      child: !showIcon
          ? const SizedBox.shrink()
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: iconSize, color: contentColor),
                if (showText) ...[
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      subject,
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: contentColor,
                        fontSize: fontSize,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
