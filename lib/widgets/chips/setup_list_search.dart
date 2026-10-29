import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/context/context_place.dart';
import '../../models/feedback/feedback_summary.dart';
import '../../models/filters/layer_filter.dart';
import '../../models/timeline_entry.dart';
import '../../pages/details/setup_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../services/subscription_service.dart';
import '../../services/test_session_service.dart';
import '../../utils/text_search.dart';
import '../../utils/timeline_grouping.dart';
import '../items/feedback_list_tile.dart';
import '../items/installation_list_tile.dart';
import '../items/setup_tile.dart';
import '../items/strava_list_tile.dart';
import '../items/task_entry_list_item.dart';
import '../items/test_session_timeline_item.dart';
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
          label: const SizedBox.shrink(),
          labelPadding: const EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.zero,
          avatar: const Icon(Icons.search),
          showCheckmark: false,
          selected: false,
          onSelected: (bool newValue) {controller.text = ""; controller.openView();},
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
            return SafeArea(
              bottom: false,
              top: false,
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: bottomInset),
                itemCount: suggestions.length,
                itemBuilder: (context, index) => suggestions.elementAt(index),
              ),
            );
          },
        );
      },
      suggestionsBuilder: (context, controller) async {
        final appSettings = context.read<AppSettings>();
        final appRepository = context.read<AppRepository>();
        final subscriptionService = context.read<SubscriptionService>();
        final layers = appRepository.filters.layers;

        final controllerText = controller.text.trim().toLowerCase();
        final searchTokens = tokenizeSearchQuery(controllerText);
        final sortAscending = appRepository.stravaSortAscending;

        final List<TimelineEntry> matchingEntries = [];

        if (layers.shows(TimelineLayer.setups)) {
          final setups = appRepository.view.setups.values;
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

        if (layers.shows(TimelineLayer.activities) && appSettings.enableStrava && subscriptionService.hasStravaEntitlement) {
          final activities = await appRepository.searchStravaActivities(controllerText);
          matchingEntries.addAll(activities.map((a) => StravaEntry(a)));
        }

        if (layers.shows(TimelineLayer.tasks)) {
          final tasks = appRepository.view.taskEntries.values;
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

        if (layers.shows(TimelineLayer.installations)) {
          final installations = appRepository.view.installations;
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

        if (appSettings.enableRating && layers.shows(TimelineLayer.feedback)) {
          final feedbacks = appRepository.view.feedbacks.values;
          matchingEntries.addAll(
            feedbacks
                .where(
                  (f) => searchFieldsMatch([
                    f.notes,
                    ...f.orderedIssues.map((issue) => issue.label),
                    ...ContextPlace.searchableFields(f.place),
                  ], searchTokens),
                )
                .map((f) => FeedbackTimelineEntry(f)),
          );
        }

        // A session shows as one item, with all its runs and their feedbacks,
        // when its name, a goal, a run name or anything inside it matches.
        if (appSettings.enableRating && layers.shows(TimelineLayer.setups)) {
          final sessions = appRepository.view.testSessions;
          String? sessionIdOf(TimelineEntry entry) => switch (entry) {
            SetupEntry(:final setup) => setup.testSessionId,
            FeedbackTimelineEntry(:final feedback) =>
              appRepository.setups[appRepository.resolvedSetupIdFor(feedback)]?.testSessionId,
            _ => null,
          };
          final matchedIds = <String>{
            for (final session in sessions.values)
              if (searchFieldsMatch([
                session.name,
                ...session.goal.map((aspect) => TestSessionService.goalLabel(aspect, appRepository.customIssues.labelOf)),
              ], searchTokens))
                session.id,
            for (final entry in matchingEntries)
              if (sessionIdOf(entry) case final id? when sessions.containsKey(id)) id,
          };
          final contents = <TimelineEntry>[
            ...appRepository.view.setups.values.map((s) => SetupEntry(s)),
            if (layers.shows(TimelineLayer.feedback))
              ...appRepository.view.feedbacks.values.map((f) => FeedbackTimelineEntry(f)),
          ].where((entry) => matchedIds.contains(sessionIdOf(entry)));
          // A run or feedback can match on its own and through its session.
          final seen = <String>{};
          final bundled = bundleTestSessions(
            [...matchingEntries, ...contents].where((entry) => seen.add(entry.id)).toList(),
            sessions: {for (final id in matchedIds) id: sessions[id]!},
            ratedSetupIdOf: appRepository.resolvedSetupIdFor,
          );
          matchingEntries
            ..clear()
            ..addAll(bundled);
        }

        matchingEntries.sort((a, b) {
          return sortAscending ? compareTimelineEntries(a, b) : compareTimelineEntries(b, a);
        });

        Widget entryWidget(TimelineEntry entry, {EdgeInsets edgeInset = EdgeInsets.zero}) {
          switch (entry) {
            case SetupEntry():
              return SetupTile(
                setupId: entry.setup.id,
                showDate: false,
                onTap: () async {
                  await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => SetupDetailsPage(
                    setupIds: matchingEntries.whereType<SetupEntry>().map((e) => e.setup.id).toList(),
                    initialSetup: entry.setup,
                  )));
                },
                edgeInset: edgeInset,
              );
            case StravaEntry():
              return StravaListTile(stravaActivity: entry.activity, showDate: false);
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
            case FeedbackTimelineEntry():
              return FeedbackListTile(feedback: entry.feedback, showDate: false);
            case TestSessionTimelineEntry():
              return TestSessionTimelineItem(
                entry: entry,
                onTapRun: (run) async {
                  await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => SetupDetailsPage(
                    setupIds: entry.runs.map((run) => run.id).toList(),
                    initialSetup: run,
                  )));
                },
              );
          }
        }

        DateTime entryDay(TimelineEntry entry) {
          final local = entry.dateLocal;
          return DateTime(local.year, local.month, local.day);
        }

        final widgets = <Widget>[];
        DateTime? currentDay;
        TimelineEntry? previous;
        for (var i = 0; i < matchingEntries.length; i++) {
          final entry = matchingEntries[i];
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
          final edgeInset = EdgeInsets.only(
            top: isFirstOfDay ? 8 : 0,
            bottom: isLastOfDay ? 8 : 0,
          );
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
