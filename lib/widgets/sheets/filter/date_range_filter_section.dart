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
    final filters = context.watch<AppRepository>().filters;
    final dateFormat = context.select<AppSettings, String>((s) => s.dateFormat);
    final label = FilterActions.dateRangeLabel(filters.dateRange, dateFormat: dateFormat);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SheetSectionTitle(title: "Date"),
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
