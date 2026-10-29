import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                  null => 'This session has no runs. Record one to go on.',
                  _ when rated => "${latest.displayName} is rated. Ready for the next run.",
                  _ => "Ride ${latest.displayName}, then tell how it went.",
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
                label: const Text('Next run'),
              )
            else
              FilledButton.icon(
                onPressed: () => unawaited(TestSessionActions.addRunFeedback(context, session: session)),
                icon: const Icon(RideFeedback.iconData),
                label: const Text('Add feedback'),
              ),
            TextButton(
              onPressed: () => unawaited(TestSessionActions.endSession(context, session: session)),
              child: const Text('End session'),
            ),
          ],
        ),
      ],
    );
  }
}
