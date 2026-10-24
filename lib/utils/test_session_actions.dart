import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/adjustment/adjustment.dart';
import '../models/bike.dart';
import '../models/feedback/test_session.dart';
import '../models/feedback/test_session_method.dart';
import '../models/setup.dart';
import '../pages/forms/setup_page.dart';
import '../pages/forms/test_session_page.dart';
import '../repositories/app_repository.dart';
import '../services/test_session/suggestion_result.dart';
import '../services/test_session_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/dialogs/confirmation.dart';
import '../widgets/sheets/sheet_header.dart';
import 'feedback_actions.dart';

class TestSessionActions {
  /// Opens the create form and, on save, records the session with its first
  /// run: a copy of the bike's current setup (or of the first setup to compare),
  /// stamped now.
  ///
  /// With a [baseSetup] (e.g. the current setup from its menu) the first run
  /// copies it, so a session never starts from an outdated setup by accident.
  static Future<void> startSession(BuildContext context, {Bike? initialBike, Setup? baseSetup}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    if (appRepository.bikes.isEmpty) {
      messenger.showSnackBar(AppSnackBar.error(context, 'A bike is required to start a test session'));
      return;
    }
    if (!appRepository.components.values.any((component) => component.adjustments.isNotEmpty) &&
        !appRepository.persons.values.any((person) => person.adjustments.isNotEmpty)) {
      messenger.showSnackBar(AppSnackBar.error(context, 'Add an adjustment to a component first'));
      return;
    }

    final session = await Navigator.push<TestSession>(
      context,
      MaterialPageRoute(
        builder: (context) => TestSessionPage(initialBike: initialBike, baseSetup: baseSetup),
      ),
    );
    if (session == null) return;

    final source = _firstRunSource(appRepository, session, baseSetup);
    if (source == null) return;
    await appRepository.startTestSession(session, TestSessionService.run(source: source, session: session, number: 1));
  }

  static Setup? _firstRunSource(AppRepository appRepository, TestSession session, Setup? baseSetup) {
    final candidates = switch (session.method) {
      Tournament(:final candidateSetupIds) => candidateSetupIds,
      _ => const <String>[],
    };
    if (candidates.isNotEmpty) return appRepository.setups[candidates.first];
    if (baseSetup != null) return baseSetup;
    return appRepository.setups[appRepository.resolveSetupId(bikeId: session.bike, atUtc: DateTime.now().toUtc())];
  }

  /// The next run of a running [session]: a copy of [source] (default: the last
  /// run, with the strategy's proposal set) where only the session's knobs can
  /// change. A Compare session copies one of its candidates as it is. Returns
  /// the recorded run.
  static Future<Setup?> addRun(BuildContext context, {required TestSession session, Setup? source}) async {
    final appRepository = context.read<AppRepository>();
    if (!session.isRunning) return null;

    final runs = appRepository.setupsInSession(session.id);
    // Every run is rated before the next one, even if only with an empty feedback.
    final latest = runs.lastOrNull;
    if (latest != null && appRepository.feedbacksForSetup(latest.id).isEmpty) {
      final rated = await FeedbackActions.addFeedbackForSetup(context, setup: latest);
      if (!rated || !context.mounted) return null;
    }
    final number = runs.length + 1;
    final suggestion = source == null ? appRepository.suggestionFor(session.id) : null;
    final proposal = suggestion is Proposal ? suggestion : null;
    // Without runs (all removed) the next one starts from the bike's current setup, like run 1.
    final from =
        source ??
        (session.method is Tournament
            ? await _pickCandidate(context, session, suggestedId: proposal?.baseSetupId)
            : runs.lastOrNull ??
                  appRepository.setups[appRepository.resolveSetupId(
                    bikeId: session.bike,
                    atUtc: DateTime.now().toUtc(),
                  )]);
    if (from == null || !context.mounted) return null;

    if (session.method is Tournament) {
      final run = TestSessionService.run(source: from, session: session, number: number);
      await appRepository.addTestSessionRun(session, run, proposal: proposal?.values);
      return run;
    }
    final run = TestSessionService.run(
      source: from,
      session: session,
      number: number,
      values: proposal?.values ?? const {},
    );

    final saved = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(
        builder: (context) => SetupPage.nextRun(run: run, session: session),
      ),
    );
    if (saved == null) return null;
    await appRepository.addTestSessionRun(session, saved, proposal: proposal?.values);
    return saved;
  }

  /// The candidates of a Compare session, the [suggestedId] one first.
  static Future<Setup?> _pickCandidate(BuildContext context, TestSession session, {String? suggestedId}) {
    final appRepository = context.read<AppRepository>();
    final candidates = [
      for (final id in (session.method as Tournament).candidateSetupIds) ?appRepository.setups[id],
    ]..sort((a, b) => (b.id == suggestedId ? 1 : 0).compareTo(a.id == suggestedId ? 1 : 0));
    return showModalBottomSheet<Setup>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHeader(title: 'Ride which setup?'),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final candidate in candidates)
                    ListTile(
                      leading: const Icon(Setup.iconData),
                      title: Text(candidate.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: candidate.id == suggestedId ? const Text('Suggested') : null,
                      onTap: () => Navigator.pop(context, candidate),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Feedback on the latest run of [session].
  static Future<void> addRunFeedback(BuildContext context, {required TestSession session}) {
    final run = context.read<AppRepository>().setupsInSession(session.id).lastOrNull;
    if (run == null) return Future.value();
    return FeedbackActions.addFeedbackForSetup(context, setup: run);
  }

  /// Freezes the knob at its value in the latest run, or releases it.
  static Future<void> toggleLock(
    BuildContext context, {
    required TestSession session,
    required String adjustmentId,
  }) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    unawaited(HapticFeedback.selectionClick());

    if (session.locks.containsKey(adjustmentId)) {
      await appRepository.setTestSessionLock(session, adjustmentId, null);
      return;
    }
    final run = appRepository.setupsInSession(session.id).lastOrNull;
    final AdjustmentValue? value = run?.bikeAdjustmentValues[adjustmentId] ?? run?.personAdjustmentValues[adjustmentId];
    if (value == null) {
      messenger.showSnackBar(AppSnackBar.error(context, 'The latest run has no value to lock for this adjustment.'));
      return;
    }
    await appRepository.setTestSessionLock(session, adjustmentId, value);
  }

  static Future<void> endSession(BuildContext context, {required TestSession session}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showConfirmationDialog(
      context,
      title: 'End session?',
      content: "'${session.displayName}' keeps its runs, but you can't add new ones.",
      trueText: 'End session',
    );
    if (!confirmed) return;

    unawaited(HapticFeedback.mediumImpact());
    await appRepository.endTestSession(session);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Test session '${session.displayName}' ended.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.editTestSession(session),
        ),
      ),
    );
  }

  /// Only the name changes: the runs already depend on everything else.
  static Future<void> editSession(BuildContext context, {required TestSession session}) async {
    final appRepository = context.read<AppRepository>();

    final edited = await Navigator.push<TestSession>(
      context,
      MaterialPageRoute(builder: (context) => TestSessionPage.edit(session: session)),
    );
    if (edited == null) return;

    await appRepository.editTestSession(edited);
  }

  /// Moves the session to the trash with its runs and their feedbacks.
  static Future<void> removeSession(BuildContext context, {required TestSession session}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    unawaited(HapticFeedback.mediumImpact());
    final removed = await appRepository.removeTestSessions([session]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Test session '${session.displayName}' moved to trash.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async =>
              appRepository.restoreTestSessions([session], runs: removed.runs, feedbacks: removed.feedbacks),
        ),
      ),
    );
  }

  /// Whether a setup may be recorded on [bikeId] now. A running session asks to
  /// end first, so no change slips in between its runs.
  static Future<bool> ensureNoRunningSession(BuildContext context, {required String? bikeId}) async {
    final appRepository = context.read<AppRepository>();
    final session = bikeId == null ? null : appRepository.runningSessionFor(bikeId);
    if (session == null) return true;

    final end = await showConfirmationDialog(
      context,
      title: 'End the session first?',
      content:
          "'${session.displayName}' is running on this bike. A setup recorded now would confuse its runs. "
          'Use Next run to continue the session.',
      trueText: 'End session',
    );
    if (!end) return false;

    await appRepository.endTestSession(session);
    return true;
  }

  static Future<void> restoreTestSession(BuildContext context, {required TestSession session}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    await appRepository.restoreTestSessions([session]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        "Test session '${session.displayName}' restored from trash.",
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: 'UNDO',
          onPressed: () async => appRepository.removeTestSessions([session]),
        ),
      ),
    );
  }
}
