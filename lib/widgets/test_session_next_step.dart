import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/feedback/ride_feedback.dart';
import '../models/feedback/test_session.dart';
import '../repositories/app_repository.dart';
import '../utils/test_session_actions.dart';

/// The one step a running session waits for: feedback on its latest run, then
/// the next run. Saving an empty feedback skips the questions.
class TestSessionNextStep extends StatelessWidget {
  final TestSession session;

  const TestSessionNextStep({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    if (!session.isRunning) return const SizedBox.shrink();
    final appRepository = context.watch<AppRepository>();
    final latest = appRepository.setupsInSession(session.id).lastOrNull;
    // Without runs (all removed) the next run starts the session over.
    final rated = latest == null || appRepository.feedbacksForSetup(latest.id).isNotEmpty;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Icon(rated ? Icons.check_circle_outline : Icons.directions_bike, size: 18, color: theme.colorScheme.primary),
            Expanded(
              child: Text(
                switch (latest) {
                  null => context.l10n.testSessionStepNoRuns,
                  _ when rated => context.l10n.testSessionStepRated(latest.displayName),
                  _ => context.l10n.testSessionStepRide(latest.displayName),
                },
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (rated)
              FilledButton.icon(
                onPressed: () => unawaited(TestSessionActions.addRun(context, session: session)),
                icon: const Icon(Icons.add),
                label: Text(context.l10n.testSessionNextRun),
              )
            else
              FilledButton.icon(
                onPressed: () => unawaited(TestSessionActions.addRunFeedback(context, session: session)),
                icon: const Icon(RideFeedback.iconData),
                label: Text(context.l10n.feedbackAddButton),
              ),
            TextButton(
              onPressed: () => unawaited(TestSessionActions.endSession(context, session: session)),
              child: Text(context.l10n.testSessionEndSession),
            ),
          ],
        ),
      ],
    );
  }
}
