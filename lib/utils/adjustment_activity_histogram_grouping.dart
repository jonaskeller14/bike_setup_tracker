import '../models/adjustment/adjustment.dart';
import '../models/adjustment_activity_histogram.dart';

const int adjustmentHistogramMaxExactContinuousValues = 12;
const int adjustmentHistogramBinCount = 8;

AdjustmentActivityHistogram groupAdjustmentActivityHistogram({
  required Adjustment adjustment,
  required Iterable<AdjustmentActivityValue> values,
}) {
  final weightedValues = values.where((entry) => entry.activityCount > 0 && entry.value != null).toList();
  if (weightedValues.isEmpty) return AdjustmentActivityHistogram.empty(adjustment.id);

  if (adjustment is CategoricalAdjustment) {
    return _groupCategorical(adjustment, weightedValues);
  }
  if (adjustment is NumericalAdjustment || adjustment is DurationAdjustment) {
    return _groupContinuous(adjustment, weightedValues);
  }
  return _groupDiscrete(adjustment, weightedValues);
}

AdjustmentActivityHistogram _groupCategorical(
  CategoricalAdjustment adjustment,
  List<AdjustmentActivityValue> values,
) {
  final counts = <String, int>{};
  for (final entry in values) {
    final selections = categoricalValueAsList(entry.value);
    if (selections == null) continue;
    for (final option in selections.toSet()) {
      counts[option] = (counts[option] ?? 0) + entry.activityCount;
    }
  }

  final ordered = <String>[
    ...adjustment.options.where(counts.containsKey),
    ...counts.keys.where((option) => !adjustment.options.contains(option)).toList()..sort(),
  ];
  return AdjustmentActivityHistogram(
    adjustmentId: adjustment.id,
    bars: List.unmodifiable(
      ordered.map(
        (option) => AdjustmentActivityHistogramBar.exact(
          label: _withUnit(option, adjustment),
          activityCount: counts[option]!,
          exactValue: option,
        ),
      ),
    ),
    isBinned: false,
  );
}

AdjustmentActivityHistogram _groupDiscrete(
  Adjustment adjustment,
  List<AdjustmentActivityValue> values,
) {
  final counts = <dynamic, int>{};
  for (final entry in values) {
    counts[entry.value] = (counts[entry.value] ?? 0) + entry.activityCount;
  }
  final ordered = counts.keys.toList()..sort(_compareExactValues);
  return AdjustmentActivityHistogram(
    adjustmentId: adjustment.id,
    bars: List.unmodifiable(
      ordered.map(
        (value) => AdjustmentActivityHistogramBar.exact(
          label: _withUnit(Adjustment.formatValue(value), adjustment),
          activityCount: counts[value]!,
          exactValue: value,
        ),
      ),
    ),
    isBinned: false,
  );
}

AdjustmentActivityHistogram _groupContinuous(
  Adjustment adjustment,
  List<AdjustmentActivityValue> values,
) {
  final counts = <num, int>{};
  final originalValues = <num, dynamic>{};
  for (final entry in values) {
    final numeric = _asNumeric(entry.value);
    if (numeric == null || !numeric.isFinite) continue;
    counts[numeric] = (counts[numeric] ?? 0) + entry.activityCount;
    originalValues[numeric] = entry.value;
  }
  if (counts.isEmpty) return AdjustmentActivityHistogram.empty(adjustment.id);

  final ordered = counts.keys.toList()..sort();
  if (ordered.length <= adjustmentHistogramMaxExactContinuousValues || ordered.first == ordered.last) {
    return AdjustmentActivityHistogram(
      adjustmentId: adjustment.id,
      bars: List.unmodifiable(
        ordered.map(
          (value) => AdjustmentActivityHistogramBar.exact(
            label: _withUnit(Adjustment.formatValue(originalValues[value]), adjustment),
            activityCount: counts[value]!,
            exactValue: originalValues[value],
          ),
        ),
      ),
      isBinned: false,
    );
  }

  final min = ordered.first.toDouble();
  final max = ordered.last.toDouble();
  final width = (max - min) / adjustmentHistogramBinCount;
  final binCounts = List<int>.filled(adjustmentHistogramBinCount, 0);
  for (final entry in counts.entries) {
    final rawIndex = ((entry.key.toDouble() - min) / width).floor();
    final index = rawIndex.clamp(0, adjustmentHistogramBinCount - 1);
    binCounts[index] += entry.value;
  }

  return AdjustmentActivityHistogram(
    adjustmentId: adjustment.id,
    bars: List.unmodifiable(
      List.generate(adjustmentHistogramBinCount, (index) {
        final lower = min + width * index;
        final upper = index == adjustmentHistogramBinCount - 1 ? max : min + width * (index + 1);
        return AdjustmentActivityHistogramBar.range(
          label: '${_formatBoundary(lower, adjustment)}–${_formatBoundary(upper, adjustment)}',
          activityCount: binCounts[index],
          lowerBound: lower,
          upperBound: upper,
          includesUpperBound: index == adjustmentHistogramBinCount - 1,
        );
      }),
    ),
    isBinned: true,
  );
}

num? _asNumeric(dynamic value) {
  return switch (value) {
    num() => value,
    Duration() => value.inMicroseconds,
    _ => null,
  };
}

int _compareExactValues(dynamic left, dynamic right) {
  if (left is num && right is num) return left.compareTo(right);
  if (left is bool && right is bool) return (left ? 1 : 0).compareTo(right ? 1 : 0);
  return Adjustment.formatValue(left).compareTo(Adjustment.formatValue(right));
}

String _formatBoundary(double value, Adjustment adjustment) {
  final dynamic displayValue = adjustment is DurationAdjustment ? Duration(microseconds: value.round()) : value;
  return _withUnit(Adjustment.formatValue(displayValue), adjustment);
}

String _withUnit(String label, Adjustment adjustment) {
  final unit = adjustment.unit;
  return unit == null ? label : '$label ${unit.label}';
}
