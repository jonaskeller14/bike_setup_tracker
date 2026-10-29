import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/adjustment/adjustment.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/feedback/test_session.dart';
import '../../models/setup.dart';
import '../../models/timeline_entry.dart';
import '../../repositories/app_repository.dart';
import '../../services/dangling_adjustment_service.dart';
import '../../services/test_session_service.dart';
import '../current_setup_badge.dart';
import '../lists/adjustment_compact_display/adjustment_compact_display_list.dart';
import '../running_badge.dart';
import '../sheets/test_session_sheet.dart';
import '../test_session_next_step.dart';
import 'feedback_list_tile.dart';
import 'setup_group_header.dart';
import 'setup_options_menu.dart';
import 'setup_tile_header.dart';
import 'test_session_options_menu.dart';
import 'tile_meta_row.dart';
import 'timeline_selection_fill.dart';

/// A test session as one timeline item: its latest runs and feedbacks, and the
/// next step while it runs. The session sheet behind a tap lists everything.
/// Selecting it selects the whole session.
class TestSessionTimelineItem extends StatelessWidget {
  /// The latest runs and feedbacks the item shows; the rest is in the sheet.
  static const int visibleItems = 2;

  final TestSessionTimelineEntry entry;
  final void Function(Setup run)? onTapRun;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onSelectionChanged;

  const TestSessionTimelineItem({
    super.key,
    required this.entry,
    this.onTapRun,
    this.selectionMode = false,
    this.selected = false,
    this.onSelectionChanged,
  });

  /// "09:00 – 10:30", or with the end's date when the session spans days.
  String _timeRange(AppSettings appSettings) {
    final start = entry.dateLocal;
    final end = entry.endLocal;
    final time = DateFormat(appSettings.timeFormat);
    final startText = time.format(start);
    if (!end.isAfter(start)) return startText;
    final sameDay = DateUtils.isSameDay(start, end);
    final endText = sameDay
        ? time.format(end)
        : '${DateFormat(appSettings.dateFormat).format(end)} • ${time.format(end)}';
    return startText == endText ? startText : '$startText – $endText';
  }

  void _openSheet(BuildContext context) =>
      unawaited(showTestSessionSheet(context: context, sessionId: entry.session.id));

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final session = entry.session;
    final bike = appRepository.bikes[session.bike];
    final outline = Theme.of(context).colorScheme.outlineVariant;

    // In the timeline's order, so the latest items sit on the timeline's newer side.
    final ascending = appRepository.stravaSortAscending;
    final items = TestSessionService.runsAndFeedbacks(
      entry.runs,
      (run) => entry.feedbacksByRun[run.id] ?? const [],
      ascending: ascending,
    );
    final hidden = items.length - visibleItems;
    final visible = hidden <= 0
        ? items
        : ascending
        ? items.sublist(hidden)
        : items.sublist(0, visibleItems);

    final metadata = <Widget>[
      TileMetaRow(icon: Icons.psychology, text: TestSessionService.methodLabel(session.method), muted: true),
      TileMetaRow(
        icon: Icons.repeat,
        text: Intl.plural(entry.runs.length, one: '1 run', other: '${entry.runs.length} runs'),
        muted: true,
      ),
      for (final aspect in session.goal)
        TileMetaRow(
          icon: Icons.track_changes,
          text: TestSessionService.goalLabel(aspect, appRepository.customIssues.labelOf),
          muted: true,
        ),
    ];

    Widget itemWidget(TimelineEntry item) => switch (item) {
      SetupEntry(setup: final run) => _RunRow(
        key: ValueKey(run.id),
        run: run,
        session: session,
        showDate: !DateUtils.isSameDay(run.datetimeLocal, entry.dateLocal),
        onTap: onTapRun == null ? null : () => onTapRun!(run),
        selectionMode: selectionMode,
        onSelectionChanged: onSelectionChanged,
      ),
      FeedbackTimelineEntry(:final feedback) => FeedbackListTile(
        key: ValueKey(feedback.id),
        feedback: feedback,
        selectionMode: selectionMode,
        onSelectionChanged: onSelectionChanged,
        showDate: !DateUtils.isSameDay(feedback.dateTimeLocal, entry.dateLocal),
        showBike: false,
      ),
      _ => const SizedBox.shrink(),
    };

    final showEarlier = Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        onPressed: selectionMode ? onSelectionChanged : () => _openSheet(context),
        icon: const Icon(Icons.unfold_more),
        label: Text(Intl.plural(hidden, one: 'Show 1 earlier', other: 'Show $hidden earlier')),
      ),
    );

    return TimelineSelectionFill(
      selected: selected,
      child: InkWell(
        onTap: selectionMode ? onSelectionChanged : () => _openSheet(context),
        onLongPress: onSelectionChanged,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SetupGroupHeader(
              setupCount: entry.runs.length,
              title: session.displayName,
              iconData: TestSession.iconData,
              dateTimeText: _timeRange(appSettings),
              bikeMetadata: TileMetaRow(
                icon: Bike.iconData,
                text: bike?.name ?? 'BIKE NOT FOUND',
                isError: bike == null,
              ),
              contextMetadata: metadata,
              selected: selected,
              badge: session.isRunning ? const RunningBadge() : null,
              trailing: selectionMode ? null : TestSessionOptionsMenu(session: session),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  border: Border.all(color: outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hidden > 0 && ascending) ...[showEarlier, Divider(height: 1, thickness: 1, color: outline)],
                    for (final (index, item) in visible.indexed) ...[
                      if (index > 0) Divider(height: 1, thickness: 1, color: outline),
                      itemWidget(item),
                    ],
                    if (hidden > 0 && !ascending) ...[Divider(height: 1, thickness: 1, color: outline), showEarlier],
                  ],
                ),
              ),
            ),
            if (session.isRunning)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TestSessionNextStep(session: session),
              ),
          ],
        ),
      ),
    );
  }
}

/// One run: name and time, and the session's adjustment values with the
/// changes to the run before highlighted.
class _RunRow extends StatelessWidget {
  final Setup run;
  final TestSession session;
  final bool showDate;
  final VoidCallback? onTap;
  final bool selectionMode;
  final VoidCallback? onSelectionChanged;

  const _RunRow({
    super.key,
    required this.run,
    required this.session,
    required this.showDate,
    required this.onTap,
    required this.selectionMode,
    required this.onSelectionChanged,
  });

  Widget? _knobValues(AppSettings appSettings, AppRepository appRepository) {
    final knobIds = session.adjustmentIds.toSet();
    Map<String, AdjustmentValue> knobsOnly(Map<String, AdjustmentValue> values) => {
      for (final MapEntry(:key, :value) in values.entries)
        if (knobIds.contains(key)) key: value,
    };
    final values = knobsOnly({...run.bikeAdjustmentValues, ...run.personAdjustmentValues});
    final previous = knobsOnly(appRepository.setupHistory.previousValuesOf(run.id));
    final breakdown = DanglingAdjustmentService.analyzeSetup(
      setup: run,
      components: appRepository.components.values,
      persons: appRepository.persons.values,
    );
    final persons = [?breakdown.person];
    final hasContent = AdjustmentCompactDisplayList.summarize(
      components: breakdown.components,
      persons: persons,
      adjustmentValues: values,
      previousAdjustmentValues: previous,
      displayPersonAdjustmentValues: appSettings.enablePerson,
    ).hasContent;
    if (!hasContent) return null;

    return AdjustmentCompactDisplayList(
      components: breakdown.components,
      persons: persons,
      adjustmentValues: values,
      previousAdjustmentValues: previous,
      showRowIcons: true,
      displayPersonAdjustmentValues: appSettings.enablePerson,
      ancestorsOf: (componentId) => appRepository.componentHierarchy.ancestorsBelowBikeAt(componentId, run.datetime),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final time = DateFormat(appSettings.timeFormat).format(run.datetimeLocal);
    final knobValues = _knobValues(appSettings, appRepository);

    return InkWell(
      onTap: selectionMode ? onSelectionChanged : onTap,
      onLongPress: onSelectionChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            // The menu sits on the same edge as the feedback tiles' menus.
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SetupTileHeader(
                    setup: run,
                    dateTimeText: showDate
                        ? '${DateFormat(appSettings.dateFormat).format(run.datetimeLocal)} • $time'
                        : time,
                    metadata: [
                      ...SetupTileHeader.metadataOf(run, appSettings),
                      ?SetupTileHeader.rankOf(run, appSettings, appRepository),
                    ],
                    badge: appRepository.setupHistory.isCurrent(run.id) ? const CurrentSetupBadge() : null,
                    showSetupIcon: false,
                  ),
                ),
                if (!selectionMode) SetupOptionsMenu(setup: run),
              ],
            ),
          ),
          if (knobValues != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: knobValues),
        ],
      ),
    );
  }
}
