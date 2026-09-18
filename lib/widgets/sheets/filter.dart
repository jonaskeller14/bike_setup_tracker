import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../icons/simple_icons.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/rating/rating.dart';
import '../../models/setup.dart';
import '../../models/task/task_rule.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../text/sheet_section_title.dart';
import 'sheet.dart';
import 'sheet_header.dart';

class _IsolatableChipOption {
  const _IsolatableChipOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final IconData? icon;
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;
}

Widget _buildIsolatableChips(List<_IsolatableChipOption> options) {
  return Wrap(
    spacing: 6,
    children: List.generate(options.length, (index) {
      final option = options[index];
      return GestureDetector(
        onLongPress: options.length < 2
            ? null
            : () {
                final isIsolated = option.selected &&
                    options.where((o) => o.selected).length == 1;
                for (var i = 0; i < options.length; i++) {
                  options[i].onChanged(isIsolated ? true : i == index);
                }
              },
        child: FilterChip(
          avatar: option.icon == null ? null : Icon(option.icon),
          label: Text(option.label),
          showCheckmark: false,
          selected: option.selected,
          onSelected: option.onChanged,
          onDeleted: option.selected ? () => option.onChanged(false) : null,
        ),
      );
    }),
  );
}

Future<void> showFilterSheet({
  required BuildContext context,
  required bool showBikes,
  required bool showSetupTags,
  required bool showSetupBookmark,
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
                    if (showSetupBookmark || showSetupTags) ...[
                      SheetSectionTitle(title: showSetupBookmark ? "Setups" : "Setup Tags"),
                      if (showSetupBookmark || appRepository.setupTags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          children: [
                            if (showSetupBookmark)
                              FilterChip(
                                avatar: Icon(appRepository.showBookmarkedSetupsOnly
                                    ? Icons.bookmark
                                    : Icons.bookmark_border),
                                label: const Text("Bookmarked"),
                                selected: appRepository.showBookmarkedSetupsOnly,
                                showCheckmark: false,
                                onSelected: (bool newValue) => appRepository.setShowBookmarkedSetupsOnly(newValue),
                                onDeleted: appRepository.showBookmarkedSetupsOnly
                                    ? () => appRepository.setShowBookmarkedSetupsOnly(false)
                                    : null,
                              ),
                            if (showSetupTags)
                              ...appRepository.setupTags.map((tag) {
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
                              }),
                          ],
                        ),
                      if (showSetupTags && appRepository.setupTags.isEmpty)
                        const SheetFilterEmptyHint(
                          icon: Icons.tag,
                          title: "No setup tags yet",
                          hint: "Add/Edit a Setup to add tags.",
                        ),
                    ],
                    if (showTaskPriority) ...[
                      const SheetSectionTitle(title: "Task Priority"),
                      _buildIsolatableChips(TaskPriority.values.map((tp) {
                        return _IsolatableChipOption(
                          icon: null,
                          label: tp.label,
                          selected: appRepository.selectedTaskPriorities.contains(tp),
                          onChanged: (selected) {
                            switch (selected) {
                              case true: appRepository.selectTaskPriority(tp);
                              case false: appRepository.deselectTaskPriority(tp);
                            }
                          },
                        );
                      }).toList()),
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
                      _buildIsolatableChips([
                        _IsolatableChipOption(
                          icon: Setup.iconData,
                          label: "Setups",
                          selected: appSettings.displayShowSetups,
                          onChanged: (selected) => appSettings.displayShowSetups = selected,
                        ),
                        if (stravaActive)
                          _IsolatableChipOption(
                            icon: SimpleIcons.strava,
                            label: "Strava Activities",
                            selected: appSettings.displayShowActivities,
                            onChanged: (selected) => appSettings.displayShowActivities = selected,
                          ),
                        if (appSettings.enableRating)
                          _IsolatableChipOption(
                            icon: Rating.iconData,
                            label: "Ratings",
                            selected: appSettings.displayShowRatingEntries,
                            onChanged: (selected) => appSettings.displayShowRatingEntries = selected,
                          ),
                      ]),
                    ],
                    if (showTimelineVisibility) ...[
                      const SheetSectionTitle(title: "Visibility"),
                      _buildIsolatableChips([
                        _IsolatableChipOption(
                          icon: Setup.iconData,
                          label: "Setups",
                          selected: appSettings.displayShowSetups,
                          onChanged: (selected) => appSettings.displayShowSetups = selected,
                        ),
                        if (stravaActive)
                          _IsolatableChipOption(
                            icon: SimpleIcons.strava,
                            label: "Activities",
                            selected: appSettings.displayShowActivities,
                            onChanged: (selected) => appSettings.displayShowActivities = selected,
                          ),
                        if (appSettings.enableTask)
                          _IsolatableChipOption(
                            icon: Icons.check_box_outlined,
                            label: "Tasks",
                            selected: appSettings.displayShowTasks,
                            onChanged: (selected) => appSettings.displayShowTasks = selected,
                          ),
                        if (appSettings.enableInstallationTimeline)
                          _IsolatableChipOption(
                            icon: Icons.swap_horiz,
                            label: "Installations",
                            selected: appSettings.displayShowInstallations,
                            onChanged: (selected) => appSettings.displayShowInstallations = selected,
                          ),
                        if (appSettings.enableRating)
                          _IsolatableChipOption(
                            icon: Rating.iconData,
                            label: "Ratings",
                            selected: appSettings.displayShowRatingEntries,
                            onChanged: (selected) => appSettings.displayShowRatingEntries = selected,
                          ),
                      ]),
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
