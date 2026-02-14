import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/setup.dart';
import '../models/strava/strava_activity.dart';
import '../models/filtered_data.dart';
import '../pages/setup_display_page.dart';
import 'setup_list_card.dart';
import 'strava_list_tile.dart';

class SetupList extends StatelessWidget {
  final Future<void> Function(Setup setup) editSetup;
  final Future<void> Function(Setup setup) restoreSetup;
  final Future<void> Function(Setup setup) removeSetup;
  final bool displayOnlyChanges;
  final Widget filterWidget;
  final bool displayBikeAdjustmentValues;
  final bool displayPersonAdjustmentValues;
  final bool displayRatingAdjustmentValues;
  final bool accending;

  const SetupList({
    super.key,
    required this.editSetup,
    required this.restoreSetup,
    required this.removeSetup,
    required this.displayOnlyChanges,
    required this.filterWidget,
    required this.displayBikeAdjustmentValues,
    required this.displayPersonAdjustmentValues,
    required this.displayRatingAdjustmentValues,
    required this.accending,
  });

  Widget _emptyPlaceholder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          filterWidget,
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
    final filteredData = context.watch<FilteredData>();
    final setupsList = filteredData.filteredSetups.values;
    final stravaActivities = filteredData.filteredStravaActivities.values;

    final List<TimelineEntry> entries =  [...setupsList.map((s) => SetupEntry(s)), ...stravaActivities.map((a) => StravaEntry(a))];
    entries.sort((a, b) => accending ? a.date.compareTo(b.date) : b.date.compareTo(a.date));

    return setupsList.isEmpty
        ? _emptyPlaceholder(context)
        : ListView.builder(
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16, bottom: 16+100),
            itemCount: entries.length + 1, // 1 header
            itemBuilder: (context, index) {
              if (index == 0) return filterWidget;
              
              final entry = entries[index - 1];
              switch (entry) {
                case StravaEntry(): 
                  return StravaListTile(stravaActivity: entry.activity);
                case SetupEntry():
                  final setup = entry.setup;
                  return SetupListCard(
                    setupId: setup.id,
                    onTap: () async {
                      Navigator.push<void>(context, MaterialPageRoute(builder: (context) => SetupDisplayPage(
                        setupIds: setupsList.map((s) => s.id).toList(),
                        initialSetup: setup,
                        editSetup: editSetup,
                      )));
                    },
                    editSetup: editSetup,
                    restoreSetup: restoreSetup,
                    removeSetup: removeSetup,
                    displayOnlyChanges: displayOnlyChanges,
                    displayBikeAdjustmentValues: displayBikeAdjustmentValues,
                    displayPersonAdjustmentValues: displayPersonAdjustmentValues,
                    displayRatingAdjustmentValues: displayRatingAdjustmentValues,
                  ); 
              }
            },
          );
  }
}

sealed class TimelineEntry {
  DateTime get date;
}

class SetupEntry extends TimelineEntry {
  final Setup setup;
  SetupEntry(this.setup);
  @override DateTime get date => setup.datetime;
}

class StravaEntry extends TimelineEntry {
  final StravaActivity activity;
  StravaEntry(this.activity);
  @override DateTime get date => activity.startDate;
}
