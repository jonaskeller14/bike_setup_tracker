import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';

class TimelineDayHeader extends StatelessWidget {
  final DateTime day;
  final EdgeInsetsGeometry margin;

  const TimelineDayHeader({
    super.key,
    required this.day,
    this.margin = const EdgeInsets.only(top: 12, bottom: 4),
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
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        _label(appSettings),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
