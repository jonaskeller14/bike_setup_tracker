import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/feedback/test_session_method.dart';
import 'package:bike_setup_tracker/services/test_session/pattern_search_strategy.dart';
import 'package:bike_setup_tracker/services/test_session/suggestion_result.dart';
import 'package:bike_setup_tracker/services/test_session/test_session_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

import 'simulation.dart';

void main() {
  const strategy = PatternSearchStrategy();

  Simulation oneKnob({required int start, required int optimum, double noise = 0, int seed = 1}) => Simulation(
    strategy: strategy,
    session: testSession(method: const PatternSearch(), knobs: ['a']),
    knobs: [stepKnob('a')],
    start: {'a': StepValue(start)},
    preference: (values) => -(stepOf(values, 'a') - optimum).abs().toDouble(),
    noise: noise,
    seed: seed,
  );

  group('PatternSearchStrategy', () {
    test('keeps its result once the session has ended', () {
      final simulation = oneKnob(start: 2, optimum: 7);
      final converged = simulation.play() as Converged;

      final ended = TestSessionHistory(
        session: testSession(method: const PatternSearch(), knobs: ['a'], ended: true),
        adjustments: simulation.adjustments,
        runs: simulation.runs,
        ratedRunIds: {for (final run in simulation.runs) run.id},
        comparisons: simulation.comparisons,
      );

      expect(strategy.propose(ended), converged);
    });

    test('converges on one knob by bracketing the optimum', () {
      final simulation = oneKnob(start: 2, optimum: 7);

      final result = simulation.play();

      expect(result, isA<Converged>());
      final best = simulation.valuesOf((result as Converged).bestSetupId);
      expect(stepOf(best, 'a'), 7);
      expect(result.drift, isFalse);
      // Bracketed: both neighbours at the smallest step were ridden and lost.
      final ridden = simulation.runs.map((r) => stepOf(r.bikeAdjustmentValues, 'a')).toSet();
      expect(ridden, containsAll([6, 8]));
      // The last run repeats the best one (A-B-A).
      expect(stepOf(simulation.runs.last.bikeAdjustmentValues, 'a'), 7);
      expect(simulation.runs.length, lessThanOrEqualTo(12));
    });

    test('moves further after a success and halves the step when nothing helps', () {
      final simulation = oneKnob(start: 2, optimum: 15);

      simulation.play();

      final ridden = [for (final r in simulation.runs) stepOf(r.bikeAdjustmentValues, 'a')];
      // 15 % of the range is 3 clicks: 2 → 5 → 8 (pattern move) → …
      expect(ridden.take(3), [2, 5, 8]);
      expect(ridden, contains(15));
    });

    test('converges on two knobs', () {
      final simulation = Simulation(
        strategy: strategy,
        session: testSession(method: const PatternSearch(), knobs: ['a', 'b']),
        knobs: [stepKnob('a'), stepKnob('b')],
        start: {'a': const StepValue(2), 'b': const StepValue(10)},
        preference: (v) => -((stepOf(v, 'a') - 6).abs() + (stepOf(v, 'b') - 13).abs()).toDouble(),
      );

      final result = simulation.play();

      expect(result, isA<Converged>());
      final best = simulation.valuesOf((result as Converged).bestSetupId);
      expect((stepOf(best, 'a'), stepOf(best, 'b')), (6, 13));
    });

    test('lands near the optimum with noisy answers', () {
      for (var seed = 1; seed <= 5; seed++) {
        final simulation = oneKnob(start: 3, optimum: 12, noise: 0.45, seed: seed);
        final result = simulation.play();
        expect(result, isA<Converged>(), reason: 'seed $seed');
        final best = stepOf(simulation.valuesOf((result as Converged).bestSetupId), 'a');
        expect((best - 12).abs(), lessThanOrEqualTo(2), reason: 'seed $seed');
      }
    });

    test('stays within the range and on the step grid', () {
      final simulation = Simulation(
        strategy: strategy,
        session: testSession(method: const PatternSearch(), knobs: ['a']),
        knobs: [stepKnob('a', min: 0, max: 10, step: 2)],
        start: {'a': const StepValue(0)},
        preference: (v) => -stepOf(v, 'a').toDouble(),
      );

      final result = simulation.play();

      for (final r in simulation.runs) {
        final value = stepOf(r.bikeAdjustmentValues, 'a');
        expect(value, inInclusiveRange(0, 10));
        expect(value.isEven, isTrue);
      }
      expect(stepOf(simulation.valuesOf((result as Converged).bestSetupId), 'a'), 0);
    });

    test('polls the knobs in session order, up first, without earlier evidence', () {
      final simulation = Simulation(
        strategy: strategy,
        session: testSession(method: const PatternSearch(), knobs: ['b', 'a']),
        knobs: [stepKnob('a'), stepKnob('b')],
        start: {'a': const StepValue(10), 'b': const StepValue(10)},
        preference: (v) => 0,
      );

      final proposal = strategy.propose(simulation.history) as Proposal;

      expect(proposal.values, {'b': const StepValue(13), 'a': const StepValue(10)});
      expect(proposal.referenceSetupId, 'r0');
      expect(proposal.rationale, contains('b +3'));
    });

    test('never moves a locked knob', () {
      final simulation = Simulation(
        strategy: strategy,
        session: testSession(
          method: const PatternSearch(),
          knobs: ['a', 'b'],
          locks: {'a': const StepValue(4)},
        ),
        knobs: [stepKnob('a'), stepKnob('b')],
        start: {'a': const StepValue(4), 'b': const StepValue(10)},
        preference: (v) => -(stepOf(v, 'b') - 14).abs().toDouble(),
      );

      simulation.play();

      for (final result in simulation.results.whereType<Proposal>()) {
        expect(result.values.keys, ['b']);
      }
      expect(simulation.runs.every((r) => stepOf(r.bikeAdjustmentValues, 'a') == 4), isTrue);
    });

    test('uses the values actually set when a run deviates', () {
      final simulation = oneKnob(start: 2, optimum: 9);
      // The rider sets 6 instead of the proposed 5.
      simulation.play(maxRuns: 2, deviate: (proposal) => {'a': const StepValue(6)});

      final proposal = strategy.propose(simulation.history) as Proposal;

      // 6 beat 2, so the pattern move goes on from 6 by the actual move (+4).
      expect(proposal.baseSetupId, 'r1');
      expect(proposal.values, {'a': const StepValue(10)});
    });

    test('flips a boolean knob and walks a categorical one', () {
      final lockout = BooleanAdjustment(id: 'lock', name: 'Lockout', notes: null, unit: null);
      final mode = CategoricalAdjustment(
        id: 'mode',
        name: 'Mode',
        notes: null,
        unit: null,
        options: const {'Open', 'Trail', 'Firm'},
      );
      final simulation = Simulation(
        strategy: strategy,
        session: testSession(method: const PatternSearch(), knobs: ['lock', 'mode']),
        knobs: [lockout, mode],
        start: {
          'lock': const BooleanValue(false),
          'mode': CategoricalValue(const ['Open']),
        },
        preference: (v) =>
            ((v['lock'] as BooleanValue).value ? 1.0 : 0.0) +
            const {'Open': 0.0, 'Trail': 1.0, 'Firm': 2.0}[(v['mode'] as CategoricalValue).options.single]!,
      );

      final result = simulation.play();

      final best = simulation.valuesOf((result as Converged).bestSetupId);
      expect(best['lock'], const BooleanValue(true));
      expect(best['mode'], CategoricalValue(const ['Firm']));
    });

    test('flags drift when the best run, ridden again, loses against a run it beat', () {
      final simulation = oneKnob(start: 10, optimum: 10);
      // Ride until the repeat of the best run is proposed.
      var result = simulation.play(maxRuns: 100);
      expect(result, isA<Converged>());
      final repeat = simulation.runs.last;
      final previous = simulation.runs[simulation.runs.length - 2];
      // The trail changed: the repeat now loses against the run before it.
      simulation.comparisons
        ..removeLast()
        ..add(RunComparison(ratedId: repeat.id, referenceId: previous.id, score: -1));

      result = strategy.propose(simulation.history);

      expect(result, isA<Converged>().having((c) => c.drift, 'drift', isTrue));
    });

    test('raises the step of a knob the rider repeatedly cannot feel', () {
      final simulation = oneKnob(start: 10, optimum: 10);
      // An earlier session: one click either way felt the same, twice.
      final earlier = [
        run('p0', {'a': const StepValue(10)}, sessionId: 'old'),
        run('p1', {'a': const StepValue(11)}, sessionId: 'old', index: 1),
        run('p2', {'a': const StepValue(12)}, sessionId: 'old', index: 2),
      ];
      final history = TestSessionHistory(
        session: simulation.session,
        adjustments: simulation.adjustments,
        runs: simulation.runs,
        ratedRunIds: const {'r0'},
        pooledRuns: earlier,
        comparisons: const [
          RunComparison(ratedId: 'p1', referenceId: 'p0', score: 0),
          RunComparison(ratedId: 'p2', referenceId: 'p1', score: 0),
        ],
      );

      final knob = TestSessionStrategy.movableKnobs(history).knobs.single;

      expect(TestSessionStrategy.minNoticeableStep(knob, history), 2);
    });
  });
}
