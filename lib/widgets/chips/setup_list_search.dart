import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/timeline_entry.dart';
import '../../pages/details/setup_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../utils/task_actions.dart';
import '../items/installation_list_tile.dart';
import '../items/setup_list_card.dart';
import '../items/strava_list_tile.dart';
import '../items/task_entry_list_item.dart';
import '../sheets/installation_sheet.dart';

class SetupListSearch extends StatelessWidget {
  const SetupListSearch({
    super.key, 
  });

  @override
  Widget build(BuildContext context) {
    return SearchAnchor(
      builder:(context, controller) {
        return FilterChip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          // label: Text(controller.text),
          label: const SizedBox.shrink(),
          labelPadding: const EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.zero,
          avatar: const Icon(Icons.search),
          showCheckmark: false,
          // selected: controller.text.isNotEmpty,
          selected: false,
          onSelected: (bool newValue) {controller.text = ""; controller.openView();},
          // onDeleted: controller.text.isEmpty ? null : () => setState(() => controller.text = ""),
        );
      },
      viewBuilder: (Iterable<Widget> suggestions) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: suggestions.length,
          itemBuilder: (context, index) => suggestions.elementAt(index),
        );
      },
      suggestionsBuilder: (context, controller) {
        final appSettings = context.read<AppSettings>();
        final appRepository = context.read<AppRepository>();

        final controllerText = controller.text.trim().toLowerCase();
        final sortAscending = appRepository.stravaSortAscending;
        
        final List<TimelineEntry> matchingEntries = [];

        if (appSettings.displayShowSetups) {
          final setups = appRepository.filteredSetups.values;
          matchingEntries.addAll(setups.where((s) => 
            s.name.toLowerCase().contains(controllerText) || 
            (s.notes ?? "").toLowerCase().contains(controllerText)
          ).map((s) => SetupEntry(s)));
        }

        if (appSettings.displayShowActivities) {
          final activities = appRepository.filteredStravaActivities.values;
          matchingEntries.addAll(activities.where((a) => 
            a.name.toLowerCase().contains(controllerText)
          ).map((a) => StravaEntry(a)));
        }

        if (appSettings.displayShowTasks) {
          final tasks = appRepository.filteredTaskEntries.values;
          matchingEntries.addAll(tasks.where((t) => 
            t.name.toLowerCase().contains(controllerText) || 
            (t.notes ?? "").toLowerCase().contains(controllerText)
          ).map((t) => TaskTimeLineEntry(t)));
        }

        if (appSettings.displayShowInstallations) {
          final installations = appRepository.filteredInstallations;
          matchingEntries.addAll(installations.where((ci) => 
            ci.component.name.toLowerCase().contains(controllerText) || 
            ci.component.componentType.label.toLowerCase().contains(controllerText)
          ).map((ci) => InstallationEntry(ci)));
        }

        matchingEntries.sort((a, b) {
          return sortAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date);
        });

        return matchingEntries.map((entry) {
          switch (entry) {
            case SetupEntry():
              return SetupListCard(
                setupId: entry.setup.id, 
                onTap: () async {
                  await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => SetupDetailsPage(
                    setupIds: matchingEntries.whereType<SetupEntry>().map((e) => e.setup.id).toList(),
                    initialSetup: entry.setup,
                  )));
                },
                displayOnlyChanges: appSettings.setupListOnlyChanges, 
                displayBikeAdjustmentValues:appSettings.setupListBikeAdjustmentValues, 
                displayPersonAdjustmentValues: appSettings.setupListPersonAdjustmentValues, 
                displayRatingAdjustmentValues: appSettings.setupListRatingAdjustmentValues,
              );
            case StravaEntry():
              return StravaListTile(stravaActivity: entry.activity);
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
        });
      },
    );
  }
}
