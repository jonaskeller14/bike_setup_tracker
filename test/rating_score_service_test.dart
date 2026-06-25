import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/rating_metric.dart';
import 'package:bike_setup_tracker/services/rating_score_service.dart';
import 'package:flutter_test/flutter_test.dart';

StepAdjustment _step({int min = 0, int max = 10}) => StepAdjustment(
      name: 'step',
      notes: null,
      unit: null,
      step: 1,
      min: min,
      max: max,
      visualization: StepAdjustmentVisualization.slider,
    );

BooleanAdjustment _bool() => BooleanAdjustment(
      name: 'bool',
      notes: null,
      unit: null,
    );

NumericalAdjustment _num({double? min, double? max}) => NumericalAdjustment(
      name: 'num',
      notes: null,
      unit: null,
      min: min,
      max: max,
    );

DurationAdjustment _dur({Duration? min, Duration? max}) => DurationAdjustment(
      name: 'dur',
      notes: null,
      unit: null,
      min: min,
      max: max,
    );

TextAdjustment _text() => TextAdjustment(
      name: 'text',
      notes: null,
      unit: null,
    );

void main() {
  group('normalize', () {
    test('step maps to [0,1]', () {
      final m = RatingMetric(adjustment: _step());
      expect(RatingScoreService.normalize(m, 0), 0.0);
      expect(RatingScoreService.normalize(m, 10), 1.0);
      expect(RatingScoreService.normalize(m, 8), closeTo(0.8, 1e-9));
    });

    test('bool maps to 0/1', () {
      final m = RatingMetric(adjustment: _bool());
      expect(RatingScoreService.normalize(m, true), 1.0);
      expect(RatingScoreService.normalize(m, false), 0.0);
    });

    test('unbounded numerical/duration are not scorable -> null', () {
      expect(RatingScoreService.normalize(RatingMetric(adjustment: _num()), 5.0), isNull);
      expect(RatingScoreService.normalize(RatingMetric(adjustment: _dur()),
          const Duration(minutes: 1)), isNull);
    });

    test('bounded duration maps to [0,1]', () {
      final m = RatingMetric(
          adjustment: _dur(min: const Duration(minutes: 1), max: const Duration(minutes: 3)));
      expect(RatingScoreService.normalize(m, const Duration(minutes: 2)), closeTo(0.5, 1e-9));
    });

    test('text/categorical and missing values -> null', () {
      expect(RatingScoreService.normalize(RatingMetric(adjustment: _text()), 'hi'), isNull);
      expect(RatingScoreService.normalize(RatingMetric(adjustment: _step()), null), isNull);
    });
  });

  group('scoreEntry', () {
    test('single positive metric', () {
      final metrics = [RatingMetric(adjustment: _step(), weight: 1)];
      final s = RatingScoreService.scoreEntry(metrics, {metrics.first.id: 8})!;
      expect(s.weightedSum, closeTo(0.8, 1e-9));
      expect(s.weightedAvg, closeTo(8.0, 1e-9)); // goodness 0.8 * 10
      expect(s.answeredScored, 1);
      expect(s.totalScored, 1);
      expect(s.isComplete, isTrue);
    });

    test('negative weight subtracts (lower is better)', () {
      // "How bad does it feel?" with a high value should hurt the score.
      final bad = RatingMetric(adjustment: _step(), weight: -1);
      final s = RatingScoreService.scoreEntry([bad], {bad.id: 10})!;
      expect(s.weightedAvg, closeTo(0.0, 1e-9)); // n=1, *-1 -> avg01=-1 -> 0/10
    });

    test('unanswered + non-scored metrics affect completeness, not crash', () {
      final answered = RatingMetric(adjustment: _step(), weight: 1);
      final missing = RatingMetric(adjustment: _step(), weight: 1);
      final txt = RatingMetric(adjustment: _text(), weight: 1);
      final s = RatingScoreService.scoreEntry(
          [answered, missing, txt], {answered.id: 5});
      expect(s, isNotNull);
      expect(s!.answeredScored, 1);
      expect(s.totalScored, 2); // text not counted as scored
      expect(s.isComplete, isFalse);
    });

    test('no usable values -> null', () {
      final m = RatingMetric(adjustment: _step(), weight: 1);
      expect(RatingScoreService.scoreEntry([m], const {}), isNull);
      expect(RatingScoreService.scoreEntry([RatingMetric(adjustment: _text())], const {}),
          isNull);
    });
  });

  group('breakdown', () {
    test('per-metric rows: subScore (0–10), contribution, and totals reconcile', () {
      final grip = RatingMetric(adjustment: _step(), weight: 2); // answered 8/10
      final comfort = RatingMetric(adjustment: _step(), weight: 1); // answered 4/10
      final missing = RatingMetric(adjustment: _step(), weight: 1); // unanswered
      final txt = RatingMetric(adjustment: _text(), weight: 1); // not scored

      final b = RatingScoreService.breakdown(
        [grip, comfort, missing, txt],
        {grip.id: 8, comfort.id: 4},
      );

      // Only scored metrics become rows (text excluded).
      expect(b.rows.length, 3);

      final gripRow = b.rows.firstWhere((r) => r.metric.id == grip.id);
      expect(gripRow.subScore, closeTo(8.0, 1e-9));
      expect(gripRow.absWeight, 2);
      expect(gripRow.contribution, closeTo(1.6, 1e-9)); // 0.8 * 2

      final missingRow = b.rows.firstWhere((r) => r.metric.id == missing.id);
      expect(missingRow.answered, isFalse);
      expect(missingRow.subScore, isNull);

      // weightedTotal / maxTotal × 10 == weightedAvg.
      expect(b.weightedTotal, closeTo(1.6 + 0.4, 1e-9)); // 2.0
      expect(b.maxTotal, closeTo(3.0, 1e-9)); // |2| + |1| over answered
      expect(b.weightedTotal / b.maxTotal * 10, closeTo(b.score!.weightedAvg, 1e-9));
    });

    test('no answers -> rows present but score null', () {
      final m = RatingMetric(adjustment: _step(), weight: 1);
      final b = RatingScoreService.breakdown([m], const {});
      expect(b.rows.length, 1);
      expect(b.score, isNull);
      expect(b.maxTotal, 0);
    });
  });

  group('setupScore (per-metric pooling)', () {
    test('respects weights under sparse/overlapping entries', () {
      // A: important (weight 5), answered once at max (n=1).
      // B: trivial (weight 1), answered 0 in four entries (n=0).
      final a = RatingMetric(adjustment: _step(), weight: 5);
      final b = RatingMetric(adjustment: _step(), weight: 1);
      final metrics = [a, b];

      final entries = <ScoringInput>[
        (metrics: metrics, values: {a.id: 10}), // A only
        (metrics: metrics, values: {b.id: 0}),
        (metrics: metrics, values: {b.id: 0}),
        (metrics: metrics, values: {b.id: 0}),
        (metrics: metrics, values: {b.id: 0}),
      ];

      final pooled = RatingScoreService.setupScore(entries)!;
      // Pooled: A goodness mean=1 (|w|5), B mean=0 (|w|1) -> (5/6)*10 ≈ 8.333
      expect(pooled, closeTo(8.3333, 1e-3));
      // A naive mean-of-entry-scores would be ~2.0 — confirm pooling differs.
      expect(pooled, greaterThan(5.0));
    });

    test('null-safe: empty / all-unanswered -> null', () {
      expect(RatingScoreService.setupScore(const []), isNull);
      final m = RatingMetric(adjustment: _step(), weight: 1);
      expect(
        RatingScoreService.setupScore([(metrics: [m], values: const {})]),
        isNull,
      );
    });
  });
}
