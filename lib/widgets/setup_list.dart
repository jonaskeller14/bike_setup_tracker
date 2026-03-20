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
import 'todo_entry_list_card.dart';

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
    final setupsList = appRepository.filteredSetups.values;
    final stravaActivities = appRepository.filteredStravaActivities.values;
    final todoEntries = appRepository.filteredTodoEntries.values;

    final oldestActivityDate = stravaActivities.isEmpty 
        ? null 
        : stravaActivities.map((a) => a.startDate).reduce((a, b) => a.isBefore(b) ? a : b);

    final List<_TimelineEntry> entries =  [
      ...setupsList
          .where((s) => oldestActivityDate == null || !appRepository.hasMoreStrava || !s.datetime.isBefore(oldestActivityDate))
          .map((s) => _SetupEntry(s)), 
      ...stravaActivities.map((a) => _StravaEntry(a)),
      ...todoEntries
          .where((t) => oldestActivityDate == null || !appRepository.hasMoreStrava || !t.dateTimeUTC.isBefore(oldestActivityDate))
          .map((t) => _TodoTimeLineEntry(t)),
    ];
    entries.sort((a, b) => appSettings.setupListSortAscending 
        ? a.date.compareTo(b.date) 
        : b.date.compareTo(a.date));

    return setupsList.isEmpty
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
                  final todoEntry = entry.todoEntry;
                  return TodoEntryListCard(
                    todoEntryId: todoEntry.id,
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
  @override DateTime get date => setup.datetime;
}

class _StravaEntry extends _TimelineEntry {
  final StravaActivity activity;
  _StravaEntry(this.activity);
  @override DateTime get date => activity.startDate;
}

class _TodoTimeLineEntry extends _TimelineEntry {
  final TodoEntry todoEntry;
  _TodoTimeLineEntry(this.todoEntry);
  @override DateTime get date => todoEntry.dateTimeUTC;
}
