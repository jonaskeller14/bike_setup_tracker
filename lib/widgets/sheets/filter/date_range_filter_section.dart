import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../models/app_settings.dart';
import '../../../models/filters/local_date_range.dart';
import '../../../repositories/app_repository.dart';
import '../../../repositories/filter_controller.dart';
import '../../../utils/filter_actions.dart';
import '../../text/sheet_section_title.dart';
import 'filter_range_slider.dart';

class DateRangeFilterSection extends StatelessWidget {
  const DateRangeFilterSection({super.key});

  Future<void> _pickRange(BuildContext context, FilterController filters) async {
    final range = filters.dateRange;
    final picked = await showDateRangePicker(
      context: context,
      helpText: "Select Date Range",
      initialDateRange: range == null ? null : DateTimeRange(start: range.start, end: range.end),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null || !context.mounted) return;

    unawaited(HapticFeedback.selectionClick());
    filters.dateRange = LocalDateRange(start: picked.start, end: picked.end);
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final filters = appRepository.filters;
    final dateFormat = context.select<AppSettings, String>((s) => s.dateFormat);
    final label = FilterActions.dateRangeLabel(filters.dateRange, dateFormat: dateFormat);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = appRepository.firstEntryDay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetSectionTitle(title: "Date"),
        if (firstDay != null && firstDay.isBefore(today))
          _DateRangeSlider(
            firstDay: firstDay,
            lastDay: today,
            range: filters.dateRange,
            dateFormat: dateFormat,
            onPickExact: () => _pickRange(context, filters),
            onChanged: (range) {
              unawaited(HapticFeedback.selectionClick());
              filters.dateRange = range;
            },
          )
        else
          FilterChip(
            avatar: const Icon(Icons.calendar_month),
            label: Text(label ?? "Any date", maxLines: 1, overflow: TextOverflow.ellipsis),
            selected: label != null,
            showCheckmark: false,
            onSelected: (_) => _pickRange(context, filters),
            onDeleted: label != null ? () => filters.dateRange = null : null,
          ),
      ],
    );
  }
}

/// A slider over the days from [firstDay] to [lastDay] for a rough range, with
/// a button to [onPickExact] days. Both thumbs at the ends clear the range.
class _DateRangeSlider extends StatelessWidget {
  final DateTime firstDay;
  final DateTime lastDay;
  final LocalDateRange? range;
  final String dateFormat;
  final VoidCallback onPickExact;
  final ValueChanged<LocalDateRange?> onChanged;

  const _DateRangeSlider({
    required this.firstDay,
    required this.lastDay,
    required this.range,
    required this.dateFormat,
    required this.onPickExact,
    required this.onChanged,
  });

  /// Calendar days, so a DST change (a 23 or 25 hour day) does not shift it.
  int _daysSinceFirst(DateTime day) {
    final utcDay = DateTime.utc(day.year, day.month, day.day);
    return utcDay.difference(DateTime.utc(firstDay.year, firstDay.month, firstDay.day)).inDays;
  }

  DateTime _day(double offset) => DateTime(firstDay.year, firstDay.month, firstDay.day + offset.round());

  LocalDateRange? _toRange(RangeValues values, double max) {
    if (values.start.round() <= 0 && values.end.round() >= max) return null;
    return LocalDateRange(start: _day(values.start), end: _day(values.end));
  }

  @override
  Widget build(BuildContext context) {
    final max = _daysSinceFirst(lastDay).toDouble();
    final range = this.range;
    final values = range == null
        ? RangeValues(0, max)
        : RangeValues(
            _daysSinceFirst(range.start).clamp(0, max).toDouble(),
            _daysSinceFirst(range.end).clamp(0, max).toDouble(),
          );

    return FilterRangeSlider(
      values: values,
      max: max,
      // Day ticks only while they stay apart; a longer track is rounded to days on release.
      divisions: max <= 60 ? max.round() : null,
      valueLabel: (dragging) =>
          FilterActions.dateRangeLabel(dragging == null ? range : _toRange(dragging, max), dateFormat: dateFormat) ??
          "Any date",
      trailing: IconButton(
        icon: const Icon(Icons.calendar_month),
        tooltip: "Pick exact dates",
        visualDensity: VisualDensity.compact,
        onPressed: onPickExact,
      ),
      onChangeEnd: (values) => onChanged(_toRange(values, max)),
    );
  }
}
