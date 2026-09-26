
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_hint.dart';
import '../../models/app_settings.dart';
import '../../models/setup.dart';
import '../../models/strava/strava_activity.dart';
import '../../models/timeline_entry.dart';
import '../../models/timeline_row.dart';
import '../../models/timeline_selection.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../utils/setup_actions.dart';
import '../../utils/timeline_grouping.dart';
import '../chips/setup_list_filter_widget.dart';
import '../empty_state_placeholder.dart';
import '../hints/app_hint_slot.dart';
import '../items/timeline_day_section.dart';
import 'list_scroll_controller.dart';

class SetupList extends StatelessWidget {
  final ListScrollController? controller;
  final Set<TimelineSelectionId> selection;
  final ValueChanged<Iterable<TimelineSelectionId>>? onSelectionChanged;

  const SetupList({
    super.key,
    this.controller,
    this.selection = const {},
    this.onSelectionChanged,
  });

  bool _hasActiveFilters(AppRepository appRepository, AppSettings appSettings) {
    return appRepository.selectedBike != null ||
        appRepository.selectedSetupTags.isNotEmpty ||
        appRepository.showBookmarkedSetupsOnly ||
        !appSettings.displayShowSetups ||
        !appSettings.displayShowActivities ||
        !appSettings.displayShowTasks ||
        !appSettings.displayShowInstallations ||
        !appSettings.displayShowRatingEntries;
  }

  bool _hasAnyContent(AppRepository appRepository) {
    return appRepository.setups.isNotEmpty ||
        appRepository.taskEntries.isNotEmpty ||
        appRepository.ratingEntries.isNotEmpty ||
        appRepository.components.values.any((c) => c.installations.isNotEmpty);
  }

  void _clearFilters(AppRepository appRepository, AppSettings appSettings) {
    appRepository.onBikeTap(null);
    appRepository.deselectAllSetupTags();
    appRepository.setShowBookmarkedSetupsOnly(false);
    appSettings.displayShowSetups = true;
    appSettings.displayShowActivities = true;
    appSettings.displayShowTasks = true;
    appSettings.displayShowInstallations = true;
    appSettings.displayShowRatingEntries = true;
  }

  Widget _emptyPlaceholder(BuildContext context, AppRepository appRepository, AppSettings appSettings) {
    final filtered = _hasActiveFilters(appRepository, appSettings) && _hasAnyContent(appRepository);
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: AppHintSlot(
            placement: AppHintPlacement.setupHeader,
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          ),
        ),
        const SliverToBoxAdapter(child: SetupListFilterWidget()),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: filtered
                ? EmptyStatePlaceholder(
                    icon: Icons.filter_alt_off,
                    title: 'Nothing matches this filter',
                    subtitle: 'Your filters are hiding all entries.',
                    actionLabel: 'Clear filters',
                    actionIcon: Icons.filter_alt_off,
                    onAction: () => _clearFilters(appRepository, appSettings),
                  )
                : EmptyStatePlaceholder(
                    icon: Setup.iconData,
                    title: 'No entries yet',
                    subtitle: 'Record your first setup to start tracking your adjustments.',
                    actionLabel: 'Record a setup',
                    onAction: () => SetupActions.addSetup(context),
                  ),
          ),
        ),
      ],
    );
  }

  /// The activities whose tiles trigger loading the next Strava page: the
  /// (up to) five at the tail of the loaded window in display order. Computed
  /// once per build so the per-tile check is a set lookup instead of a sort of
  /// the whole window.
  Set<int> _lazyLoadTriggerIds(
    AppRepository appRepository,
    Iterable<StravaActivity> activities,
    bool sortAscending,
  ) {
    if (!appRepository.hasMoreStrava) return const {};
    final sorted = activities.toList()
      ..sort(
        (a, b) => sortAscending ? a.startDate.compareTo(b.startDate) : b.startDate.compareTo(a.startDate),
      );
    final tailStart = sorted.length > 5 ? sorted.length - 5 : 0;
    return {for (final a in sorted.sublist(tailStart)) a.id};
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();
    final sortAscending = appRepository.stravaSortAscending;
    final setupsList = appRepository.filteredSetups.values;
    final bool showingStrava =
        appSettings.displayShowActivities && appSettings.enableStrava && subscriptionService.hasStravaEntitlement;
    final stravaActivities = showingStrava ? appRepository.filteredStravaActivities.values : const <StravaActivity>[];
    final lazyLoadTriggerIds = _lazyLoadTriggerIds(
      appRepository,
      stravaActivities,
      sortAscending,
    );
    final taskEntries = appRepository.filteredTaskEntries.values;
    final installations = appRepository.filteredInstallations;

    // Horizon date is the "furthest" loaded activity date in the current scroll direction.
    // ASC: newest activity date. DESC: oldest activity date.
    final horizonDate = stravaActivities.isEmpty
        ? null
        : sortAscending
        ? stravaActivities.map((a) => a.startDate).reduce((a, b) => a.isAfter(b) ? a : b)
        : stravaActivities.map((a) => a.startDate).reduce((a, b) => a.isBefore(b) ? a : b);

    final List<TimelineEntry> entries = [
      if (appSettings.displayShowSetups)
        ...setupsList
            .where((s) {
              if (horizonDate == null || !appRepository.hasMoreStrava) return true;
              return sortAscending
                  ? !s.datetime.isAfter(horizonDate) // ASC: hide newer than horizon
                  : !s.datetime.isBefore(horizonDate); // DESC: hide older than horizon
            })
            .map((s) => SetupEntry(s)),
      if (showingStrava) ...stravaActivities.map((a) => StravaEntry(a)),
      if (appSettings.displayShowTasks)
        ...taskEntries
            .where((t) {
              if (horizonDate == null || !appRepository.hasMoreStrava) return true;
              return sortAscending
                  ? !t.dateTimeUTC.isAfter(horizonDate) // ASC: hide newer than horizon
                  : !t.dateTimeUTC.isBefore(horizonDate); // DESC: hide older than horizon
            })
            .map((t) => TaskTimeLineEntry(t)),
      if (appSettings.displayShowInstallations)
        ...installations
            .where((ci) {
              if (horizonDate == null || !appRepository.hasMoreStrava) return true;
              return sortAscending
                  ? !ci.installation.dateTimeUTC.isAfter(horizonDate) // ASC: hide newer than horizon
                  : !ci.installation.dateTimeUTC.isBefore(horizonDate); // DESC: hide older than horizon
            })
            .map((ci) => InstallationEntry(ci)),
      if (appSettings.enableRating && appSettings.displayShowRatingEntries)
        ...appRepository.filteredRatingEntries.values
            .where((re) {
              if (horizonDate == null || !appRepository.hasMoreStrava) return true;
              return sortAscending
                  ? !re.dateTimeUTC.isAfter(horizonDate) // ASC: hide newer than horizon
                  : !re.dateTimeUTC.isBefore(horizonDate); // DESC: hide older than horizon
            })
            .map((re) => RatingEntryTimelineEntry(re)),
    ];
    entries.sort(
      (a, b) => sortAscending ? a.dateUTC.compareTo(b.dateUTC) : b.dateUTC.compareTo(a.dateUTC),
    );

    final rows = buildTimelineRows(
      entries,
      sortAscending: sortAscending,
      appSettings: appSettings,
    );

    if (entries.isEmpty && !appRepository.isLoadingMoreStrava) {
      return _emptyPlaceholder(context, appRepository, appSettings);
    }

    final sections = <({DayHeaderRow header, List<TimelineRow> rows})>[];
    for (final row in rows) {
      if (row is DayHeaderRow) {
        sections.add((header: row, rows: []));
      } else if (sections.isNotEmpty) {
        sections.last.rows.add(row);
      }
    }

    return CustomScrollView(
      controller: controller?.scrollController,
      slivers: [
        const SliverToBoxAdapter(
          child: AppHintSlot(
            placement: AppHintPlacement.setupHeader,
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          ),
        ),
        const SliverToBoxAdapter(child: SetupListFilterWidget()),
        SliverList.builder(
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            return KeyedSubtree(
              key: section.header.key,
              child: TimelineDaySection(
                header: section.header,
                rows: section.rows,
                appSettings: appSettings,
                appRepository: appRepository,
                lazyLoadTriggerIds: lazyLoadTriggerIds,
                setupsList: setupsList,
                selection: selection,
                onSelectionChanged: onSelectionChanged,
              ),
            );
          },
        ),
        if (appRepository.isLoadingMoreStrava)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16 + 100)),
      ],
    );
  }
}
