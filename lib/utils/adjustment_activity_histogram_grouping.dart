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
    final value = entry.value;
    if (value is! CategoricalValue) continue;
    for (final option in value.options.toSet()) {
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
          exactValue: CategoricalValue([option]),
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
  final counts = <AdjustmentValue, int>{};
  for (final entry in values) {
    counts[entry.value!] = (counts[entry.value] ?? 0) + entry.activityCount;
  }
  final ordered = counts.keys.toList()..sort(_compareExactValues);
  return AdjustmentActivityHistogram(
    adjustmentId: adjustment.id,
    bars: List.unmodifiable(
      ordered.map(
        (value) => AdjustmentActivityHistogramBar.exact(
          label: _withUnit(value.display, adjustment),
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
  final originalValues = <num, AdjustmentValue>{};
  for (final entry in values) {
    final numeric = entry.value!.asNum;
    if (numeric == null || !numeric.isFinite) continue;
    counts[numeric] = (counts[numeric] ?? 0) + entry.activityCount;
    originalValues[numeric] = entry.value!;
  }
  if (counts.isEmpty) return AdjustmentActivityHistogram.empty(adjustment.id);

  final ordered = counts.keys.toList()..sort();
  if (ordered.length <= adjustmentHistogramMaxExactContinuousValues || ordered.first == ordered.last) {
    return AdjustmentActivityHistogram(
      adjustmentId: adjustment.id,
      bars: List.unmodifiable(
        ordered.map(
          (value) => AdjustmentActivityHistogramBar.exact(
            label: _withUnit(originalValues[value]!.display, adjustment),
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
    binCounts[_binIndex(entry.key, min, width, adjustmentHistogramBinCount)] += entry.value;
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

int _binIndex(num value, double min, double width, int binCount) {
  return ((value.toDouble() - min) / width).floor().clamp(0, binCount - 1);
}

/// Indexes of the [histogram] bars that [value] falls into. Empty when the
/// value was never ridden; several for a multi-select categorical value.
Set<int> adjustmentHistogramBarIndexesFor(AdjustmentActivityHistogram histogram, AdjustmentValue? value) {
  final bars = histogram.bars;
  if (value == null || bars.isEmpty) return const {};

  if (histogram.isBinned) {
    final numeric = value.asNum;
    final min = bars.first.lowerBound!.toDouble();
    final max = bars.last.upperBound!.toDouble();
    if (numeric == null || !numeric.isFinite || numeric < min || numeric > max) return const {};
    return {_binIndex(numeric, min, (max - min) / bars.length, bars.length)};
  }

  return {
    for (var index = 0; index < bars.length; index++)
      if (_isExactMatch(bars[index].exactValue, value)) index,
  };
}

bool _isExactMatch(AdjustmentValue? barValue, AdjustmentValue value) {
  if (value is CategoricalValue) {
    return barValue is CategoricalValue && barValue.options.every(value.options.contains);
  }
  return barValue == value;
}

int _compareExactValues(AdjustmentValue left, AdjustmentValue right) {
  final (leftNum, rightNum) = (left.asNum, right.asNum);
  if (leftNum != null && rightNum != null) return leftNum.compareTo(rightNum);
  return left.display.compareTo(right.display);
}

/// [value] is on the [AdjustmentValue.asNum] scale, i.e. seconds for durations.
String _formatBoundary(double value, Adjustment adjustment) {
  final AdjustmentValue displayValue = adjustment is DurationAdjustment
      ? DurationValue(Duration(microseconds: (value * Duration.microsecondsPerSecond).round()))
      : NumericalValue(value);
  return _withUnit(displayValue.display, adjustment);
}

String _withUnit(String label, Adjustment adjustment) {
  final unit = adjustment.unit;
  return unit == null ? label : '$label ${unit.label}';
}
