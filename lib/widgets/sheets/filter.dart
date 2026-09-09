import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../icons/simple_icons.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/rating.dart';
import '../../models/setup.dart';
import '../../models/task/task_rule.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../text/sheet_section_title.dart';
import 'sheet.dart';
import 'sheet_header.dart';

Future<void> showFilterSheet({
  required BuildContext context,
  required bool showBikes,
  required bool showSetupTags,
  required bool showTaskPriority,
  required bool showTaskTags,
  required bool showMapVisibility,
  required bool showTimelineVisibility,
}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) {
      final appRepository = context.watch<AppRepository>();
      final appSettings = context.watch<AppSettings>();
      final stravaActive = appSettings.enableStrava &&
          context.watch<SubscriptionService>().hasStravaEntitlement;

      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(title: 'Filter'),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showBikes) ...[
                      const SheetSectionTitle(title: "Bike"),
                      appRepository.bikes.isEmpty
                          ? const SheetFilterEmptyHint(
                              icon: Bike.iconData,
                              title: "No bikes yet",
                              hint: "Add a bike to filter this list by bike.",
                            )
                          : Wrap(
                              spacing: 6,
                              children: appRepository.bikes.values.map((bike) => FilterChip(
                                avatar: const Icon(Bike.iconData),
                                label: Text(bike.name),
                                selected: bike.id == appRepository.selectedBike,
                                showCheckmark: false,
                                onSelected: (bool newValue) {
                                  switch (newValue) {
                                    case true: appRepository.onBikeTap(bike.id);
                                    case false: appRepository.onBikeTap(bike.id);
                                  }
                                },
                                onDeleted: appRepository.selectedBike != null && appRepository.selectedBike == bike.id
                                    ? () => appRepository.onBikeTap(bike.id)
                                    : null,
                              )).toList(),
                            ),
                    ],
                    if (showSetupTags) ...[
                      const SheetSectionTitle(title: "Setup Tags"),
                      appRepository.setupTags.isEmpty
                          ? const SheetFilterEmptyHint(
                              icon: Icons.tag,
                              title: "No setup tags yet",
                              hint: "Add/Edit a Setup to add tags.",
                            )
                          : Wrap(
                              spacing: 6,
                              children: appRepository.setupTags.map((tag) {
                                return FilterChip(
                                  avatar: const Icon(Icons.tag),
                                  label: Text(tag),
                                  selected: appRepository.selectedSetupTags.contains(tag),
                                  showCheckmark: false,
                                  onSelected: (bool newValue) {
                                    switch (newValue) {
                                      case true: appRepository.selectSetupTag(tag);
                                      case false: appRepository.deselectSetupTag(tag);
                                    }
                                  },
                                  onDeleted: appRepository.selectedSetupTags.contains(tag)
                                      ? () => appRepository.deselectSetupTag(tag)
                                      : null,
                                );
                              }).toList(),
                            ),
                    ],
                    if (showTaskPriority) ...[
                      const SheetSectionTitle(title: "Task Priority"),
                      Wrap(
                        spacing: 6,
                        children: TaskPriority.values.map((tp) {
                          return FilterChip(
                            label: Text(tp.label),
                            selected: appRepository.selectedTaskPriorities.contains(tp),
                            showCheckmark: false,
                            onSelected: (bool newValue) {
                              switch (newValue) {
                                case true: appRepository.selectTaskPriority(tp);
                                case false: appRepository.deselectTaskPriority(tp);
                              }
                            },
                            onDeleted: appRepository.selectedTaskPriorities.contains(tp)
                                ? () => appRepository.deselectTaskPriority(tp)
                                : null
                          );
                        }).toList(),
                      )
                    ],
                    if (showTaskTags) ...[
                      const SheetSectionTitle(title: "Task Tags"),
                      appRepository.taskRuleTags.isEmpty
                          ? const SheetFilterEmptyHint(
                              icon: Icons.tag,
                              title: "No task tags yet",
                              hint: "Add/Edit a Task Rule to add tags.",
                            )
                          : Wrap(
                              spacing: 6,
                              children: appRepository.taskRuleTags.map((tag) {
                                return FilterChip(
                                  avatar: const Icon(Icons.tag),
                                  label: Text(tag),
                                  selected: appRepository.selectedTaskRuleTags.contains(tag),
                                  showCheckmark: false,
                                  onSelected: (bool newValue) {
                                    switch (newValue) {
                                      case true: appRepository.selectTaskRuleTag(tag);
                                      case false: appRepository.deselectTaskRuleTag(tag);
                                    }
                                  },
                                  onDeleted: appRepository.selectedTaskRuleTags.contains(tag)
                                      ? () => appRepository.deselectTaskRuleTag(tag)
                                      : null,
                                );
                              }).toList(),
                            ),
                    ],
                    if (showMapVisibility) ...[
                      const SheetSectionTitle(title: "Visibility"),
                      Wrap(
                        spacing: 6,
                        children: [
                          FilterChip(
                            avatar: const Icon(Setup.iconData),
                            label: const Text("Setups"),
                            showCheckmark: false,
                            selected: appSettings.displayShowSetups,
                            onSelected: (bool selected) => appSettings.displayShowSetups = selected,
                            onDeleted: appSettings.displayShowSetups
                                ? () => appSettings.displayShowSetups = false
                                : null,
                          ),
                          if (stravaActive)
                            FilterChip(
                              avatar: const Icon(SimpleIcons.strava),
                              label: const Text("Strava Activities"),
                              showCheckmark: false,
                              selected: appSettings.displayShowActivities,
                              onSelected: (bool selected) => appSettings.displayShowActivities = selected,
                              onDeleted: appSettings.displayShowActivities
                                  ? () => appSettings.displayShowActivities = false
                                  : null,
                            ),
                          if (appSettings.enableRating)
                            FilterChip(
                              avatar: const Icon(Rating.iconData),
                              label: const Text("Ratings"),
                              showCheckmark: false,
                              selected: appSettings.displayShowRatingEntries,
                              onSelected: (bool selected) => appSettings.displayShowRatingEntries = selected,
                              onDeleted: appSettings.displayShowRatingEntries
                                  ? () => appSettings.displayShowRatingEntries = false
                                  : null,
                            ),
                        ],
                      ),
                    ],
                    if (showTimelineVisibility) ...[
                      const SheetSectionTitle(title: "Visibility"),
                      Wrap(
                        spacing: 6,
                        children: [
                          FilterChip(
                            avatar: const Icon(Setup.iconData),
                            label: const Text("Setups"),
                            showCheckmark: false,
                            selected: appSettings.displayShowSetups,
                            onSelected: (bool selected) => appSettings.displayShowSetups = selected,
                            onDeleted: appSettings.displayShowSetups
                                ? () => appSettings.displayShowSetups = false
                                : null,
                          ),
                          if (stravaActive)
                            FilterChip(
                              avatar: const Icon(SimpleIcons.strava),
                              label: const Text("Activities"),
                              showCheckmark: false,
                              selected: appSettings.displayShowActivities,
                              onSelected: (bool selected) => appSettings.displayShowActivities = selected,
                              onDeleted: appSettings.displayShowActivities
                                  ? () => appSettings.displayShowActivities = false
                                  : null,
                            ),
                          if (appSettings.enableTask)
                            FilterChip(
                              avatar: const Icon(Icons.check_box_outlined),
                              label: const Text("Tasks"),
                              showCheckmark: false,
                              selected: appSettings.displayShowTasks,
                              onSelected: (bool selected) => appSettings.displayShowTasks = selected,
                              onDeleted: appSettings.displayShowTasks
                                  ? () => appSettings.displayShowTasks = false
                                  : null,
                            ),
                          if (appSettings.enableInstallationTimeline)
                            FilterChip(
                              avatar: const Icon(Icons.swap_horiz),
                              label: const Text("Installations"),
                              showCheckmark: false,
                              selected: appSettings.displayShowInstallations,
                              onSelected: (bool selected) => appSettings.displayShowInstallations = selected,
                              onDeleted: appSettings.displayShowInstallations
                                  ? () => appSettings.displayShowInstallations = false
                                  : null,
                            ),
                          if (appSettings.enableRating)
                            FilterChip(
                              avatar: const Icon(Rating.iconData),
                              label: const Text("Ratings"),
                              showCheckmark: false,
                              selected: appSettings.displayShowRatingEntries,
                              onSelected: (bool selected) => appSettings.displayShowRatingEntries = selected,
                              onDeleted: appSettings.displayShowRatingEntries
                                  ? () => appSettings.displayShowRatingEntries = false
                                  : null,
                            ),
                        ],
                      ),
                    ],
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
