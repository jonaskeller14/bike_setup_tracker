import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../models/feedback/test_session.dart';
import '../models/feedback/test_session_method.dart';
import '../models/setup.dart';
import '../repositories/app_repository.dart';
import '../services/dangling_adjustment_service.dart';
import '../services/test_session/suggestion_result.dart';
import '../services/test_session_service.dart';
import '../utils/test_session_actions.dart';
import 'dashed_border_painter.dart';
import 'lists/adjustment_compact_display/adjustment_compact_display_list.dart';

/// Below the runs of a running session: the run the strategy suggests next as
/// a ghost item, the best run once nothing is left to try, or what blocks the
/// strategy. Nothing while it waits for feedback or for a free session.
class TestSessionSuggestion extends StatelessWidget {
  final TestSession session;

  const TestSessionSuggestion({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    if (!session.isRunning) return const SizedBox.shrink();
    final appRepository = context.watch<AppRepository>();
    final theme = Theme.of(context);
    final runs = appRepository.setupsInSession(session.id);

    return switch (appRepository.suggestionFor(session.id)) {
      final Proposal proposal when runs.isNotEmpty => _ghostRun(context, appRepository, proposal),
      Converged(:final bestSetupId, :final drift) => _converged(
        context,
        // A Compare session names a candidate; the run that rode it is shown beside it.
        best: appRepository.setups[bestSetupId],
        run: session.method is Tournament
            ? runs.reversed.where((run) => run.sourceSetupId == bestSetupId).firstOrNull
            : null,
        summary: switch (session.method) {
          PatternSearch() => 'Fine-tuning converged. Nothing left to try.',
          OrthogonalArray() => 'Exploring converged. Nothing left to try.',
          _ => 'Comparing converged. Nothing left to try.',
        },
        drift: drift,
      ),
      InvalidData(:final error) => _notice(
        context,
        icon: Icons.error_outline,
        color: theme.colorScheme.error,
        text: error,
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _ghostRun(BuildContext context, AppRepository appRepository, Proposal proposal) {
    final theme = Theme.of(context);
    final runs = appRepository.setupsInSession(session.id);
    final last = runs.last;
    final next = TestSessionService.run(
      source: last,
      session: session,
      number: runs.length + 1,
      values: proposal.values,
    );
    final breakdown = DanglingAdjustmentService.analyzeSetup(
      setup: next,
      components: appRepository.components.values,
      persons: appRepository.persons.values,
    );
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: theme.colorScheme.outlineVariant,
          strokeWidth: 1.5,
          dashWidth: 6,
          dashSpace: 4,
          borderRadius: 12,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => unawaited(TestSessionActions.addRun(context, session: session)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    spacing: 8,
                    children: [
                      Icon(Icons.tips_and_updates_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                      Expanded(
                        child: Text(
                          '${next.displayName} · Suggested',
                          style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(proposal.rationale, style: mutedStyle),
                ),
                AdjustmentCompactDisplayList(
                  components: breakdown.components,
                  persons: [?breakdown.person],
                  adjustmentValues: {...next.bikeAdjustmentValues, ...next.personAdjustmentValues},
                  previousAdjustmentValues: {...last.bikeAdjustmentValues, ...last.personAdjustmentValues},
                  showRowIcons: true,
                  displayOnlyChanges: true,
                  displayPersonAdjustmentValues: context.read<AppSettings>().enablePerson,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The winner as a card: fades in while the trophy pops, once.
  Widget _converged(
    BuildContext context, {
    required Setup? best,
    required Setup? run,
    required String summary,
    required bool drift,
  }) {
    final theme = Theme.of(context);
    final name = best?.displayName ?? 'The best run';
    final label = session.method is Tournament ? 'Best setup' : 'Best run';
    final onContainer = theme.colorScheme.onPrimaryContainer;
    final animate = !MediaQuery.disableAnimationsOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: animate ? const Duration(milliseconds: 500) : Duration.zero,
        curve: Curves.easeOut,
        builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Row(
                spacing: 16,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: animate ? const Duration(milliseconds: 900) : Duration.zero,
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                    child: Icon(Icons.emoji_events, size: 40, color: onContainer),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(color: onContainer, letterSpacing: 1.2),
                        ),
                        Text(
                          name,
                          style: theme.textTheme.titleLarge?.copyWith(color: onContainer, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (run != null)
                          Text(
                            '(${run.displayName})',
                            style: theme.textTheme.bodyMedium?.copyWith(color: onContainer),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(summary, style: theme.textTheme.bodyMedium?.copyWith(color: onContainer)),
                      ],
                    ),
                  ),
                ],
              ),
              if (drift)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Icon(Icons.warning_amber_outlined, size: 18, color: onContainer),
                    Expanded(
                      child: Text(
                        'Ridden again, it lost against a run it had beaten: the trail or you may have changed.',
                        style: theme.textTheme.bodySmall?.copyWith(color: onContainer),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notice(BuildContext context, {required IconData icon, required Color color, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Icon(icon, size: 18, color: color),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
