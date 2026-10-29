import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/feedback/test_session_method.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/services/test_session/suggestion_result.dart';
import 'package:bike_setup_tracker/services/test_session/test_session_strategy.dart';
import 'package:bike_setup_tracker/services/test_session/tournament_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

import 'simulation.dart';

void main() {
  const strategy = TournamentStrategy();

  /// Candidates c0 … c(n−1) that differ in knob `a` (value = index).
  Simulation field(List<double> strengths) {
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
      expect(simulation.results.whereType<Proposal>().last.rationale, contains('level'));
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
}
