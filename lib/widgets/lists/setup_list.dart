import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/timeline_entry.dart';
import '../../pages/details/setup_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../utils/task_actions.dart';
import '../chips/setup_list_filter_widget.dart';
import '../items/installation_list_tile.dart';
import '../items/setup_list_card.dart';
import '../items/strava_list_tile.dart';
import '../items/task_entry_list_item.dart';
import '../sheets/installation_sheet.dart';

class SetupList extends StatelessWidget {
  const SetupList({super.key});

  Widget _emptyPlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SetupListFilterWidget(),
          Expanded(
            child: Center(
              child: Text(
                'No entries yet',
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
    final taskEntries = appRepository.filteredTaskEntries.values;
    final installations = appRepository.filteredInstallations;

    // Horizon date is the "furthest" loaded activity date in the current scroll direction.
    // ASC: newest activity date. DESC: oldest activity date.
    final horizonDate = stravaActivities.isEmpty 
        ? null 
        : sortAscending
            ? stravaActivities.map((a) => a.startDate).reduce((a, b) => a.isAfter(b) ? a : b)
            : stravaActivities.map((a) => a.startDate).reduce((a, b) => a.isBefore(b) ? a : b);

    final List<TimelineEntry> entries =  [
      if (appSettings.displayShowSetups) ...setupsList
          .where((s) {
            if (horizonDate == null || !appRepository.hasMoreStrava) return true;
            return sortAscending 
                ? !s.datetime.isAfter(horizonDate) // ASC: hide newer than horizon
                : !s.datetime.isBefore(horizonDate); // DESC: hide older than horizon
          })
          .map((s) => SetupEntry(s)), 
      if (appSettings.displayShowActivities) ...stravaActivities.map((a) => StravaEntry(a)),
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
    ];
    entries.sort((a, b) => sortAscending 
        ? a.date.compareTo(b.date) 
        : b.date.compareTo(a.date));

    return entries.isEmpty && !appRepository.isLoadingMoreStrava
        ? _emptyPlaceholder(context)
        : ListView.builder(
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16+100),
            itemCount: entries.length + 1 + (appRepository.isLoadingMoreStrava ? 1 : 0), // 1 header + optional loader
            itemBuilder: (context, index) {
              if (index == 0) {
                return const SetupListFilterWidget();
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
              if (entry is StravaEntry && appRepository.hasMoreStrava && !appRepository.isLoadingMoreStrava) {
                final activities = appRepository.filteredStravaActivities.values.toList();
                activities.sort((a, b) => sortAscending 
                    ? a.startDate.compareTo(b.startDate) 
                    : b.startDate.compareTo(a.startDate));
                
                if (activities.length >= 5) {
                   final tailActivities = activities.sublist(activities.length - 5);
                   if (tailActivities.contains(entry.activity)) {
                     WidgetsBinding.instance.addPostFrameCallback((_) async {
                       appRepository.loadMoreStravaActivities();
                     });
                   }
                } else if (activities.isNotEmpty && activities.last == entry.activity) {
                   WidgetsBinding.instance.addPostFrameCallback((_) async {
                     appRepository.loadMoreStravaActivities();
                   });
                }
              }

              switch (entry) {
                case StravaEntry(): 
                  return StravaListTile(stravaActivity: entry.activity);
                case SetupEntry():
                  final setup = entry.setup;
                  return SetupListCard(
                    setupId: setup.id,
                    onTap: () async {
                      Navigator.push<void>(context, MaterialPageRoute(builder: (context) => SetupDetailsPage(
                        setupIds: setupsList.map((s) => s.id).toList(),
                        initialSetup: setup,
                      )));
                    },
                    displayOnlyChanges: appSettings.setupListOnlyChanges,
                    displayBikeAdjustmentValues: appSettings.setupListBikeAdjustmentValues,
                    displayPersonAdjustmentValues: appSettings.setupListPersonAdjustmentValues,
                    displayRatingAdjustmentValues: appSettings.setupListRatingAdjustmentValues,
                  );
                case TaskTimeLineEntry():
                  return TaskEntryListItem(
                    taskEntryId: entry.taskEntry.id,
                    onTap: () => TaskActions.showTaskRuleDetails(
                      context, 
                      taskRuleId: entry.taskEntry.taskRule, 
                      highlightTaskEntryId: entry.taskEntry.id,
                    ),
                  );
                case InstallationEntry():
                  return InstallationListTile(
                    componentInstallation: entry.componentInstallation,
                    onTap: () async {
                      await showEditInstallationSheet(
                        context,
                        component: entry.componentInstallation.component,
                        editEntry: entry.componentInstallation,
                      );
                    },
                  );
              }
            },
          );
  }
}
