import 'dart:math' as math;

import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/feedback/test_session_method.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/services/test_session/session_progress.dart';
import 'package:bike_setup_tracker/services/test_session/suggestion_result.dart';
import 'package:bike_setup_tracker/services/test_session/test_session_strategy.dart';
import 'package:bike_setup_tracker/services/test_session/tournament_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

import 'simulation.dart';

void main() {
  const strategy = TournamentStrategy();

  /// Candidates c0 … c(n−1) that differ in knob `a` (value = index).
  Simulation field(List<double> strengths, {double noise = 0, int seed = 1}) {
    final candidates = [
      for (var i = 0; i < strengths.length; i++) run('c$i', {'a': StepValue(i)}, sessionId: 'none', name: 'Setup $i'),
    ];
    return Simulation(
      strategy: strategy,
      session: testSession(
        method: Tournament(candidateSetupIds: [for (final c in candidates) c.id]),
        knobs: ['a'],
      ),
      knobs: [stepKnob('a')],
      start: candidates.first.bikeAdjustmentValues,
      preference: (v) => strengths[stepOf(v, 'a')],
      setups: {for (final c in candidates) c.id: c},
      noise: noise,
      seed: seed,
    );
  }

  Set<(int, int)> comparedPairs(Simulation simulation) {
    int candidate(String runId) => stepOf(simulation.valuesOf(runId), 'a');
    return {
      for (final c in simulation.comparisons)
        if (candidate(c.ratedId) != candidate(c.referenceId))
          (candidate(c.ratedId) < candidate(c.referenceId)
              ? (candidate(c.ratedId), candidate(c.referenceId))
              : (candidate(c.referenceId), candidate(c.ratedId))),
    };
  }

  group('TournamentStrategy', () {
    test('plays a round robin and finds the best of 3', () {
      final simulation = field([0, 2, 1]);

      final result = simulation.play();

      expect(result, const Converged(bestSetupId: 'c1'));
      expect(comparedPairs(simulation), {(0, 1), (0, 2), (1, 2)});
      expect(simulation.runs.length, lessThanOrEqualTo(4));
    });

    test('covers every pair of 4 candidates', () {
      final simulation = field([0, 1, 3, 2]);

      final result = simulation.play();

      expect(result, const Converged(bestSetupId: 'c2'));
      expect(comparedPairs(simulation).length, 6);
    });

    test('compares every one of 6 candidates at least twice', () {
      final simulation = field([0, 1, 2, 5, 3, 4]);

      final result = simulation.play();

      expect(result, const Converged(bestSetupId: 'c3'));
      final counts = <int, int>{};
      for (final (a, b) in comparedPairs(simulation)) {
        counts.update(a, (n) => n + 1, ifAbsent: () => 1);
        counts.update(b, (n) => n + 1, ifAbsent: () => 1);
      }
      expect(counts.values.every((n) => n >= 2), isTrue);
      expect(simulation.runs.length, lessThan(15));
    });

    test('rides a level top two against each other again', () {
      final simulation = field([2, 2, 0]);

      final result = simulation.play();

      expect(result, isA<Converged>());
      expect(simulation.results.whereType<Proposal>().last.rationale.kind, SuggestionNoteKind.levelRideAgain);
      final direct = simulation.comparisons.where((c) {
        final pair = {stepOf(simulation.valuesOf(c.ratedId), 'a'), stepOf(simulation.valuesOf(c.referenceId), 'a')};
        return pair.length == 2 && pair.containsAll([0, 1]);
      });
      expect(direct.length, TournamentStrategy.tieBreakGames);
    });

    test('compares with the run just ridden and copies the candidate', () {
      final simulation = field([0, 1, 2]);

      final proposal = strategy.propose(simulation.history) as Proposal;

      expect(proposal.baseSetupId, 'c1');
      expect(proposal.values, {'a': const StepValue(1)});
      expect(proposal.referenceSetupId, 'r0');
    });

    test('a removed candidate is invalid data', () {
      final simulation = field([0, 1, 2]);
      final history = simulation.history;

      final result = strategy.propose(
        TestSessionHistory(
          session: history.session,
          adjustments: history.adjustments,
          runs: history.runs,
          ratedRunIds: history.ratedRunIds,
          comparisons: history.comparisons,
          setups: Map<String, Setup>.of(history.setups)..remove('c2'),
        ),
      );

      expect(result, isA<InvalidData>());
    });
  });

  group('TournamentStrategy.progress', () {
    test('the walk through the pairs, plus one tie-break at most', () {
      // 2: one pair, its second comparison. 3 and 4: the round robin, then one
      // more comparison of the level two, after bringing one of them up.
      expect(strategy.progress(field([0, 1]).history), const SessionProgress(ridden: 1, left: 1, maxLeft: 2));
      expect(strategy.progress(field([0, 1, 2]).history), const SessionProgress(ridden: 1, left: 3, maxLeft: 5));
      expect(strategy.progress(field([0, 1, 2, 3]).history), const SessionProgress(ridden: 1, left: 7, maxLeft: 9));
    });

    test('a large field rides until every candidate has two comparisons', () {
      // The level two may not have met yet: two comparisons, after bringing one up.
      expect(
        strategy.progress(field([0, 1, 2, 3, 4, 5]).history),
        const SessionProgress(ridden: 1, left: 6, maxLeft: 9),
      );
    });

    test('counts down the walk and ends on a clear winner', () {
      final simulation = field([0, 2, 1]);

      final steps = simulation.playWithProgress();

      expect(steps.map((step) => (step.before.left, step.before.maxLeft)), [(3, 5), (2, 4), (1, 3)]);
      expect(strategy.progress(simulation.history), const SessionProgress.exact(ridden: 4, left: 0));
    });

    test('a level top two needs up to their missing comparisons', () {
      final simulation = field([2, 2, 0]);

      final steps = simulation.playWithProgress();

      // After the round robin c0 and c1 are level and met once; c0 was ridden last.
      expect(steps.last.before, const SessionProgress.exact(ridden: 4, left: 1));
      expect(steps.last.waiting, const SessionProgress(ridden: 5, pending: true, left: 0, maxLeft: 0));
      expect(strategy.progress(simulation.history)!.isDone, isTrue);
    });

    test('nothing once a candidate is gone', () {
      final history = field([0, 1, 2]).history;

      final progress = strategy.progress(
        TestSessionHistory(
          session: history.session,
          adjustments: history.adjustments,
          runs: history.runs,
          ratedRunIds: history.ratedRunIds,
          comparisons: history.comparisons,
          setups: Map<String, Setup>.of(history.setups)..remove('c2'),
        ),
      );

      expect(progress, isNull);
    });

    test('never needs fewer runs than estimated, and rarely more', () {
      final random = math.Random(5);
      var estimates = 0;
      var aboveMax = 0;
      for (final count in [2, 3, 4, 6]) {
        for (var seed = 1; seed <= 60; seed++) {
          // Whole strengths make level candidates common.
          final simulation = field(
            [for (var i = 0; i < count; i++) random.nextInt(3).toDouble()],
            noise: 0.5,
            seed: seed,
          );
          for (final (:before, :waiting, :actual) in simulation.playWithProgress()) {
            final reason = '$count candidates, seed $seed, $before';
            expect(actual, greaterThanOrEqualTo(before.left), reason: reason);
            expect(waiting, before.awaitingFeedback, reason: reason);
            estimates++;
            if (actual > before.maxLeft!) aboveMax++;
          }
          expect(strategy.progress(simulation.history)!.isDone, isTrue, reason: '$count candidates, seed $seed');
        }
      }
      // Only a tie-break that levels a second pair goes past the upper end.
      expect(aboveMax / estimates, lessThan(0.02));
    });
  });
}
