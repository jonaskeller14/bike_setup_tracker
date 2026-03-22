import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/setup.dart';
import '../models/strava/strava_activity.dart';
import '../models/todo_entry.dart';
import '../repositories/app_repository.dart';
import '../pages/setup_display_page.dart';
import 'chips/setup_list_filter_widget.dart';
import 'setup_list_card.dart';
import 'strava_list_tile.dart';
import 'todo_entry_list_item.dart';
import 'installation_list_tile.dart';

class SetupList extends StatelessWidget {
  const SetupList({super.key});

  Widget _emptyPlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SetupListFilterWidget(),
          Expanded(
            child: Center(
              child: Text(
                'No setups yet',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final sortAscending = appRepository.stravaSortAscending;
    final setupsList = appRepository.filteredSetups.values;
    final stravaActivities = appRepository.filteredStravaActivities.values;
    final todoEntries = appRepository.filteredTodoEntries.values;
    final installations = appRepository.filteredInstallations;

    // Horizon date is the "furthest" loaded activity date in the current scroll direction.
    // ASC: newest activity date. DESC: oldest activity date.
    final horizonDate = stravaActivities.isEmpty 
        ? null 
        : sortAscending
            ? stravaActivities.map((a) => a.startDate).reduce((a, b) => a.isAfter(b) ? a : b)
            : stravaActivities.map((a) => a.startDate).reduce((a, b) => a.isBefore(b) ? a : b);

    final List<_TimelineEntry> entries =  [
      if (appSettings.displayShowSetups) ...setupsList
          .where((s) {
            if (horizonDate == null || !appRepository.hasMoreStrava) return true;
            return sortAscending 
                ? !s.datetime.isAfter(horizonDate) // ASC: hide newer than horizon
                : !s.datetime.isBefore(horizonDate); // DESC: hide older than horizon
          })
          .map((s) => _SetupEntry(s)), 
      if (appSettings.displayShowActivities) ...stravaActivities.map((a) => _StravaEntry(a)),
      if (appSettings.displayShowTodos) ...todoEntries
          .where((t) {
            if (horizonDate == null || !appRepository.hasMoreStrava) return true;
            return sortAscending 
                ? !t.dateTimeUTC.isAfter(horizonDate) // ASC: hide newer than horizon
                : !t.dateTimeUTC.isBefore(horizonDate); // DESC: hide older than horizon
          })
          .map((t) => _TodoTimeLineEntry(t)),
      if (appSettings.displayShowInstallations) ...installations
          .where((ci) {
            if (horizonDate == null || !appRepository.hasMoreStrava) return true;
            return sortAscending 
                ? !ci.installation.dateTimeUTC.isAfter(horizonDate) // ASC: hide newer than horizon
                : !ci.installation.dateTimeUTC.isBefore(horizonDate); // DESC: hide older than horizon
          })
          .map((ci) => _InstallationEntry(ci)),
    ];
    entries.sort((a, b) => sortAscending 
        ? a.date.compareTo(b.date) 
        : b.date.compareTo(a.date));

    return setupsList.isEmpty && stravaActivities.isEmpty && todoEntries.isEmpty
        ? _emptyPlaceholder(context)
        : ListView.builder(
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16+100),
            itemCount: entries.length + 1 + (appRepository.isLoadingMoreStrava ? 1 : 0), // 1 header + optional loader
            itemBuilder: (context, index) {
              if (index == 0) {
                return SetupListFilterWidget();
              }

              if (index > entries.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              final entry = entries[index - 1];

              // Check for lazy loading trigger
              if (entry is _StravaEntry && appRepository.hasMoreStrava && !appRepository.isLoadingMoreStrava) {
                final activities = appRepository.filteredStravaActivities.values.toList();
                activities.sort((a, b) => sortAscending 
                    ? a.startDate.compareTo(b.startDate) 
                    : b.startDate.compareTo(a.startDate));
                
                if (activities.length >= 5) {
                   final tailActivities = activities.sublist(activities.length - 5);
                   if (tailActivities.contains(entry.activity)) {
                     WidgetsBinding.instance.addPostFrameCallback((_) {
                       appRepository.loadMoreStravaActivities();
                     });
                   }
                } else if (activities.isNotEmpty && activities.last == entry.activity) {
                   WidgetsBinding.instance.addPostFrameCallback((_) {
                     appRepository.loadMoreStravaActivities();
                   });
                }
              }

              switch (entry) {
                case _StravaEntry(): 
                  return StravaListTile(stravaActivity: entry.activity);
                case _SetupEntry():
                  final setup = entry.setup;
                  return SetupListCard(
                    setupId: setup.id,
                    onTap: () async {
                      Navigator.push<void>(context, MaterialPageRoute(builder: (context) => SetupDisplayPage(
                        setupIds: setupsList.map((s) => s.id).toList(),
                        initialSetup: setup,
                      )));
                    },
                    displayOnlyChanges: appSettings.setupListOnlyChanges,
                    displayBikeAdjustmentValues: appSettings.setupListBikeAdjustmentValues,
                    displayPersonAdjustmentValues: appSettings.setupListPersonAdjustmentValues,
                    displayRatingAdjustmentValues: appSettings.setupListRatingAdjustmentValues,
                  );
                case _TodoTimeLineEntry():
                  return TodoEntryListItem(
                    todoEntryId: entry.todoEntry.id,
                  );
                case _InstallationEntry():
                  return InstallationListTile(
                    componentInstallation: entry.componentInstallation,
                  );
              }
            },
          );
  }
}

sealed class _TimelineEntry {
  DateTime get date;
}

class _SetupEntry extends _TimelineEntry {
  final Setup setup;
  _SetupEntry(this.setup);
  @override
  DateTime get date => setup.datetime;
}

class _StravaEntry extends _TimelineEntry {
  final StravaActivity activity;
  _StravaEntry(this.activity);
  @override
  DateTime get date => activity.startDate;
}

class _TodoTimeLineEntry extends _TimelineEntry {
  final TodoEntry todoEntry;
  _TodoTimeLineEntry(this.todoEntry);
  @override
  DateTime get date => todoEntry.dateTimeUTC;
}

class _InstallationEntry extends _TimelineEntry {
  final ComponentInstallation componentInstallation;
  _InstallationEntry(this.componentInstallation);
  @override
  DateTime get date => componentInstallation.installation.dateTimeUTC;
}
