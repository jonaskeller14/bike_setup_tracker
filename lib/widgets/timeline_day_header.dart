import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';

class TimelineDayHeader extends StatelessWidget {
  final DateTime day;
  final EdgeInsetsGeometry margin;
  final bool onContainerSurface;

  const TimelineDayHeader({
    super.key,
    required this.day,
    this.margin = const EdgeInsets.only(top: 12, bottom: 4),
    this.onContainerSurface = false,
  });

  // One header is built per day in the timeline, so DateFormat instances are
  // cached instead of re-created (and their pattern re-parsed) per header.
  static final Map<String, DateFormat> _formats = {};
  static DateFormat _format(String pattern) =>
      _formats.putIfAbsent(pattern, () => DateFormat(pattern));

  String _label(AppSettings appSettings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateText =
        "${_format('EEE').format(day)}, ${_format(appSettings.dateFormat).format(day)}";
    if (day == today) return "Today · $dateText";
    if (day == yesterday) return "Yesterday · $dateText";
    return dateText;
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: onContainerSurface
            ? colorScheme.surfaceDim
            : colorScheme.surfaceContainerHighest,
        border: onContainerSurface
            ? Border.symmetric(
                horizontal: BorderSide(color: colorScheme.outlineVariant),
              )
            : null,
      ),
      child: Text(
        _label(appSettings),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
