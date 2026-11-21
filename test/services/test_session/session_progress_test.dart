import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/feedback/test_session_method.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/services/test_session/orthogonal_array_strategy.dart';
import 'package:bike_setup_tracker/services/test_session/session_progress.dart';
import 'package:bike_setup_tracker/services/test_session/test_session_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

import 'simulation.dart';

void main() {
  group('SessionProgress', () {
    test('tells exact, ranged and open-ended estimates apart', () {
      const exact = SessionProgress.exact(ridden: 2, left: 3);
      const ranged = SessionProgress(ridden: 2, left: 3, maxLeft: 5);
      const open = SessionProgress(ridden: 2, left: 3, maxLeft: null);

      expect((exact.isExact, exact.isOpenEnded, exact.isDone), (true, false, false));
      expect((ranged.isExact, ranged.isOpenEnded), (false, false));
      expect((open.isExact, open.isOpenEnded), (false, true));
    });

    test('is done once nothing is left and no run waits for feedback', () {
      const done = SessionProgress.exact(ridden: 5, left: 0);

      expect(done.isDone, isTrue);
      expect(done.asPending.isDone, isFalse);
      expect(const SessionProgress(ridden: 5, left: 0, maxLeft: 2).isDone, isFalse);
    });

    test('a run that waits for its feedback moves from left to ridden', () {
      expect(
        const SessionProgress(ridden: 2, left: 3, maxLeft: 5).awaitingFeedback,
        const SessionProgress(ridden: 3, pending: true, left: 2, maxLeft: 4),
      );
      expect(
        const SessionProgress(ridden: 2, left: 3, maxLeft: null).awaitingFeedback,
        const SessionProgress(ridden: 3, pending: true, left: 2, maxLeft: null),
      );
      expect(
        const SessionProgress.exact(ridden: 6, left: 1, confirming: true).awaitingFeedback,
        const SessionProgress(ridden: 7, pending: true, left: 0, maxLeft: 0, confirming: true),
      );
    });

    test('a run ridden after the result leaves nothing below zero', () {
      expect(
        const SessionProgress.exact(ridden: 6, left: 0).awaitingFeedback,
        const SessionProgress(ridden: 7, pending: true, left: 0, maxLeft: 0),
      );
    });
  });

  group('TestSessionStrategy.progress', () {
    const strategy = OrthogonalArrayStrategy();
    final adjustments = {'a': stepKnob('a')};

    TestSessionHistory history(
      int runs, {
      int rated = 0,
      TestSession? session,
      Map<String, Adjustment>? knobs,
      Map<String, AdjustmentValue> Function(int index)? values,
    }) {
      final all = <Setup>[
        for (var i = 0; i < runs; i++) run('r$i', values?.call(i) ?? {'a': StepValue(10 + i)}, index: i),
      ];
      return TestSessionHistory(
        session: session ?? testSession(method: const OrthogonalArray(), knobs: ['a']),
        adjustments: knobs ?? adjustments,
        runs: all,
        ratedRunIds: {for (final r in all.take(rated)) r.id},
        comparisons: const [],
      );
    }

    test('nothing without runs', () {
      expect(strategy.progress(history(0)), isNull);
    });

    test('the first run counts as ridden while it waits for its feedback', () {
      final rated = strategy.progress(history(1, rated: 1))!;

      expect(rated, const SessionProgress.exact(ridden: 1, left: 3));
      expect(strategy.progress(history(1)), rated.asPending);
    });

    test('a later run keeps the estimate it was proposed with until its feedback is in', () {
      final before = strategy.progress(history(1, rated: 1))!;

      final waiting = strategy.progress(history(2, rated: 1));

      expect(waiting, before.awaitingFeedback);
      expect(waiting, const SessionProgress(ridden: 2, pending: true, left: 2, maxLeft: 2));
      expect(strategy.progress(history(2, rated: 2)), const SessionProgress.exact(ridden: 2, left: 2));
    });

    test('several runs without feedback all count as ridden', () {
      expect(
        strategy.progress(history(3, rated: 1)),
        const SessionProgress(ridden: 3, pending: true, left: 1, maxLeft: 1),
      );
    });

    test('nothing when every knob is locked', () {
      final locked = testSession(method: const OrthogonalArray(), knobs: ['a'], locks: {'a': const StepValue(10)});

      expect(strategy.progress(history(1, rated: 1, session: locked)), isNull);
      expect(strategy.progress(history(1, session: locked)), isNull);
    });

    test('nothing for data the strategy cannot use', () {
      expect(strategy.progress(history(1, rated: 1, knobs: const {})), isNull);
      expect(strategy.progress(history(1, rated: 1, values: (_) => {'a': const StepValue(25)})), isNull);
    });
  });
}
