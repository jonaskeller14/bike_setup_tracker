import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../utils/filter_actions.dart';
import 'filter/activity_filter_section.dart';
import 'filter/bike_filter_section.dart';
import 'filter/date_range_filter_section.dart';
import 'filter/layer_filter_section.dart';
import 'filter/setup_filter_section.dart';
import 'filter/task_priority_filter_section.dart';
import 'filter/task_tags_filter_section.dart';
import 'sheet.dart';
import 'sheet_header.dart';

enum FilterSection { bike, dateRange, setups, taskPriority, taskTags, activity, mapLayers, timelineLayers }

Widget _sectionWidget(FilterSection section) => switch (section) {
  FilterSection.bike => const BikeFilterSection(),
  FilterSection.dateRange => const DateRangeFilterSection(),
  FilterSection.setups => const SetupFilterSection(),
  FilterSection.taskPriority => const TaskPriorityFilterSection(),
  FilterSection.taskTags => const TaskTagsFilterSection(),
  FilterSection.activity => const ActivityFilterSection(),
  FilterSection.mapLayers || FilterSection.timelineLayers => LayerFilterSection(section: section),
};

Future<void> showFilterSheet({
  required BuildContext context,
  required Set<FilterSection> sections,
}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) {
      final appSettings = context.watch<AppSettings>();
      final stravaActive = appSettings.enableStrava &&
          context.watch<SubscriptionService>().hasStravaEntitlement;
      final enabled = FilterActions.enabledSections(sections, appSettings: appSettings, stravaActive: stravaActive);

      final isFiltered = FilterActions.isFiltered(
        sections,
        appRepository: context.watch<AppRepository>(),
        appSettings: appSettings,
        stravaActive: stravaActive,
      );

      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(
              title: 'Filter',
              actions: [
                sheetActionButton(
                  context,
                  icon: Icons.filter_alt_off,
                  tooltip: 'Reset filters',
                  onPressed: isFiltered
                      ? () {
                          unawaited(HapticFeedback.selectionClick());
                          FilterActions.clear(context, sections);
                        }
                      : null,
                ),
                const SizedBox(width: 4),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final section in FilterSection.values)
                      if (enabled.contains(section)) _sectionWidget(section),
                  ],
                ),
              )
            ),
          ],
        ),
      );
    },
  );
}
