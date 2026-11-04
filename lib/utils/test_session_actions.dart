import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/entity_names.dart';
import '../l10n/l10n.dart';
import '../models/adjustment/adjustment.dart';
import '../models/app_settings.dart';
import '../models/bike.dart';
import '../models/feedback/ride_feedback.dart';
import '../models/feedback/test_session.dart';
import '../models/feedback/test_session_method.dart';
import '../models/setup.dart';
import '../pages/forms/setup_page.dart';
import '../pages/forms/test_session_page.dart';
import '../repositories/app_repository.dart';
import '../services/setup_carry_over.dart';
import '../services/test_session/suggestion_result.dart';
import '../services/test_session_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/dialogs/confirmation.dart';
import '../widgets/sheets/pick_setup.dart';
import 'carry_over_actions.dart';
import 'feedback_actions.dart';

typedef SessionStep = ({String label, IconData icon, Future<void> Function(BuildContext context) run});

class TestSessionActions {
  /// The bike new setups and sessions land on: the first one in view.
  static String? activeBikeId(AppRepository appRepository) {
    if (appRepository.bikes.isEmpty) return null;
    return appRepository.view.bikes.keys.firstOrNull ?? appRepository.bikes.keys.first;
  }

  /// What a button that adds a setup does instead while a session runs on the
  /// active bike, so it never opens a different form than its label says. Null
  /// without a running session.
  static SessionStep? nextStepFor(AppRepository appRepository, AppLocalizations l10n) {
    final bikeId = activeBikeId(appRepository);
    final session = bikeId == null ? null : appRepository.runningSessionFor(bikeId);
    if (session == null) return null;

    final latest = appRepository.setupsInSession(session.id).lastOrNull;
    if (latest != null && appRepository.feedbacksForSetup(latest.id).isEmpty) {
      return (
        label: l10n.setupOptionAddFeedback,
        icon: RideFeedback.iconData,
        run: (context) => addRunFeedback(context, session: session),
      );
    }
    return (label: l10n.testSessionNextRun, icon: Icons.add, run: (context) => addRun(context, session: session));
  }

  /// Opens the create form, then the form of the first run: a copy of the
  /// bike's current setup (or of the first setup to compare), stamped now. The
  /// session is only recorded once its first run is saved.
  static Future<void> startSession(BuildContext context, {Bike? initialBike}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);

    if (appRepository.bikes.isEmpty) {
      messenger.showSnackBar(AppSnackBar.error(context, context.l10n.testSessionBikeRequired));
      return;
    }
    if (!appRepository.components.values.any((component) => component.adjustments.isNotEmpty) &&
        !appRepository.persons.values.any((person) => person.adjustments.isNotEmpty)) {
      messenger.showSnackBar(AppSnackBar.error(context, context.l10n.testSessionAdjustmentRequired));
      return;
    }

    final session = await Navigator.push<TestSession>(
      context,
      MaterialPageRoute(
        builder: (context) => TestSessionPage(initialBike: initialBike),
      ),
    );
    if (session == null) return;

    final source = _firstRunSource(appRepository, session);
    if (source == null || !context.mounted) return;
    final carryOver = session.method is Tournament ? await CarryOverActions.confirm(context, setup: source) : null;
    if (!context.mounted) return;
    final firstRun = await Navigator.push<Setup>(
      context,
      MaterialPageRoute(
        builder: (context) => SetupPage.nextRun(
          run: _run(context, source: source, session: session, number: 1, carryOver: carryOver),
          session: session,
        ),
      ),
    );
    if (firstRun == null) return;

    // A first run ridden before the session was created moves its start.
    final started = firstRun.datetime.isBefore(session.startedAtUTC)
        ? session.copyWith(startedAtUTC: firstRun.datetime, startedAtLocal: firstRun.datetimeLocal)
        : session;
    await appRepository.startTestSession(started, firstRun);
  }

  static Setup _run(
    BuildContext context, {
    required Setup source,
    required TestSession session,
    required int number,
    Map<String, AdjustmentValue> values = const {},
    SetupCarryOver? carryOver,
  }) {
    final dateFormat = context.read<AppSettings>().dateFormat;
    final l10n = context.l10n;
    return TestSessionService.run(
      l10n,
      source: source,
      session: session,
      number: number,
      values: values,
      carryOver: carryOver,
      notes: TestSessionService.runNotes(l10n, source: source, session: session, dateFormat: dateFormat),
    );
  }

  static Setup? _firstRunSource(AppRepository appRepository, TestSession session) {
    final candidates = switch (session.method) {
      Tournament(:final candidateSetupIds) => candidateSetupIds,
      _ => const <String>[],
    };
    if (candidates.isNotEmpty) return appRepository.setups[candidates.first];
    return appRepository.setups[appRepository.resolveSetupId(bikeId: session.bike, atUtc: DateTime.now().toUtc())];
  }

  /// The next run of a running [session]: a copy of [source] (default: the last
  /// run, with the strategy's proposal set) where only the session's knobs can
  /// change. A Compare session copies one of its candidates with every
  /// adjustment locked. Returns the recorded run.
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
    final carryOver = session.method is Tournament ? await CarryOverActions.confirm(context, setup: from) : null;
    if (!context.mounted) return null;

    final run = _run(
      context,
      source: from,
      session: session,
      number: number,
      // A candidate is ridden as it is.
      values: session.method is Tournament ? const {} : proposal?.values ?? const {},
      carryOver: carryOver,
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

  /// The candidates of a Compare session, the [suggestedId] one highlighted.
  static Future<Setup?> _pickCandidate(BuildContext context, TestSession session, {String? suggestedId}) {
    final appRepository = context.read<AppRepository>();
    final candidates = [
      for (final id in (session.method as Tournament).candidateSetupIds) ?appRepository.setups[id],
    ];
    return showPickSetupSheet(
      context,
      title: context.l10n.testSessionPickNextSetup,
      options: candidates,
      suggestedId: suggestedId,
    );
  }

  /// Feedback on the latest run of [session].
  static Future<void> addRunFeedback(BuildContext context, {required TestSession session}) {
    final run = context.read<AppRepository>().setupsInSession(session.id).lastOrNull;
    if (run == null) return Future.value();
    return FeedbackActions.addFeedbackForSetup(context, setup: run);
  }

  /// Freezes the knob at its value in the latest run, or releases it. A Compare
  /// session rides its candidates as they are, so it has nothing to lock.
  static Future<void> toggleLock(
    BuildContext context, {
    required TestSession session,
    required String adjustmentId,
  }) async {
    if (session.method is Tournament) return;
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
      messenger.showSnackBar(AppSnackBar.error(context, context.l10n.testSessionNoValueToLock));
      return;
    }
    await appRepository.setTestSessionLock(session, adjustmentId, value);
  }

  static Future<void> endSession(BuildContext context, {required TestSession session}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    unawaited(HapticFeedback.mediumImpact());
    await appRepository.endTestSession(session);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        l10n.testSessionEndedSnack(session.label(l10n)),
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: l10n.undo,
          onPressed: () async => appRepository.editTestSession(session),
        ),
      ),
    );
  }

  static Future<void> resumeSession(BuildContext context, {required TestSession session}) async {
    final appRepository = context.read<AppRepository>();

    if (!appRepository.canResumeTestSession(session)) {
      ScaffoldMessenger.of(context).showSnackBar(AppSnackBar.error(context, context.l10n.testSessionResumeBlocked));
      return;
    }

    unawaited(HapticFeedback.mediumImpact());
    await appRepository.resumeTestSession(session);
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
    final l10n = context.l10n;

    unawaited(HapticFeedback.mediumImpact());
    final removed = await appRepository.removeTestSessions([session]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        l10n.testSessionMovedToTrash(session.label(l10n)),
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: l10n.undo,
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
      title: context.l10n.testSessionEndFirstTitle,
      content: context.l10n.testSessionEndFirstBody(session.label(context.l10n)),
      trueText: context.l10n.testSessionEndSession,
    );
    if (!end) return false;

    await appRepository.endTestSession(session);
    return true;
  }

  static Future<void> restoreTestSession(BuildContext context, {required TestSession session}) async {
    final appRepository = context.read<AppRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    await appRepository.restoreTestSessions([session]);

    if (!context.mounted) return;
    messenger.showSnackBar(
      AppSnackBar.info(
        context,
        l10n.testSessionRestoredFromTrash(session.label(l10n)),
        duration: const Duration(seconds: 5),
        action: AppSnackBarAction(
          label: l10n.undo,
          onPressed: () async => appRepository.removeTestSessions([session]),
        ),
      ),
    );
  }
}
