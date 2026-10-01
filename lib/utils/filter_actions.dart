import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/filters/layer_filter.dart';
import '../models/filters/setup_filter.dart';
import '../models/task/task_rule.dart';
import '../repositories/app_repository.dart';
import '../widgets/sheets/filter.dart';

/// The one place that decides which filter sections a page offers, whether they
/// narrow anything, how that is labelled and how it is reset. The filter chip,
/// the filter sheet and the "Clear filters" empty states all go through here.
class FilterActions {
  /// The [sections] whose feature is on, so the sheet has something to offer.
  static Set<FilterSection> enabledSections(
    Set<FilterSection> sections, {
    required AppSettings appSettings,
    required bool stravaActive,
  }) {
    bool enabled(FilterSection section) => switch (section) {
      FilterSection.bike => true,
      FilterSection.setups => appSettings.enableSetupTags || appSettings.enableSetupBookmark,
      FilterSection.taskPriority => appSettings.enableTaskPriority,
      FilterSection.taskTags => appSettings.enableTaskTags,
      // Layer toggles are only offered when a layer other than setups can be shown at all.
      FilterSection.mapLayers => appSettings.enableRating || stravaActive,
      FilterSection.timelineLayers =>
        appSettings.enableRating || stravaActive || appSettings.enableInstallationTimeline || appSettings.enableTask,
    };

    return sections.where(enabled).toSet();
  }

  /// The layers the enabled layer sections of [sections] let the user toggle, in
  /// display order. A layer whose feature is off is not among them.
  static Set<TimelineLayer> availableLayers(
    Set<FilterSection> sections, {
    required AppSettings appSettings,
    required bool stravaActive,
  }) {
    bool featureOn(TimelineLayer layer) => switch (layer) {
      TimelineLayer.setups => true,
      TimelineLayer.activities => stravaActive,
      TimelineLayer.tasks => appSettings.enableTask,
      TimelineLayer.installations => appSettings.enableInstallationTimeline,
      TimelineLayer.ratingEntries => appSettings.enableRating,
    };

    final enabled = enabledSections(sections, appSettings: appSettings, stravaActive: stravaActive);
    return _layersOf(enabled).where(featureOn).toSet();
  }

  /// Whether a criterion of the [sections] currently narrows what is shown.
  static bool isFiltered(
    Set<FilterSection> sections, {
    required AppRepository appRepository,
    required AppSettings appSettings,
    required bool stravaActive,
  }) => activeLabels(
    sections,
    appRepository: appRepository,
    appSettings: appSettings,
    stravaActive: stravaActive,
  ).isNotEmpty;

  /// One label per active criterion of the [sections], in chip order. A
  /// criterion whose feature is off is not offered, so it does not count.
  static List<String> activeLabels(
    Set<FilterSection> sections, {
    required AppRepository appRepository,
    required AppSettings appSettings,
    required bool stravaActive,
  }) {
    final filters = appRepository.filters;
    final enabled = enabledSections(sections, appSettings: appSettings, stravaActive: stravaActive);
    final setups = enabled.contains(FilterSection.setups);

    final setupTagCount = setups && appSettings.enableSetupTags ? filters.setup.tags.length : 0;
    final taskTagCount = enabled.contains(FilterSection.taskTags) ? filters.taskRule.tags.length : 0;
    final tagCount = setupTagCount + taskTagCount;
    final priorityCount = filters.taskRule.priorities.length;
    final layers = availableLayers(sections, appSettings: appSettings, stravaActive: stravaActive);

    return [
      if (enabled.contains(FilterSection.bike) && filters.bikeId != null)
        appRepository.bikes[filters.bikeId]?.name ?? '',
      if (setups && appSettings.enableSetupBookmark && filters.setup.bookmarkedOnly) "Bookmarked",
      if (tagCount > 0) "$tagCount ${tagCount != 1 ? 'Tags' : 'Tag'}",
      if (enabled.contains(FilterSection.taskPriority) && filters.taskRule.hasActivePriorities)
        "$priorityCount ${priorityCount != 1 ? 'Priorities' : 'Priority'}",
      if (filters.layers.isActiveFor(layers)) "1 Filter",
    ];
  }

  /// Resets every criterion the [sections] own, whether or not its feature is
  /// on. A layer that only another section offers keeps its state.
  static void clear(BuildContext context, Set<FilterSection> sections) {
    final filters = context.read<AppRepository>().filters;

    if (sections.contains(FilterSection.bike)) filters.toggleBike(null);
    if (sections.contains(FilterSection.setups)) filters.setup = const SetupFilter();
    filters.taskRule = filters.taskRule.copyWith(
      priorities: sections.contains(FilterSection.taskPriority) ? TaskPriority.values.toSet() : null,
      tags: sections.contains(FilterSection.taskTags) ? const {} : null,
    );
    filters.layers = filters.layers.copyWith(hidden: filters.layers.hidden.difference(_layersOf(sections)));
  }

  static const _mapLayers = {TimelineLayer.setups, TimelineLayer.activities, TimelineLayer.ratingEntries};

  /// Every layer the layer sections of [sections] cover, whatever the feature flags say.
  static Set<TimelineLayer> _layersOf(Set<FilterSection> sections) => {
    if (sections.contains(FilterSection.timelineLayers)) ...TimelineLayer.values,
    if (sections.contains(FilterSection.mapLayers)) ..._mapLayers,
  };
}
