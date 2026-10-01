import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/task/task_rule.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../utils/map_actions.dart';
import '../sheets/filter.dart';

class FilterSheetChip extends StatelessWidget {
  static const garageList = FilterSheetChip._(showBikes: true);
  static const setupList = FilterSheetChip._(showBikes: true, showSetupTags: true, showSetupBookmark: true, showTimelineVisibility: true);
  static const personList = FilterSheetChip._(showBikes: true);
  static const ratingList = FilterSheetChip._(showBikes: true);
  static const taskList = FilterSheetChip._(showBikes: true, showTaskPriority: true, showTaskTags: true);
  static const map = FilterSheetChip._(showBikes: true, showSetupTags: true, showSetupBookmark: true, showMapVisibility: true);
  static const calendar = FilterSheetChip._(showBikes: true, showSetupTags: true, showSetupBookmark: true, showTimelineVisibility: true);
  static const componentDetailsPage = FilterSheetChip._(showBikes: true, showSetupTags: true, showSetupBookmark: true);
  static const bikeDetailsPage = FilterSheetChip._(showSetupTags: true, showSetupBookmark: true);

  final bool showBikes;
  final bool showSetupTags;
  final bool showSetupBookmark;
  final bool showTaskPriority;
  final bool showTaskTags;
  final bool showMapVisibility;
  final bool showTimelineVisibility;

  const FilterSheetChip._({
    this.showBikes = false,
    this.showSetupTags = false,
    this.showSetupBookmark = false,
    this.showTaskPriority = false,
    this.showTaskTags = false,
    this.showMapVisibility = false,
    this.showTimelineVisibility = false,
  });

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final filters = appRepository.filters;
    final appSettings = context.watch<AppSettings>();
    final stravaActive = appSettings.enableStrava &&
        context.watch<SubscriptionService>().hasStravaEntitlement;

    final showSetupTags2 = showSetupTags && appSettings.enableSetupTags;
    final showSetupBookmark2 = showSetupBookmark && appSettings.enableSetupBookmark;
    final showTaskTags2 = showTaskTags && appSettings.enableTaskTags;
    final showTaskPriority2 = showTaskPriority && appSettings.enableTaskPriority;
    final showMapVisibility2 = showMapVisibility && (appSettings.enableRating || stravaActive);
    final showTimelineVisibility2 = showTimelineVisibility && (appSettings.enableRating || stravaActive || appSettings.enableInstallationTimeline || appSettings.enableTask);

    final showBikeOnly = showBikes && !showSetupTags2 && !showSetupBookmark2 && !showTaskPriority2 && !showTaskTags2 && !showMapVisibility2 && !showTimelineVisibility2;

    final bikeSelected = showBikes && filters.bikeId != null;
    final setupTagsSelected = showSetupTags2 && filters.setup.tags.isNotEmpty;
    final bookmarkSelected = showSetupBookmark2 && filters.setup.bookmarkedOnly;
    final taskPrioritySelected = showTaskPriority2 && filters.taskRule.hasActivePriorities;
    final taskTagsSelected = showTaskTags2 && filters.taskRule.tags.isNotEmpty;
    final mapVisibilitySelected = showMapVisibility2 &&
        (!appSettings.displayShowSetups ||
            (stravaActive && !appSettings.displayShowActivities) ||
            (appSettings.enableRating && !appSettings.displayShowRatingEntries));
    final timelineVisibilitySelected = showTimelineVisibility2 &&
        (!appSettings.displayShowSetups ||
            (stravaActive && !appSettings.displayShowActivities) ||
            (appSettings.enableTask && !appSettings.displayShowTasks) ||
            (appSettings.enableInstallationTimeline && !appSettings.displayShowInstallations) ||
            (appSettings.enableRating && !appSettings.displayShowRatingEntries));
    // The map shares its narrowed/reset logic with the map empty-state placeholder.
    final selected = showMapVisibility
        ? MapActions.isFiltered(appRepository: appRepository, appSettings: appSettings, stravaActive: stravaActive)
        : bikeSelected || setupTagsSelected || bookmarkSelected || taskPrioritySelected || taskTagsSelected || timelineVisibilitySelected;

    void resetDisplay() {
      if (showMapVisibility) {
        MapActions.clearFilters(context);
        return;
      }

      if (showBikes) filters.toggleBike(null);
      if (showSetupTags2) filters.setup = filters.setup.copyWith(tags: const {});
      if (showSetupBookmark2) filters.setup = filters.setup.copyWith(bookmarkedOnly: false);
      if (showTaskPriority2) filters.taskRule = filters.taskRule.copyWith(priorities: TaskPriority.values.toSet());
      if (showTaskTags2) filters.taskRule = filters.taskRule.copyWith(tags: const {});

      if (showTimelineVisibility2) {
        appSettings.displayShowSetups = true;
        appSettings.displayShowActivities = true;
        appSettings.displayShowRatingEntries = true;
        appSettings.displayShowTasks = true;
        appSettings.displayShowInstallations = true;
      }
    }

    final String bikeName = appRepository.bikes[filters.bikeId]?.name ?? '';

    final int setupTagCount = setupTagsSelected ? filters.setup.tags.length : 0;
    final int taskTagCount = taskTagsSelected ? filters.taskRule.tags.length : 0;
    final int tagCount = setupTagCount + taskTagCount;
    final String tagLabel = "$tagCount ${tagCount != 1 ? 'Tags' : 'Tag'}";

    final priorityCount = filters.taskRule.priorities.length;
    final priorityCountLabel = "$priorityCount ${priorityCount != 1 ? 'Priorities' : 'Priority'}";

    final extraCount = (mapVisibilitySelected ? 1 : 0) + (timelineVisibilitySelected ? 1 : 0);
    final extraCountLabel = "$extraCount ${extraCount != 1 ? 'Filters' : 'Filter'}";

    String labelText;
    if (selected) {
      final labels = [
        if (bikeSelected) bikeName,
        if (bookmarkSelected) "Bookmarked",
        if (tagCount > 0) tagLabel,
        if (taskPrioritySelected) priorityCountLabel,
        if (extraCount > 0) extraCountLabel,
      ];
      if (labels.isEmpty) {
        labelText = "Filter";
      } else {
        labelText = labels.join(" + ");
      }
    } else {
      labelText = showBikeOnly ? "All Bikes" : "Filter";
    }

    return FilterChip(
      avatar: showBikeOnly
          ? const Icon(Bike.iconData)
          : const Icon(Icons.filter_alt_outlined),
      label: Text(
        labelText,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      selected: selected,
      showCheckmark: false,
      onSelected: (bool newValue) async {
        await showFilterSheet(
          context: context,
          showBikes: showBikes,
          showSetupTags: showSetupTags2,
          showSetupBookmark: showSetupBookmark2,
          showTaskPriority: showTaskPriority2,
          showTaskTags: showTaskTags2,
          showMapVisibility: showMapVisibility2,
          showTimelineVisibility: showTimelineVisibility2,
        );
      },
      onDeleted: selected ? resetDisplay : null,
    );
  }
}
