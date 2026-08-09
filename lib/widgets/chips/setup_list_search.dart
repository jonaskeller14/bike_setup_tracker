import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/context/context_place.dart';
import '../../models/timeline_entry.dart';
import '../../pages/details/setup_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../utils/text_search.dart';
import '../../utils/timeline_grouping.dart';
import '../items/installation_list_tile.dart';
import '../items/rating_entry_list_tile.dart';
import '../items/setup_list_tile.dart';
import '../items/strava_list_tile.dart';
import '../items/task_entry_list_item.dart';
import '../sheets/installation_sheet.dart';
import '../sheets/task_rule_sheet.dart';
import '../timeline_day_header.dart';

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
        // The search view is pushed as its own route, outside this widget's
        // ancestor Scaffold — Scaffold.resizeToAvoidBottomInset zeroes out
        // viewInsets.bottom for its body subtree, so reading MediaQuery from
        // the outer (Scaffold-body) context would always see 0 here. A
        // Builder gets a context that belongs to the route itself instead.
        return Builder(
          builder: (context) {
            final mediaQuery = MediaQuery.of(context);
            final bottomInset = math.max(mediaQuery.viewPadding.bottom, mediaQuery.viewInsets.bottom);
            return ListView.builder(
              padding: EdgeInsets.only(bottom: bottomInset),
              itemCount: suggestions.length,
              itemBuilder: (context, index) => suggestions.elementAt(index),
            );
          },
        );
      },
      suggestionsBuilder: (context, controller) async {
        final appSettings = context.read<AppSettings>();
        final appRepository = context.read<AppRepository>();
        final subscriptionService = context.read<SubscriptionService>();

        final controllerText = controller.text.trim().toLowerCase();
        final searchTokens = tokenizeSearchQuery(controllerText);
        final sortAscending = appRepository.stravaSortAscending;

        final List<TimelineEntry> matchingEntries = [];

        if (appSettings.displayShowSetups) {
          final setups = appRepository.filteredSetups.values;
          matchingEntries.addAll(
            setups
                .where(
                  (s) => searchFieldsMatch([
                    s.displayName,
                    s.notes,
                    ...ContextPlace.searchableFields(s.place),
                  ], searchTokens),
                )
                .map((s) => SetupEntry(s)),
          );
        }

        if (appSettings.displayShowActivities && appSettings.enableStrava && subscriptionService.hasStravaEntitlement) {
          final activities = await appRepository.searchStravaActivities(controllerText);
          matchingEntries.addAll(activities.map((a) => StravaEntry(a)));
        }

        if (appSettings.displayShowTasks) {
          final tasks = appRepository.filteredTaskEntries.values;
          matchingEntries.addAll(
            tasks
                .where(
                  (t) => searchFieldsMatch([
                    t.name,
                    t.notes,
                  ], searchTokens),
                )
                .map((t) => TaskTimeLineEntry(t)),
          );
        }

        if (appSettings.displayShowInstallations) {
          final installations = appRepository.filteredInstallations;
          matchingEntries.addAll(
            installations
                .where(
                  (ci) => searchFieldsMatch([
                    ci.component.name,
                    ci.component.componentType.label,
                  ], searchTokens),
                )
                .map((ci) => InstallationEntry(ci)),
          );
        }

        if (appSettings.enableRating && appSettings.displayShowRatingEntries) {
          final ratingEntries = appRepository.filteredRatingEntries.values;
          matchingEntries.addAll(
            ratingEntries
                .where(
                  (re) => searchFieldsMatch([
                    re.displayName,
                    re.notes,
                    ...ContextPlace.searchableFields(re.place),
                  ], searchTokens),
                )
                .map((re) => RatingEntryTimelineEntry(re)),
          );
        }

        matchingEntries.sort((a, b) {
          return sortAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date);
        });

        final showDayHeaders = appSettings.enableTimelineDayHeaders;
        final showDate = !showDayHeaders;

        Widget entryWidget(TimelineEntry entry, {EdgeInsets edgeInset = EdgeInsets.zero}) {
          switch (entry) {
            case SetupEntry():
              return SetupListTile(
                setupId: entry.setup.id,
                showDate: showDate,
                onTap: () async {
                  await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => SetupDetailsPage(
                    setupIds: matchingEntries.whereType<SetupEntry>().map((e) => e.setup.id).toList(),
                    initialSetup: entry.setup,
                  )));
                },
                displayBikeAdjustmentValues:appSettings.setupListBikeAdjustmentValues,
                displayPersonAdjustmentValues: appSettings.setupListPersonAdjustmentValues,
                edgeInset: edgeInset,
              );
            case StravaEntry():
              return StravaListTile(stravaActivity: entry.activity, showDate: showDate);
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
              return RatingEntryListTile(ratingEntry: entry.ratingEntry, showDate: showDate);
          }
        }

        DateTime entryDay(TimelineEntry entry) {
          final local = timelineEntryLocalDate(entry);
          return DateTime(local.year, local.month, local.day);
        }

        final widgets = <Widget>[];
        DateTime? currentDay;
        TimelineEntry? previous;
        for (var i = 0; i < matchingEntries.length; i++) {
          final entry = matchingEntries[i];
          EdgeInsets edgeInset = EdgeInsets.zero;
          if (showDayHeaders) {
            final day = entryDay(entry);
            if (day != currentDay) {
              widgets.add(
                TimelineDayHeader(
                  day: day,
                  margin: EdgeInsets.zero,
                  onContainerSurface: true,
                ),
              );
              currentDay = day;
              previous = null; // no divider right after a header
            }
            final isFirstOfDay = previous == null;
            final isLastOfDay = i == matchingEntries.length - 1 || entryDay(matchingEntries[i + 1]) != day;
            edgeInset = EdgeInsets.only(
              top: isFirstOfDay ? 8 : 0,
              bottom: isLastOfDay ? 8 : 0,
            );
          }
          if (previous != null) widgets.add(const Divider(height: 1));
          final child = entryWidget(entry, edgeInset: edgeInset);
          // Setup tiles absorb the inset so their current highlight paints over
          // it; every other row takes it as plain outer padding.
          widgets.add(
            entry is SetupEntry ? child : Padding(padding: edgeInset, child: child),
          );
          previous = entry;
        }
        return widgets;
      },
    );
  }
}
