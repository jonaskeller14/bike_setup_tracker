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

Set<T> _toggled<T>(Set<T> values, T value, {required bool selected}) =>
    selected ? {...values, value} : values.difference({value});

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
      final filters = appRepository.filters;
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
                                selected: bike.id == filters.bikeId,
                                showCheckmark: false,
                                onSelected: (_) => filters.toggleBike(bike.id),
                                onDeleted: bike.id == filters.bikeId
                                    ? () => filters.toggleBike(bike.id)
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
                                avatar: Icon(filters.setup.bookmarkedOnly
                                    ? Icons.bookmark
                                    : Icons.bookmark_border),
                                label: const Text("Bookmarked"),
                                selected: filters.setup.bookmarkedOnly,
                                showCheckmark: false,
                                onSelected: (bool newValue) =>
                                    filters.setup = filters.setup.copyWith(bookmarkedOnly: newValue),
                                onDeleted: filters.setup.bookmarkedOnly
                                    ? () => filters.setup = filters.setup.copyWith(bookmarkedOnly: false)
                                    : null,
                              ),
                            if (showSetupTags)
                              ...appRepository.setupTags.map((tag) {
                                void select(bool selected) => filters.setup = filters.setup.copyWith(
                                  tags: _toggled(filters.setup.tags, tag, selected: selected),
                                );
                                return FilterChip(
                                  avatar: const Icon(Icons.tag),
                                  label: Text(tag),
                                  selected: filters.setup.tags.contains(tag),
                                  showCheckmark: false,
                                  onSelected: select,
                                  onDeleted: filters.setup.tags.contains(tag) ? () => select(false) : null,
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
                          selected: filters.taskRule.priorities.contains(tp),
                          onChanged: (selected) => filters.taskRule = filters.taskRule.copyWith(
                            priorities: _toggled(filters.taskRule.priorities, tp, selected: selected),
                          ),
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
                                void select(bool selected) => filters.taskRule = filters.taskRule.copyWith(
                                  tags: _toggled(filters.taskRule.tags, tag, selected: selected),
                                );
                                return FilterChip(
                                  avatar: const Icon(Icons.tag),
                                  label: Text(tag),
                                  selected: filters.taskRule.tags.contains(tag),
                                  showCheckmark: false,
                                  onSelected: select,
                                  onDeleted: filters.taskRule.tags.contains(tag) ? () => select(false) : null,
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
