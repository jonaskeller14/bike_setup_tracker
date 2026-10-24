import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/feedback/custom_issue.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_comparison.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/feedback/test_session_method.dart';
import 'package:bike_setup_tracker/services/test_session/orthogonal_array_strategy.dart';
import 'package:bike_setup_tracker/services/test_session/pattern_search_strategy.dart';
import 'package:bike_setup_tracker/services/test_session/strategy_knob.dart';
import 'package:bike_setup_tracker/services/test_session/suggestion_result.dart';
import 'package:bike_setup_tracker/services/test_session/test_session_strategy.dart';
import 'package:bike_setup_tracker/services/test_session/tournament_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

import 'simulation.dart';

void main() {
  const frontCalm = EndAspect(FeedbackEnd.front, FeedbackAttribute.calm);
  const rearGrip = EndAspect(FeedbackEnd.rear, FeedbackAttribute.grip);
  final armPump = CustomAspect(CustomIssue.slugOf('Arm pump'));

  FeedbackComparison answer(FeedbackAspect aspect, int outcome) =>
      FeedbackComparison(referenceSetupId: 'ref', aspect: aspect, outcome: outcome);

  group('RunComparison.scoreOf (decision per step)', () {
    test('the overall answer decides', () {
      expect(RunComparison.scoreOf([answer(const OverallAspect(), -2), answer(frontCalm, 1)], [frontCalm]), -2);
    });

    test('the goal aspects break an overall "same"', () {
      expect(RunComparison.scoreOf([answer(const OverallAspect(), 0), answer(frontCalm, 1)], [frontCalm]), 1);
      expect(
        RunComparison.scoreOf(
          [answer(const OverallAspect(), 0), answer(frontCalm, 1), answer(rearGrip, -1), answer(armPump, -1)],
          [frontCalm, rearGrip, armPump],
        ),
        -1,
      );
    });

    test('custom aspects count, aspects outside the goal do not', () {
      expect(RunComparison.scoreOf([answer(const OverallAspect(), 0), answer(armPump, 1)], [armPump]), 1);
      expect(RunComparison.scoreOf([answer(const OverallAspect(), 0), answer(rearGrip, 1)], [frontCalm]), 0);
    });

    test('equal when overall and goal sum are both zero', () {
      expect(
        RunComparison.scoreOf([answer(const OverallAspect(), 0), answer(frontCalm, 1), answer(rearGrip, -1)], [
          frontCalm,
          rearGrip,
        ]),
        0,
      );
    });

    test('the goal decides without an overall answer; nothing answered is null', () {
      expect(RunComparison.scoreOf([answer(frontCalm, -1)], [frontCalm]), -1);
      expect(RunComparison.scoreOf([answer(rearGrip, -1)], [frontCalm]), isNull);
      expect(RunComparison.scoreOf(const [], [frontCalm]), isNull);
    });
  });

  group('TestSessionStrategy.of', () {
    test('one strategy per method, none for a free session', () {
      expect(TestSessionStrategy.of(const PatternSearch()), isA<PatternSearchStrategy>());
      expect(TestSessionStrategy.of(const OrthogonalArray()), isA<OrthogonalArrayStrategy>());
      expect(TestSessionStrategy.of(const Tournament(candidateSetupIds: ['a', 'b'])), isA<TournamentStrategy>());
      expect(TestSessionStrategy.of(null), isNull);
    });
  });

  group('SuggestionResult states', () {
    TestSessionHistory history({
      TestSession? session,
      Map<String, Adjustment>? adjustments,
      Map<String, AdjustmentValue>? values,
      bool rated = true,
    }) {
      final first = run('r0', values ?? {'a': const StepValue(10)});
      return TestSessionHistory(
        session: session ?? testSession(method: const PatternSearch(), knobs: ['a']),
        adjustments: adjustments ?? {'a': stepKnob('a')},
        runs: [first],
        ratedRunIds: rated ? {'r0'} : const {},
        comparisons: const [],
      );
    }

    const strategy = PatternSearchStrategy();

    test('no feedback on the latest run yet', () {
      expect(strategy.propose(history(rated: false)), const NoSuggestion('Add feedback on Run 1 first.'));
    });

    test('an ended session', () {
      expect(
        strategy.propose(history(session: testSession(method: const PatternSearch(), knobs: ['a'], ended: true))),
        isA<NoSuggestion>(),
      );
    });

    test('every knob locked', () {
      expect(
        strategy.propose(
          history(
            session: testSession(method: const PatternSearch(), knobs: ['a'], locks: {'a': const StepValue(10)}),
          ),
        ),
        const NoSuggestion('Every adjustment is locked.'),
      );
    });

    test('a knob that is no longer installed', () {
      expect(strategy.propose(history(adjustments: const {})), isA<InvalidData>());
    });

    test('an unresolved catalog max', () {
      expect(
        strategy.propose(history(adjustments: {'a': stepKnob('a', notes: StepAdjustment.unknownMaxWarning)})),
        isA<InvalidData>().having((r) => r.error, 'error', contains('placeholder')),
      );
    });

    test('a value out of range', () {
      expect(strategy.propose(history(values: {'a': const StepValue(25)})), isA<InvalidData>());
    });

    test('a knob the strategies cannot move is left alone', () {
      final multi = CategoricalAdjustment(
        id: 'm',
        name: 'Tokens',
        notes: null,
        unit: null,
        options: const {'x', 'y'},
        multiSelect: true,
      );
      final result = strategy.propose(
        history(
          session: testSession(method: const PatternSearch(), knobs: ['m', 'a']),
          adjustments: {'m': multi, 'a': stepKnob('a')},
          values: {
            'm': CategoricalValue(const ['x', 'y']),
            'a': const StepValue(10),
          },
        ),
      );
      expect(result, isA<Proposal>().having((p) => p.values.keys, 'keys', ['a']));
    });
  });

  group('TestSessionHistory.collect', () {
    RideFeedback feedback(String setupId, List<FeedbackComparison> comparisons) => RideFeedback(
      bike: 'bike',
      setupId: setupId,
      dateTimeUTC: DateTime.utc(2026, 5, 2, 12),
      dateTimeLocal: DateTime(2026, 5, 2, 12),
      comparisons: comparisons.toSet(),
    );

    test('scores each reference with the goal of the rated run and pools other sessions', () {
      final session = TestSession(
        id: 'ts',
        bike: 'bike',
        method: const PatternSearch(),
        adjustmentIds: const ['a'],
        goal: const [frontCalm],
        startedAtUTC: DateTime.utc(2026, 5, 2),
        startedAtLocal: DateTime(2026, 5, 2),
      );
      final old = testSession(method: null, knobs: ['a'], id: 'old');
      final setups = {
        for (final s in [
          run('p0', {'a': const StepValue(1)}, sessionId: 'old'),
          run('p1', {'a': const StepValue(2)}, sessionId: 'old', index: 1),
          run('r0', {'a': const StepValue(10)}, index: 2),
          run('r1', {'a': const StepValue(12)}, index: 3),
          run('r2', {'a': const StepValue(14)}, index: 4),
          run('x', {'a': const StepValue(14)}, sessionId: 'elsewhere', index: 5),
        ])
          s.id: s,
      };
      final feedbacks = {
        'p1': [
          feedback('p1', const [FeedbackComparison(referenceSetupId: 'p0', aspect: OverallAspect(), outcome: 2)]),
        ],
        'r0': [feedback('r0', const [])],
        'r1': [
          feedback('r1', const [
            FeedbackComparison(referenceSetupId: 'r0', aspect: OverallAspect(), outcome: 0),
            FeedbackComparison(referenceSetupId: 'r0', aspect: frontCalm, outcome: 1),
            // A setup outside the bike's sessions is no run.
            FeedbackComparison(referenceSetupId: 'x', aspect: OverallAspect(), outcome: 1),
          ]),
        ],
        'r2': [
          feedback('r2', const [FeedbackComparison(referenceSetupId: 'r1', aspect: OverallAspect(), outcome: -1)]),
        ],
      };

      final history = TestSessionHistory.collect(
        session: session,
        sessions: [session, old],
        setups: setups,
        feedbacksForSetup: (id) => feedbacks[id] ?? const [],
        adjustments: {'a': stepKnob('a')},
      );

      expect(history.runs.map((r) => r.id), ['r0', 'r1', 'r2']);
      expect(history.pooledRuns.map((r) => r.id), ['p0', 'p1']);
      expect(history.ratedRunIds, {'p1', 'r0', 'r1', 'r2'});
      expect(history.comparisons, const [
        RunComparison(ratedId: 'p1', referenceId: 'p0', score: 2),
        RunComparison(ratedId: 'r1', referenceId: 'r0', score: 1),
        RunComparison(ratedId: 'r2', referenceId: 'r1', score: -1),
      ]);
      expect(history.verdict('r0', 'r1'), -1);

      final earlier = TestSessionHistory.collect(
        session: session,
        sessions: [session, old],
        setups: setups,
        feedbacksForSetup: (id) => feedbacks[id] ?? const [],
        adjustments: {'a': stepKnob('a')},
        before: setups['r2'],
      );
      expect(earlier.runs.map((r) => r.id), ['r0', 'r1']);
      expect(earlier.comparisons.map((c) => c.ratedId), ['p1', 'r1']);
    });
  });

  group('StrategyKnob', () {
    test('numerical steps follow the unit, the range or the value', () {
      NumericalAdjustment numerical({AdjustmentUnit? unit, double? min, double? max}) =>
          NumericalAdjustment(name: 'n', notes: null, unit: unit, min: min, max: max);

      expect(
        StrategyKnob.numericalUnit(
          numerical(unit: const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'bar')),
          null,
        ),
        0.1,
      );
      expect(StrategyKnob.numericalUnit(numerical(unit: const CustomUnit('turns')), null), 0.25);
      expect(StrategyKnob.numericalUnit(numerical(min: 0, max: 50), null), 2);
      expect(StrategyKnob.numericalUnit(numerical(), 180), 10);
      expect(StrategyKnob.numericalUnit(numerical(), null), 1);
    });

    test('rounds numerical moves without float noise and snaps steps to the grid', () {
      final bar = StrategyKnob.of(
        NumericalAdjustment(
          name: 'Pressure',
          notes: null,
          unit: const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'bar'),
        ),
        reference: const NumericalValue(1.7),
      )!;
      expect(bar.valueAt(1.7 + 3 * bar.unit), const NumericalValue(2.0));

      final clicks = StrategyKnob.of(stepKnob('a', min: 1, max: 10, step: 3))!;
      expect(clicks.valueAt(5.6), const StepValue(7));
      expect(clicks.valueAt(99), const StepValue(10));
      expect(clicks.describe(4, 7), 'a +3');
    });
  });
}
