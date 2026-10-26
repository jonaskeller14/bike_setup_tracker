import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/feedback/test_session.dart';
import '../../models/feedback/test_session_method.dart';
import '../../pages/details/setup_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../services/test_session_service.dart';
import '../../utils/test_session_actions.dart';
import '../items/feedback_list_tile.dart';
import '../items/setup_tile.dart';
import '../items/tile_meta_row.dart';
import '../running_badge.dart';
import '../test_session_next_step.dart';
import '../test_session_suggestion.dart';
import '../text/section_title.dart';
import 'sheet_header.dart';

Future<void> showTestSessionSheet({required BuildContext context, required String sessionId}) {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (context) => TestSessionSheetContent(sessionId: sessionId),
  );
}

/// The session's details: method and goal, the adjustments it tunes (tap one
/// to lock it) or, comparing setups, those they differ in, every run with its values and feedbacks, the suggested next
/// run, and the next step.
/// A running session opens scrolled to its next step.
class TestSessionSheetContent extends StatefulWidget {
  final String sessionId;

  const TestSessionSheetContent({super.key, required this.sessionId});

  @override
  State<TestSessionSheetContent> createState() => _TestSessionSheetContentState();
}

class _TestSessionSheetContentState extends State<TestSessionSheetContent> {
  final _nextStepKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nextStep = _nextStepKey.currentContext;
      if (nextStep != null) unawaited(Scrollable.ensureVisible(nextStep, alignment: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final session = appRepository.testSessions[widget.sessionId];
    if (session == null) {
      return const Padding(padding: EdgeInsets.all(24), child: Text('This test session no longer exists.'));
    }
    final theme = Theme.of(context);
    final runs = appRepository.setupsInSession(session.id);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              title: session.displayName,
              leadingIcon: const Icon(TestSession.iconData),
              titleMaxLines: 2,
              onEdit: () => unawaited(TestSessionActions.editSession(context, session: session)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (session.isRunning)
                    const RunningBadge()
                  else
                    const TileMetaRow(icon: Icons.stop_circle_outlined, text: 'Ended'),
                  TileMetaRow(icon: Icons.tune, text: TestSessionService.methodLabel(session.method)),
                  TileMetaRow(
                    icon: Icons.directions_bike,
                    text: Intl.plural(runs.length, one: '1 run', other: '${runs.length} runs'),
                  ),
                  for (final aspect in session.goal)
                    TileMetaRow(
                      icon: Icons.track_changes,
                      text: TestSessionService.goalLabel(aspect, appRepository.customIssues.labelOf),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                TestSessionService.methodDescription(session.method),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            SectionTitle(
              title: 'Adjustments',
              infoText: session.isRunning && session.method is! Tournament
                  ? 'Tap an adjustment to lock it at its value in the latest run. The next runs keep that value.'
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _knobs(context, appRepository, session),
            ),
            const SectionTitle(title: 'Runs'),
            ..._runs(context, appRepository, session),
            TestSessionSuggestion(session: session),
            if (session.isRunning)
              Padding(
                key: _nextStepKey,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TestSessionNextStep(session: session),
              ),
          ],
        ),
      ),
    );
  }

  /// One chip per adjustment: free ones can move, locked ones hold their value.
  Widget _knobs(BuildContext context, AppRepository appRepository, TestSession session) {
    final now = DateTime.now().toUtc();
    final knobs = {
      for (final knob in TestSessionService.knobsFor(
        bikeComponents: appRepository.components.values.where(
          (component) => appRepository.componentHierarchy.bikeAt(component.id, now) == session.bike,
        ),
        rider: appRepository.persons[appRepository.bikes[session.bike]?.person],
      ))
        knob.adjustment.id: knob,
    };
    // The owner only where two adjustments share a name, e.g. the fork's and the shock's rebound.
    final names = session.adjustmentIds.map((id) => knobs[id]?.adjustment.name).nonNulls.toList();
    String labelOf(String id) {
      final knob = knobs[id];
      if (knob == null) return 'ADJUSTMENT NOT FOUND';
      final name = knob.adjustment.name;
      return names.where((other) => other == name).length > 1 ? '${knob.ownerName} · $name' : name;
    }

    // The candidates are ridden as they are, so there is nothing to lock.
    if (session.method is Tournament) {
      final theme = Theme.of(context);
      final style = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('The adjustments your setups differ in:', style: style),
          for (final id in session.adjustmentIds) Text('•  ${labelOf(id)}', style: style),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final id in session.adjustmentIds)
          FilterChip(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            showCheckmark: false,
            avatar: Icon(session.locks.containsKey(id) ? Icons.lock : Icons.swap_vert, size: 18),
            label: Text(labelOf(id), maxLines: 1, overflow: TextOverflow.ellipsis),
            tooltip: !session.isRunning
                ? null
                : session.locks.containsKey(id)
                ? 'Locked at its value. Tap to unlock.'
                : 'Tap to lock it at its value in the latest run.',
            selected: session.locks.containsKey(id),
            onSelected: session.isRunning
                ? (_) => unawaited(TestSessionActions.toggleLock(context, session: session, adjustmentId: id))
                : null,
          ),
      ],
    );
  }

  /// One card per run, oldest first: the run's values and the feedbacks on it.
  /// Collapsed, a run shows the session's adjustments so the runs compare.
  List<Widget> _runs(BuildContext context, AppRepository appRepository, TestSession session) {
    final runs = appRepository.setupsInSession(session.id);
    if (runs.isEmpty) return const [ListTile(title: Text('No runs yet.'))];

    final adjustmentIds = session.adjustmentIds.toSet();
    return [
      for (final run in runs)
        Card.outlined(
          key: ValueKey(run.id),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SetupTile(
                setupId: run.id,
                collapsedAdjustmentIds: adjustmentIds,
                onTap: () => unawaited(
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SetupDetailsPage(setupIds: runs.map((run) => run.id).toList(), initialSetup: run),
                    ),
                  ),
                ),
              ),
              for (final feedback
                  in appRepository.feedbacksForSetup(run.id).toList()
                    ..sort((a, b) => a.dateTimeUTC.compareTo(b.dateTimeUTC))) ...[
                const Divider(height: 1),
                FeedbackListTile(key: ValueKey(feedback.id), feedback: feedback, showBike: false),
              ],
            ],
          ),
        ),
    ];
  }
}
