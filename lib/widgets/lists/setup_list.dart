import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/setup.dart';
import '../../models/strava/strava_activity.dart';
import '../../models/timeline_entry.dart';
import '../../pages/details/setup_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../utils/setup_actions.dart';
import '../../utils/timeline_grouping.dart';
import '../chips/setup_list_filter_widget.dart';
import '../empty_state_placeholder.dart';
import '../hints/getting_started_guide_hint.dart';
import '../hints/setup_calendar_hint.dart';
import '../hints/setup_hint_selection.dart';
import '../hints/setup_task_hint.dart';
import '../items/installation_list_tile.dart';
import '../items/rating_entry_list_tile.dart';
import '../items/replacement_list_tile.dart';
import '../items/setup_group_section.dart';
import '../items/setup_list_tile.dart';
import '../items/strava_context_wrapper.dart';
import '../items/strava_list_tile.dart';
import '../items/task_entry_list_item.dart';
import '../sheets/installation_sheet.dart';
import '../sheets/replacement_sheet.dart';
import '../sheets/task_rule_sheet.dart';
import '../sticky_section.dart';
import '../timeline_day_header.dart';

class SetupList extends StatelessWidget {
  const SetupList({super.key});

  Widget _emptyPlaceholder(BuildContext context, {required bool showStartupGuide}) {
    if (showStartupGuide) {
      return const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            SetupListFilterWidget(),
            GettingStartedGuideHint(),
          ],
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(child: SetupListFilterWidget()),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: EmptyStatePlaceholder(
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
        (a, b) => sortAscending
            ? a.startDate.compareTo(b.startDate)
            : b.startDate.compareTo(a.startDate),
      );
    final tailStart = sorted.length > 5 ? sorted.length - 5 : 0;
    return {for (final a in sorted.sublist(tailStart)) a.id};
  }

  void _maybeTriggerStravaLazyLoad(
    AppRepository appRepository,
    Set<int> lazyLoadTriggerIds,
    StravaActivity activity,
  ) {
    if (!appRepository.hasMoreStrava || appRepository.isLoadingMoreStrava) return;
    if (!lazyLoadTriggerIds.contains(activity.id)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(appRepository.loadMoreStravaActivities());
    });
  }

  void _openSetupDetails(
    BuildContext context,
    Iterable<Setup> setupsList,
    Setup setup,
  ) {
    unawaited(
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (context) => SetupDetailsPage(
            setupIds: setupsList.map((s) => s.id).toList(),
            initialSetup: setup,
          ),
        ),
      ),
    );
  }

  Widget _buildEntryTile(
    BuildContext context,
    TimelineEntry entry, {
    required AppSettings appSettings,
    required AppRepository appRepository,
    required Set<int> lazyLoadTriggerIds,
    required Iterable<Setup> setupsList,
    required double currentBarLeft,
  }) {
    final showDate = !appSettings.enableTimelineDayHeaders;

    switch (entry) {
      case StravaEntry():
        _maybeTriggerStravaLazyLoad(
          appRepository,
          lazyLoadTriggerIds,
          entry.activity,
        );
        return StravaListTile(stravaActivity: entry.activity, showDate: showDate);
      case SetupEntry():
        final setup = entry.setup;
        return SetupListTile(
          setupId: setup.id,
          onTap: () => _openSetupDetails(context, setupsList, setup),
          displayBikeAdjustmentValues: appSettings.setupListBikeAdjustmentValues,
          displayPersonAdjustmentValues: appSettings.setupListPersonAdjustmentValues,
          showDate: showDate,
          currentBarLeft: currentBarLeft,
        );
      case TaskTimeLineEntry():
        return TaskEntryListItem(
          taskEntryId: entry.taskEntry.id,
          showDate: showDate,
          onTap: () => showTaskRuleSheet(
            context,
            taskRuleId: entry.taskEntry.taskRule,
            highlightTaskEntryId: entry.taskEntry.id,
          ),
        );
      case InstallationEntry():
        return InstallationListTile(
          componentInstallation: entry.componentInstallation,
          showDate: showDate,
          onTap: () async {
            await showEditInstallationSheet(
              context,
              component: entry.componentInstallation.component,
              editEntry: entry.componentInstallation,
            );
          },
        );
      case RatingEntryTimelineEntry():
        return RatingEntryListTile(
          ratingEntry: entry.ratingEntry,
          showDate: showDate,
        );
    }
  }

  Widget _buildRow(
    BuildContext context,
    TimelineRow row, {
    required AppSettings appSettings,
    required AppRepository appRepository,
    required Set<int> lazyLoadTriggerIds,
    required Iterable<Setup> setupsList,
  }) {
    // A row inside a ride block already spends the left gutter on the Strava
    // bar, so the current-setup bar moves aside to sit next to it.
    final bool hasStravaContext = row is EntryRow && row.stravaContext != null;

    final Widget child = switch (row) {
      DayHeaderRow() => TimelineDayHeader(day: row.day),
      SingleEntryRow() => _buildEntryTile(
        context,
        row.entry,
        appSettings: appSettings,
        appRepository: appRepository,
        lazyLoadTriggerIds: lazyLoadTriggerIds,
        setupsList: setupsList,
        currentBarLeft: hasStravaContext ? 6 : 0,
      ),
      SetupGroupRow() => SetupGroupSection(
        setupIds: row.setups.map((e) => e.setup.id).toList(),
        onTapSetup: (setup) => _openSetupDetails(context, setupsList, setup),
        displayBikeAdjustmentValues: appSettings.setupListBikeAdjustmentValues,
        displayPersonAdjustmentValues:
            appSettings.setupListPersonAdjustmentValues,
      ),
      ReplacementRow() => ReplacementListTile(
        row: row,
        showDate: !appSettings.enableTimelineDayHeaders,
        onTap: () async {
          await showReplacementSheet(
            context,
            removed: row.removed,
            installed: row.installed,
          );
        },
      ),
    };

    // Every row is full-bleed and owns its own 16 px content inset; the Strava
    // bar is painted into that gutter rather than insetting the row further.
    if (row is EntryRow && row.stravaContext != null) {
      return StravaContextWrapper(stravaContext: row.stravaContext!, child: child);
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final subscriptionService = context.watch<SubscriptionService>();
    final sortAscending = appRepository.stravaSortAscending;
    final setupsList = appRepository.filteredSetups.values;
    final bool showingStrava = appSettings.displayShowActivities &&
        appSettings.enableStrava &&
        subscriptionService.hasStravaEntitlement;
    final stravaActivities = showingStrava
        ? appRepository.filteredStravaActivities.values
        : const <StravaActivity>[];
    final lazyLoadTriggerIds = _lazyLoadTriggerIds(
      appRepository,
      stravaActivities,
      sortAscending,
    );
    final taskEntries = appRepository.filteredTaskEntries.values;
    final installations = appRepository.filteredInstallations;

    // Onboarding guide: shown until all three getting-started steps are done
    // (mirrors the self-guard inside GettingStartedGuideHint).
    final showStartupGuide = appSettings.showGettingStartedGuideHint &&
        !(appRepository.bikes.isNotEmpty &&
            appRepository.components.isNotEmpty &&
            appRepository.setups.isNotEmpty);

    // Horizon date is the "furthest" loaded activity date in the current scroll direction.
    // ASC: newest activity date. DESC: oldest activity date.
    final horizonDate = stravaActivities.isEmpty
        ? null
        : sortAscending
        ? stravaActivities
              .map((a) => a.startDate)
              .reduce((a, b) => a.isAfter(b) ? a : b)
        : stravaActivities
              .map((a) => a.startDate)
              .reduce((a, b) => a.isBefore(b) ? a : b);

    final List<TimelineEntry> entries = [
      if (appSettings.displayShowSetups) ...setupsList
            .where((s) {
              if (horizonDate == null || !appRepository.hasMoreStrava) return true;
              return sortAscending
                  ? !s.datetime.isAfter(horizonDate) // ASC: hide newer than horizon
                  : !s.datetime.isBefore(horizonDate); // DESC: hide older than horizon
            })
            .map((s) => SetupEntry(s)),
      if (showingStrava) ...stravaActivities.map((a) => StravaEntry(a)),
      if (appSettings.displayShowTasks) ...taskEntries
            .where((t) {
              if (horizonDate == null || !appRepository.hasMoreStrava) return true;
              return sortAscending
                  ? !t.dateTimeUTC.isAfter(horizonDate) // ASC: hide newer than horizon
                  : !t.dateTimeUTC.isBefore(horizonDate); // DESC: hide older than horizon
            })
            .map((t) => TaskTimeLineEntry(t)),
      if (appSettings.displayShowInstallations) ...installations
            .where((ci) {
              if (horizonDate == null || !appRepository.hasMoreStrava) return true;
              return sortAscending
                  ? !ci.installation.dateTimeUTC.isAfter(horizonDate) // ASC: hide newer than horizon
                  : !ci.installation.dateTimeUTC.isBefore(horizonDate); // DESC: hide older than horizon
            })
            .map((ci) => InstallationEntry(ci)),
      if (appSettings.enableRating && appSettings.displayShowRatingEntries) ...appRepository.filteredRatingEntries.values
            .where((re) {
              if (horizonDate == null || !appRepository.hasMoreStrava) return true;
              return sortAscending
                  ? !re.dateTimeUTC.isAfter(horizonDate) // ASC: hide newer than horizon
                  : !re.dateTimeUTC.isBefore(horizonDate); // DESC: hide older than horizon
            })
            .map((re) => RatingEntryTimelineEntry(re)),
    ];
    entries.sort((a, b) => sortAscending
        ? a.date.compareTo(b.date)
        : b.date.compareTo(a.date),
    );

    final rows = buildTimelineRows(
      entries,
      sortAscending: sortAscending,
      appSettings: appSettings,
    );

    // Only one hint at a time at the top: the onboarding guide takes priority over
    // the task/calendar suggestion hints.
    final Widget? hint = showStartupGuide
        ? null
        : switch (selectSetupHint(
            settings: appSettings,
            setupCount: setupsList.length,
            stravaActivityCount: stravaActivities.length,
          )) {
            SetupHint.task => const SetupTaskHint(),
            SetupHint.calendar => const SetupCalendarHint(),
            SetupHint.none => null,
          };

    if (entries.isEmpty && !appRepository.isLoadingMoreStrava) {
      return _emptyPlaceholder(context, showStartupGuide: showStartupGuide);
    }

    final headerChildren = <Widget>[
      if (showStartupGuide) const GettingStartedGuideHint(),
      ?hint,
      const SetupListFilterWidget(),
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: headerChildren.length == 1
                ? headerChildren.first
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: headerChildren,
                  ),
          ),
        ),
        ..._buildRowSlivers(
          context,
          rows,
          appSettings: appSettings,
          appRepository: appRepository,
          lazyLoadTriggerIds: lazyLoadTriggerIds,
          setupsList: setupsList,
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

  List<Widget> _buildRowSlivers(
    BuildContext context,
    List<TimelineRow> rows, {
    required AppSettings appSettings,
    required AppRepository appRepository,
    required Set<int> lazyLoadTriggerIds,
    required Iterable<Setup> setupsList,
  }) {
    if (!appSettings.enableTimelineDayHeaders) {
      return [
        _daySliverList(
          context,
          rows,
          appSettings: appSettings,
          appRepository: appRepository,
          lazyLoadTriggerIds: lazyLoadTriggerIds,
          setupsList: setupsList,
        ),
      ];
    }

    // One box child per day so a single SliverList can build sections lazily
    // (a sliver group per day is inflated eagerly and made deep windows take
    // seconds to build). The pinning happens inside each section, see
    // StickySection.
    final sections = <({DayHeaderRow header, List<TimelineRow> rows})>[];
    for (final row in rows) {
      if (row is DayHeaderRow) {
        sections.add((header: row, rows: []));
      } else if (sections.isNotEmpty) {
        sections.last.rows.add(row);
      }
    }

    return [
      SliverList.builder(
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return KeyedSubtree(
            key: section.header.key,
            child: _daySection(
              context,
              section.header,
              section.rows,
              appSettings: appSettings,
              appRepository: appRepository,
              lazyLoadTriggerIds: lazyLoadTriggerIds,
              setupsList: setupsList,
            ),
          );
        },
      ),
    ];
  }

  Widget _daySection(
    BuildContext context,
    DayHeaderRow header,
    List<TimelineRow> group, {
    required AppSettings appSettings,
    required AppRepository appRepository,
    required Set<int> lazyLoadTriggerIds,
    required Iterable<Setup> setupsList,
  }) {
    final children = <Widget>[];
    for (var i = 0; i < group.length; i++) {
      children.add(
        KeyedSubtree(
          key: group[i].key,
          child: _buildRow(
            context,
            group[i],
            appSettings: appSettings,
            appRepository: appRepository,
            lazyLoadTriggerIds: lazyLoadTriggerIds,
            setupsList: setupsList,
          ),
        ),
      );
      if (i + 1 < group.length) children.add(const Divider(height: 1));
    }
    return StickySection(
      // Flush under the appbar (no margin) and opaque, so scrolled rows don't
      // bleed through while it's pinned.
      header: TimelineDayHeader(day: header.day, margin: EdgeInsets.zero),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _daySliverList(
    BuildContext context,
    List<TimelineRow> group, {
    required AppSettings appSettings,
    required AppRepository appRepository,
    required Set<int> lazyLoadTriggerIds,
    required Iterable<Setup> setupsList,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      sliver: SliverList.separated(
        itemCount: group.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final row = group[index];
          // Key each row to its stable entry identity so element state (card
          // expansion, Strava context wrapper) tracks the logical entry across
          // the reordering an edit can cause.
          return KeyedSubtree(
            key: row.key,
            child: _buildRow(
              context,
              row,
              appSettings: appSettings,
              appRepository: appRepository,
              lazyLoadTriggerIds: lazyLoadTriggerIds,
              setupsList: setupsList,
            ),
          );
        },
      ),
    );
  }
}
