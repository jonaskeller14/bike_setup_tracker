import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_settings.dart';
import '../../models/setup.dart';
import '../../models/strava/strava_activity.dart';
import '../../models/timeline_entry.dart';
import '../../models/timeline_row.dart';
import '../../pages/details/setup_details_page.dart';
import '../../repositories/app_repository.dart';
import '../items/installation_list_tile.dart';
import '../items/rating_entry_list_tile.dart';
import '../items/strava_list_tile.dart';
import '../items/task_entry_list_item.dart';
import '../sheets/installation_sheet.dart';
import '../sheets/replacement_sheet.dart';
import '../sheets/task_rule_sheet.dart';
import '../sticky_section.dart';
import '../timeline_day_header.dart';
import 'replacement_list_tile.dart';
import 'setup_group_section.dart';
import 'setup_tile.dart';
import 'strava_context_wrapper.dart';

class TimelineDaySection extends StatelessWidget{
  final DayHeaderRow header;
  final List<TimelineRow> rows;
  final Set<int> lazyLoadTriggerIds;
  final Iterable<Setup> setupsList;
  final AppSettings appSettings;
  final AppRepository appRepository;

  const TimelineDaySection({
    super.key,
    required this.header,
    required this.rows,
    required this.lazyLoadTriggerIds,
    required this.setupsList,
    required this.appSettings,
    required this.appRepository,
  });

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

  Widget _buildEntryTile(
    BuildContext context,
    TimelineEntry entry, {
    required AppSettings appSettings,
    required AppRepository appRepository,
    required Set<int> lazyLoadTriggerIds,
    required Iterable<Setup> setupsList,
    required double currentBarLeft,
    required EdgeInsets edgeInset,
  }) {
    switch (entry) {
      case StravaEntry():
        _maybeTriggerStravaLazyLoad(
          appRepository,
          lazyLoadTriggerIds,
          entry.activity,
        );
        return StravaListTile(stravaActivity: entry.activity, showDate: false);
      case SetupEntry():
        final setup = entry.setup;
        return SetupTile(
          setupId: setup.id,
          onTap: () => _openSetupDetails(context, setupsList, setup),
          showDate: false,
          currentBarLeft: currentBarLeft,
          edgeInset: edgeInset,
        );
      case TaskTimeLineEntry():
        return TaskEntryListItem(
          taskEntryId: entry.taskEntry.id,
          showDate: false,
          onTap: () => showTaskRuleSheet(
            context,
            taskRuleId: entry.taskEntry.taskRule,
            highlightTaskEntryId: entry.taskEntry.id,
          ),
        );
      case InstallationEntry():
        return InstallationListTile(
          componentInstallation: entry.componentInstallation,
          showDate: false,
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
          showDate: false,
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
    bool isFirstInSection = false,
    bool isLastInSection = false,
  }) {
    final edgeInset = EdgeInsets.only(
      top: isFirstInSection ? 8 : 0,
      bottom: isLastInSection ? 8 : 0,
    );

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
        currentBarLeft: hasStravaContext ? StravaContextWrapper.barWidth : 0,
        edgeInset: edgeInset,
      ),
      SetupGroupRow() => SetupGroupSection(
        setupIds: row.setups.map((e) => e.setup.id).toList(),
        onTapSetup: (setup) => _openSetupDetails(context, setupsList, setup),
      ),
      ReplacementRow() => ReplacementListTile(
        row: row,
        showDate: false,
        onTap: () async {
          await showReplacementSheet(
            context,
            removed: row.removed,
            installed: row.installed,
          );
        },
      ),
    };

    // A setup tile takes the inset itself so its current-setup highlight paints
    // over it; every other row takes it as plain outer padding.
    final bool isSetupEntry = row is SingleEntryRow && row.entry is SetupEntry;
    final bool isCurrentSeteup = isSetupEntry && (row.entry as SetupEntry).setup.isCurrent;

    // Every row is full-bleed and owns its own 16 px content inset; the Strava
    // bar is painted into that gutter rather than insetting the row further.
    final Widget wrapped = hasStravaContext
        ? StravaContextWrapper(
            stravaContext: row.stravaContext!,
            isFirstAndCurrentSetupInSection: isFirstInSection && isCurrentSeteup,
            isLastAndCurrentSetupInSection: isLastInSection && isCurrentSeteup,
            child: child,
          )
        : child;
    
    final absorbsEdgeInset = isSetupEntry;
    return absorbsEdgeInset ? wrapped : Padding(padding: edgeInset, child: wrapped);
  }

  @override
  Widget build(BuildContext context) {
    return StickySection(
      header: TimelineDayHeader(day: header.day, margin: EdgeInsets.zero),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            KeyedSubtree(
              key: rows[i].key,
              child: _buildRow(
                context,
                rows[i],
                appSettings: appSettings,
                appRepository: appRepository,
                lazyLoadTriggerIds: lazyLoadTriggerIds,
                setupsList: setupsList,
                isFirstInSection: i == 0,
                isLastInSection: i == rows.length - 1,
              ),
            ),
            if (i < rows.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}
