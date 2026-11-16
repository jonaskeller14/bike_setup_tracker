import 'dart:math' as math;

import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/feedback/test_session_method.dart';
import 'package:bike_setup_tracker/services/test_session/knob_effect_model.dart';
import 'package:bike_setup_tracker/services/test_session/orthogonal_array_strategy.dart';
import 'package:bike_setup_tracker/services/test_session/session_progress.dart';
import 'package:bike_setup_tracker/services/test_session/suggestion_result.dart';
import 'package:bike_setup_tracker/services/test_session/test_session_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

import 'simulation.dart';

void main() {
  const strategy = OrthogonalArrayStrategy();
  const ids = ['a', 'b', 'c', 'd'];

  /// Linear preference per 5 clicks (the pattern's step on a 0–20 knob).
  Simulation fourKnobs(List<double> effects, {double noise = 0, int seed = 1}) => Simulation(
    strategy: strategy,
    session: testSession(method: const OrthogonalArray(), knobs: ids),
    knobs: [for (final id in ids) stepKnob(id)],
    start: {for (final id in ids) id: const StepValue(10)},
    preference: (v) => [
      for (var k = 0; k < ids.length; k++) effects[k] * (stepOf(v, ids[k]) - 10) / 5,
    ].fold(0.0, (a, b) => a + b),
    noise: noise,
    seed: seed,
  );

  group('patternRows', () {
    test('balanced columns first, the all-plus column last', () {
      expect(OrthogonalArrayStrategy.patternRows(1), [
        [1],
        [-1],
      ]);
      expect(OrthogonalArrayStrategy.patternRows(4), [
        [1, 1, 1, 1],
        [-1, 1, -1, 1],
        [1, -1, -1, 1],
        [-1, -1, 1, 1],
      ]);
      final rows = OrthogonalArrayStrategy.patternRows(6);
      expect(rows.length, 8);
      for (var c = 0; c < 6; c++) {
        expect(rows.map((r) => r[c]).fold(0, (a, b) => a + b), 0);
      }
    });
  });

  group('OrthogonalArrayStrategy', () {
    test('moves every knob by a quarter of its range in each pattern run', () {
      final simulation = fourKnobs([0.8, -0.8, 0.5, -0.5]);

      simulation.play(maxRuns: 5);

      final patterns = simulation.runs.skip(1).map((r) => [for (final id in ids) stepOf(r.bikeAdjustmentValues, id)]);
      expect(patterns, [
        [15, 15, 15, 15],
        [5, 15, 5, 15],
        [15, 5, 5, 15],
        [5, 5, 15, 15],
      ]);
    });

    test('recovers the sign of each knob for 4 knobs and converges in 7 runs', () {
      final simulation = fourKnobs([0.8, -0.8, 0.5, -0.5]);

      final result = simulation.play();

      expect(simulation.runs.length, lessThanOrEqualTo(7));
      expect(result, isA<Converged>());
      final model = KnobEffectModel.fit(
        knobs: TestSessionStrategy.movableKnobs(simulation.history).knobs,
        history: simulation.history,
        scales: {for (final id in ids) id: 5},
      );
      expect([for (final id in ids) model.effects[id]!.sign], [1, -1, 1, -1]);
      // Run 6 is the estimated best: every knob moved the helpful way.
      expect([for (final id in ids) stepOf(simulation.runs[5].bikeAdjustmentValues, id)], [15, 5, 15, 5]);
      expect(stepOf(simulation.valuesOf((result as Converged).bestSetupId), 'a'), 15);
    });

    test('recovers the strong effects with noisy answers', () {
      for (var seed = 1; seed <= 5; seed++) {
        final simulation = fourKnobs([1, -1, 0, 0], noise: 0.3, seed: seed)..play(maxRuns: 5);
        final model = KnobEffectModel.fit(
          knobs: TestSessionStrategy.movableKnobs(simulation.history).knobs,
          history: simulation.history,
          scales: {for (final id in ids) id: 5},
        );
        expect(model.effects['a'], greaterThan(0), reason: 'seed $seed');
        expect(model.effects['b'], lessThan(0), reason: 'seed $seed');
      }
    });

    test('confirms with the baseline when the estimate is the best run', () {
      final simulation = fourKnobs([0.8, -0.8, 0.5, -0.5])..play(maxRuns: 6);

      final proposal = strategy.propose(simulation.history) as Proposal;

      expect(proposal.baseSetupId, 'r0');
      expect(proposal.referenceSetupId, 'r5');
      expect(proposal.rationale.kind, SuggestionNoteKind.rideAgainConfirm);
    });

    test('clamps the pattern at the end of the range', () {
      final simulation = Simulation(
        strategy: strategy,
        session: testSession(method: const OrthogonalArray(), knobs: ['a']),
        knobs: [stepKnob('a')],
        start: {'a': const StepValue(18)},
        preference: (v) => 0,
      );

      simulation.play(maxRuns: 3);

      expect([for (final r in simulation.runs) stepOf(r.bikeAdjustmentValues, 'a')], [18, 20, 13]);
    });

    test('flips a boolean and steps a numerical knob in pressure units', () {
      final simulation = Simulation(
        strategy: strategy,
        session: testSession(method: const OrthogonalArray(), knobs: ['lock', 'psi']),
        knobs: [
          BooleanAdjustment(id: 'lock', name: 'Lockout', notes: null, unit: null),
          NumericalAdjustment(
            id: 'psi',
            name: 'Pressure',
            notes: null,
            unit: const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi'),
          ),
        ],
        start: {'lock': const BooleanValue(false), 'psi': const NumericalValue(26.3)},
        preference: (v) => 0,
      );

      simulation.play(maxRuns: 3);

      expect([for (final r in simulation.runs.skip(1)) r.bikeAdjustmentValues], [
        {'lock': const BooleanValue(true), 'psi': const NumericalValue(30.3)},
        {'lock': const BooleanValue(false), 'psi': const NumericalValue(30.3)},
      ]);
    });
  });

  group('OrthogonalArrayStrategy.progress', () {
    Simulation knobs(int count, {List<double>? effects, double noise = 0, int seed = 1, Set<String> locked = const {}}) {
      final ids = ['a', 'b', 'c', 'd', 'e'].take(count).toList();
      return Simulation(
        strategy: strategy,
        session: testSession(
          method: const OrthogonalArray(),
          knobs: ids,
          locks: {for (final id in locked) id: const StepValue(10)},
        ),
        knobs: [for (final id in ids) stepKnob(id)],
        start: {for (final id in ids) id: const StepValue(10)},
        preference: (v) => [
          for (var k = 0; k < ids.length; k++) (effects?[k] ?? 0) * (stepOf(v, ids[k]) - 10) / 5,
        ].fold(0.0, (a, b) => a + b),
        noise: noise,
        seed: seed,
      );
    }

    test('the pattern, then the confirmation, plus the estimated best while it is open', () {
      // 3 knobs: a pattern of 4.
      final simulation = knobs(3, effects: [0.8, -0.8, 0.5]);

      expect(strategy.progress(simulation.history), const SessionProgress(ridden: 1, left: 5, maxLeft: 6));

      simulation.play(maxRuns: 4);
      expect(strategy.progress(simulation.history), const SessionProgress(ridden: 4, left: 2, maxLeft: 3));
    });

    test('is exact from the estimated best on', () {
      final simulation = knobs(3, effects: [0.8, -0.8, 0.5])..play(maxRuns: 5);

      expect(strategy.progress(simulation.history), const SessionProgress.exact(ridden: 5, left: 2));

      simulation.play(maxRuns: 6);
      expect(strategy.progress(simulation.history), const SessionProgress.exact(ridden: 6, left: 1, confirming: true));

      expect(simulation.play(), isA<Converged>());
      final done = strategy.progress(simulation.history)!;
      expect(done, const SessionProgress.exact(ridden: 7, left: 0));
      expect(done.isDone, isTrue);
    });

    test('goes straight to the confirmation when nothing made a difference', () {
      final simulation = knobs(3)..play(maxRuns: 5);

      expect(strategy.progress(simulation.history), const SessionProgress.exact(ridden: 5, left: 1, confirming: true));
    });

    test('one knob never needs the estimated best', () {
      final simulation = knobs(1, effects: [0.8]);

      expect(strategy.progress(simulation.history), const SessionProgress.exact(ridden: 1, left: 3));
      expect(simulation.playWithProgress().map((step) => step.before.left), [3, 2, 1]);
    });

    test('a locked knob shortens the pattern', () {
      // 5 knobs need a pattern of 8, 4 of them one of 4.
      expect(strategy.progress(knobs(5).history)!.left, 9);
      expect(strategy.progress(knobs(5, locked: {'e'}).history)!.left, 5);
    });

    test('the run that waits for its feedback is the confirmation', () {
      final simulation = knobs(3)..play(maxRuns: 6);

      expect(
        strategy.progress(simulation.historyAwaitingFeedback),
        const SessionProgress(ridden: 6, pending: true, left: 0, maxLeft: 0, confirming: true),
      );
    });

    test('the runs really left stay within the estimate, whatever the answers', () {
      final random = math.Random(3);
      for (final count in [1, 2, 3, 5]) {
        for (var seed = 1; seed <= 40; seed++) {
          final effects = [for (var k = 0; k < count; k++) const [0.0, 0.8, -0.8, 0.4, -1.2][random.nextInt(5)]];
          final simulation = knobs(count, effects: effects, noise: 0.6, seed: seed);
          for (final (:before, :waiting, :actual) in simulation.playWithProgress()) {
            final reason = '$count knobs, seed $seed, $before';
            expect(actual, inInclusiveRange(before.left, before.maxLeft!), reason: reason);
            expect(waiting, before.awaitingFeedback, reason: reason);
          }
          expect(strategy.progress(simulation.history)!.isDone, isTrue, reason: '$count knobs, seed $seed');
        }
      }
    });
  });
}
