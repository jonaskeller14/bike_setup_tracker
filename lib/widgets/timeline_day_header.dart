import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';

class TimelineDayHeader extends StatelessWidget {
  final DateTime day;

  const TimelineDayHeader({super.key, required this.day});

  String _label(AppSettings appSettings) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateText =
        "${DateFormat('EEE').format(day)}, ${DateFormat(appSettings.dateFormat).format(day)}";
    if (day == today) return "Today · $dateText";
    if (day == yesterday) return "Yesterday · $dateText";
    return dateText;
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12, bottom: 4),
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
