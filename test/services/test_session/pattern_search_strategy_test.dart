import 'dart:math' as math;

import 'package:bike_setup_tracker/l10n/enum_labels.dart';
import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/feedback/test_session_method.dart';
import 'package:bike_setup_tracker/services/test_session/pattern_search_strategy.dart';
import 'package:bike_setup_tracker/services/test_session/session_progress.dart';
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
      expect(proposal.rationale.text(englishL10n), contains('b +3'));
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

  group('PatternSearchStrategy.progress', () {
    test('counts down run by run while the first run stays the best', () {
      final simulation = oneKnob(start: 10, optimum: 10);

      // Polls at 3, 2 and 1 clicks, both ways, then the confirmation.
      expect(strategy.progress(simulation.history), const SessionProgress(ridden: 1, left: 7, maxLeft: null));

      final steps = simulation.playWithProgress();
      expect(steps.map((step) => step.before.left), [7, 6, 5, 4, 3, 2, 1]);
      expect(steps.every((step) => step.actual == step.before.left), isTrue);
    });

    test('the last run confirms the best one, and nothing is open any more', () {
      final simulation = oneKnob(start: 10, optimum: 10);

      final last = simulation.playWithProgress().last;

      expect(last.before, const SessionProgress.exact(ridden: 7, left: 1, confirming: true));
      expect(last.waiting, const SessionProgress(ridden: 8, pending: true, left: 0, maxLeft: 0, confirming: true));
      expect(strategy.progress(simulation.history), const SessionProgress.exact(ridden: 8, left: 0));
    });

    test('a better run keeps the count up while the ridden runs keep growing', () {
      final simulation = oneKnob(start: 5, optimum: 16);

      final steps = simulation.playWithProgress();

      // 5 → 8 → 11 → 14 → 17: every better run moves the polls along.
      expect(steps.map((step) => step.before.left).take(6), [7, 6, 6, 6, 6, 5]);
      expect(steps.map((step) => step.before.ridden), [for (var i = 1; i <= steps.length; i++) i]);
    });

    test('a better run at the smallest step saves the poll on its other side', () {
      final simulation = oneKnob(start: 10, optimum: 14);

      final steps = simulation.playWithProgress();

      // 14 beats 13 with 13 and 15 ridden already, so 12 is never polled.
      expect(steps.map((step) => step.before.left), [7, 6, 5, 4, 3, 1]);
    });

    test('polls every knob at every step size', () {
      final simulation = Simulation(
        strategy: strategy,
        session: testSession(method: const PatternSearch(), knobs: ['a', 'b']),
        knobs: [stepKnob('a'), stepKnob('b')],
        start: {'a': const StepValue(10), 'b': const StepValue(10)},
        preference: (v) => -((stepOf(v, 'a') - 10).abs() + (stepOf(v, 'b') - 10).abs()).toDouble(),
      );

      expect(strategy.progress(simulation.history), const SessionProgress(ridden: 1, left: 13, maxLeft: null));
      expect(simulation.playWithProgress().length, 13);
    });

    test('steps an earlier session could not feel are left out', () {
      final simulation = oneKnob(start: 10, optimum: 10);
      final history = TestSessionHistory(
        session: simulation.session,
        adjustments: simulation.adjustments,
        runs: simulation.runs,
        ratedRunIds: const {'r0'},
        pooledRuns: [
          run('p0', {'a': const StepValue(10)}, sessionId: 'old'),
          run('p1', {'a': const StepValue(11)}, sessionId: 'old', index: 1),
          run('p2', {'a': const StepValue(12)}, sessionId: 'old', index: 2),
        ],
        comparisons: const [
          RunComparison(ratedId: 'p1', referenceId: 'p0', score: 0),
          RunComparison(ratedId: 'p2', referenceId: 'p1', score: 0),
        ],
      );

      // One click felt the same twice: polls at 3 and 2 clicks only.
      expect(strategy.progress(history)!.left, 5);
    });

    test('stays close below the runs really left, for every kind of rider', () {
      // (clicks felt per click of distance, noise, optimum at the end of the range)
      const riders = [(1.0, 0.0, false), (1.0, 0.0, true), (1.0, 0.8, false), (0.3, 0.0, false), (0.15, 0.0, false)];
      final random = math.Random(7);
      for (final (slope, noise, atEnd) in riders) {
        for (final ids in [
          ['a'],
          ['a', 'b'],
        ]) {
          for (var seed = 1; seed <= 30; seed++) {
            final optimum = [for (final _ in ids) atEnd ? 20 : 4 + random.nextInt(13)];
            final simulation = Simulation(
              strategy: strategy,
              session: testSession(method: const PatternSearch(), knobs: ids),
              knobs: [for (final id in ids) stepKnob(id)],
              start: {for (final id in ids) id: StepValue(4 + random.nextInt(13))},
              preference: (v) => [
                for (var k = 0; k < ids.length; k++) -slope * (stepOf(v, ids[k]) - optimum[k]).abs(),
              ].fold(0.0, (a, b) => a + b),
              noise: noise,
              seed: seed,
            );
            // A rider who feels every click and has room around the optimum
            // saves at most the one poll of the test above. Steps too fine to
            // feel and the end of a range save up to two polls per knob.
            final slack = slope == 1 && noise == 0 && !atEnd ? 1 : 2 * ids.length;
            for (final (:before, :waiting, :actual) in simulation.playWithProgress()) {
              final reason = 'slope $slope, noise $noise, at end $atEnd, ${ids.length} knobs, seed $seed, $before';
              expect(actual, greaterThanOrEqualTo(before.left - slack), reason: reason);
              expect(waiting, before.awaitingFeedback, reason: reason);
            }
            expect(strategy.propose(simulation.history), isA<Converged>());
            expect(strategy.progress(simulation.history)!.isDone, isTrue);
          }
        }
      }
    });
  });
}
