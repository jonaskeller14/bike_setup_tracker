import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/feedback/test_session_method.dart';
import 'package:bike_setup_tracker/services/test_session/knob_effect_model.dart';
import 'package:bike_setup_tracker/services/test_session/orthogonal_array_strategy.dart';
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
      expect(proposal.rationale, contains('again'));
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
}
