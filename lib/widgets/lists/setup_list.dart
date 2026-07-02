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
import '../chips/setup_list_filter_widget.dart';
import '../empty_state_placeholder.dart';
import '../hints/setup_calendar_hint.dart';
import '../hints/setup_hint_selection.dart';
import '../hints/setup_task_hint.dart';
import '../items/installation_list_tile.dart';
import '../items/rating_entry_list_tile.dart';
import '../items/setup_list_card.dart';
import '../items/strava_list_tile.dart';
import '../items/task_entry_list_item.dart';
import '../sheets/installation_sheet.dart';
import '../sheets/task_rule_sheet.dart';

class SetupList extends StatelessWidget {
  const SetupList({super.key});

  Widget _emptyPlaceholder(BuildContext context) {
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
        : b.date.compareTo(a.date));

    final Widget? hint = switch (selectSetupHint(
      settings: appSettings,
      setupCount: setupsList.length,
      stravaActivityCount: stravaActivities.length,
    )) {
      SetupHint.task => const SetupTaskHint(),
      SetupHint.calendar => const SetupCalendarHint(),
      SetupHint.none => null,
    };

    return entries.isEmpty && !appRepository.isLoadingMoreStrava
        ? _emptyPlaceholder(context)
        : ListView.builder(
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16+100),
            itemCount: entries.length + 1 + (appRepository.isLoadingMoreStrava ? 1 : 0), // 1 header + optional loader
            itemBuilder: (context, index) {
              if (index == 0) {
                if (hint == null) return const SetupListFilterWidget();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    hint,
                    const SetupListFilterWidget(),
                  ],
                );
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
                    displayBikeAdjustmentValues: appSettings.setupListBikeAdjustmentValues,
                    displayPersonAdjustmentValues: appSettings.setupListPersonAdjustmentValues,
                  );
                case TaskTimeLineEntry():
                  return TaskEntryListItem(
                    taskEntryId: entry.taskEntry.id,
                    onTap: () => showTaskRuleSheet(
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
                case RatingEntryTimelineEntry():
                  return RatingEntryListTile(ratingEntry: entry.ratingEntry);
              }
            },
          );
  }
}
