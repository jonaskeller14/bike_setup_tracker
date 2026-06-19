import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/person.dart';
import '../../models/task/task_rule.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../text/sheet_section_title.dart';
import 'sheet.dart';

Future<void> showFilterSheet({
  required BuildContext context,
  required bool enableSetupTagFilter,
  bool enableTaskRuleTagFilter = false,
  required bool enableTaskPriorityFilter,
  bool showMapVisibility = false,
  bool showTimelineVisibility = false,
  bool showOnlyChangesSection = false,
  bool showByCategorySection = false,
}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  sheetTitle(context, 'Filter'),
                  sheetCloseButton(context),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SheetSectionTitle(title: "Bike"),
                    appRepository.bikes.isEmpty 
                        ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text("No bikes yet", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
                          ),
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
                    if (enableSetupTagFilter) ...[
                      const SheetSectionTitle(title: "Setup Tags"),
                      appRepository.setupTags.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text("No tags yet. Add/Edit a Setup to add a tag.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
                              ),
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
                    if (enableTaskPriorityFilter) ...[
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
                    if (enableTaskRuleTagFilter) ...[
                      const SheetSectionTitle(title: "Task Tags"),
                      appRepository.taskRuleTags.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text("No tags yet. Add/Edit a Task Rule to add a tag.", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
                              ),
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
                    // ---- Display options (folded-in "Display" chip) ----
                    // Map visibility: only geo-located entry types.
                    if (showMapVisibility) ...[
                      const SheetSectionTitle(title: "Visibility"),
                      Wrap(
                        spacing: 6,
                        children: [
                          FilterChip(
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
                              label: const Text("Strava Activities"),
                              showCheckmark: false,
                              selected: appSettings.displayShowActivities,
                              onSelected: (bool selected) => appSettings.displayShowActivities = selected,
                              onDeleted: appSettings.displayShowActivities
                                  ? () => appSettings.displayShowActivities = false
                                  : null,
                            ),
                        ],
                      ),
                    ],
                    // Timeline visibility: all entry types shown in the list.
                    if (showTimelineVisibility) ...[
                      const SheetSectionTitle(title: "Visibility"),
                      Wrap(
                        spacing: 6,
                        children: [
                          FilterChip(
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
                              label: const Text("Strava Activities"),
                              showCheckmark: false,
                              selected: appSettings.displayShowActivities,
                              onSelected: (bool selected) => appSettings.displayShowActivities = selected,
                              onDeleted: appSettings.displayShowActivities
                                  ? () => appSettings.displayShowActivities = false
                                  : null,
                            ),
                          if (appSettings.enableTask)
                            FilterChip(
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
                              label: const Text("Installations"),
                              showCheckmark: false,
                              selected: appSettings.displayShowInstallations,
                              onSelected: (bool selected) => appSettings.displayShowInstallations = selected,
                              onDeleted: appSettings.displayShowInstallations
                                  ? () => appSettings.displayShowInstallations = false
                                  : null,
                            ),
                        ],
                      ),
                    ],
                    if (showOnlyChangesSection) ...[
                      const SheetSectionTitle(title: "Setups"),
                      Wrap(
                        spacing: 6,
                        children: [
                          FilterChip(
                            label: const Text("Display Only Changes"),
                            showCheckmark: false,
                            selected: appSettings.setupListOnlyChanges,
                            onSelected: (bool selected) => appSettings.setupListOnlyChanges = selected,
                            tooltip: "Show only changed values",
                            onDeleted: appSettings.setupListOnlyChanges
                                ? () => appSettings.setupListOnlyChanges = false
                                : null,
                          ),
                        ],
                      ),
                    ],
                    if (showByCategorySection && (appSettings.enablePerson || appSettings.enableRating)) ...[
                      const SheetSectionTitle(title: "By Category"),
                      Wrap(
                        spacing: 6,
                        children: [
                          FilterChip(
                            avatar: const Icon(Bike.iconData, size: 20),
                            showCheckmark: false,
                            label: const Text("Bike Values"),
                            selected: appSettings.setupListBikeAdjustmentValues,
                            onSelected: (bool selected) => appSettings.setupListBikeAdjustmentValues = selected,
                            tooltip: "Show bike/component related values",
                            onDeleted: appSettings.setupListBikeAdjustmentValues
                                ? () => appSettings.setupListBikeAdjustmentValues = false
                                : null,
                          ),
                          if (appSettings.enablePerson)
                            FilterChip(
                              avatar: const Icon(Person.iconData, size: 20),
                              showCheckmark: false,
                              label: const Text("Person Values"),
                              selected: appSettings.setupListPersonAdjustmentValues,
                              onSelected: (bool selected) => appSettings.setupListPersonAdjustmentValues = selected,
                              tooltip: "Show person related values",
                              onDeleted: appSettings.setupListPersonAdjustmentValues
                                  ? () => appSettings.setupListPersonAdjustmentValues = false
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
