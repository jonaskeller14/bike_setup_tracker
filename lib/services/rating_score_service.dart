import '../models/adjustment/adjustment.dart';
import '../models/rating_metric.dart';

class EntryScore {
  final double weightedAvg;  // 0-10, Higher is better
  final double weightedSum;
  final int answeredScored;
  final int totalScored;

  const EntryScore({
    required this.weightedAvg,
    required this.weightedSum,
    required this.answeredScored,
    required this.totalScored,
  });

  bool get isComplete => answeredScored >= totalScored;
}

typedef ScoringInput = ({List<RatingMetric> metrics, Map<String, dynamic> values});

class RatingScoreService {
  const RatingScoreService._();

  static double? normalize(RatingMetric metric, dynamic value) {
    if (value == null) return null;
    final adjustment = metric.adjustment;
    switch (adjustment) {
      case final BooleanAdjustment _:
        if (value is! bool) return null;
        return value ? 1.0 : 0.0;
      case final StepAdjustment a:
        if (value is! int) return null;
        if (a.max <= a.min) return null;
        return ((value - a.min) / (a.max - a.min)).clamp(0.0, 1.0).toDouble();
      case final NumericalAdjustment a:
        if (value is! double) return null;
        if (!a.min.isFinite || !a.max.isFinite || a.max <= a.min) return null;
        return ((value - a.min) / (a.max - a.min)).clamp(0.0, 1.0).toDouble();
      case final DurationAdjustment a:
        if (value is! Duration) return null;
        final min = a.min;
        final max = a.max;
        if (min == null || max == null || max.inMicroseconds <= min.inMicroseconds) {
          return null;
        }
        return ((value.inMicroseconds - min.inMicroseconds) / (max.inMicroseconds - min.inMicroseconds)).clamp(0.0, 1.0).toDouble();
      case final CategoricalAdjustment _:
      case final TextAdjustment _:
        return null;
    }
  }

  static double? goodness(RatingMetric metric, dynamic value) {
    final normalizedValue = normalize(metric, value);
    if (normalizedValue == null) return null;
    return metric.weight >= 0 ? normalizedValue : 1 - normalizedValue;
  }

  static EntryScore? scoreEntry(List<RatingMetric> metrics, Map<String, dynamic> values) {
    int totalScored = 0;
    int answeredScored = 0;
    double weightedSum = 0;
    double absWeight = 0;

    for (final metric in metrics) {
      if (!metric.isScored) continue;
      
      totalScored++;

      final value = values[metric.id];
      final normalizedValue = normalize(metric, value);
      if (normalizedValue == null) continue;

      final goodness = metric.weight >= 0 
        ? normalizedValue
        : 1 - normalizedValue;

      answeredScored++;
      weightedSum += goodness * metric.weight.abs();
      absWeight += metric.weight.abs();
    }

    if (absWeight == 0) return null;

    return EntryScore(
      weightedAvg: (weightedSum / absWeight) * 10, // 0–10
      weightedSum: weightedSum,
      answeredScored: answeredScored,
      totalScored: totalScored,
    );
  }

  static double? setupScore(Iterable<ScoringInput> entries) {
    final Map<String, List<double>> pooled = {};
    final Map<String, double> absWeights = {};

    for (final entry in entries) {
      for (final metric in entry.metrics) {
        if (!metric.isScored) continue;

        final value = entry.values[metric.id];
        final normalizedValue = normalize(metric, value);
        if (normalizedValue == null) continue;

        final goodness = metric.weight >= 0 
            ? normalizedValue
            : 1 - normalizedValue;

        (pooled[metric.id] ??= []).add(goodness);
        absWeights[metric.id] = metric.weight.abs();
      }
    }

    if (pooled.isEmpty) return null;

    double weightedSum = 0;
    double absWeightSum = 0;
    pooled.forEach((id, goodnessValues) {
      final mean = goodnessValues.reduce((a, b) => a + b) / goodnessValues.length;
      final absWeight = absWeights[id]!; // already |weight|
      weightedSum += mean * absWeight;
      absWeightSum += absWeight;
    });

    if (absWeightSum == 0) return null;
    return (weightedSum / absWeightSum) * 10; // 0–10
  }
}
