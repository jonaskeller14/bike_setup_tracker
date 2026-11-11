import '../models/adjustment/adjustment.dart';
import '../models/adjustment_activity_histogram.dart';
import '../services/component_slot.dart';

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
  final slotCounts = <String, Map<ComponentSlot?, int>>{};
  for (final entry in values) {
    final value = entry.value;
    if (value is! CategoricalValue) continue;
    for (final option in value.options.toSet()) {
      counts[option] = (counts[option] ?? 0) + entry.activityCount;
      _addSlotCount(slotCounts, option, entry);
    }
  }
  final slots = _stackSlots(slotCounts);

  final ordered = <String>[
    ...adjustment.options.where(counts.containsKey),
    ...counts.keys.where((option) => !adjustment.options.contains(option)).toList()..sort(),
  ];
  return AdjustmentActivityHistogram(
    adjustmentId: adjustment.id,
    unitLabel: adjustment.unit?.label,
    bars: List.unmodifiable(
      ordered.map(
        (option) => AdjustmentActivityHistogramBar.exact(
          activityCount: counts[option]!,
          exactValue: CategoricalValue([option]),
          segments: _segments(slots, slotCounts[option]),
        ),
      ),
    ),
    isBinned: false,
    slots: slots,
  );
}

AdjustmentActivityHistogram _groupDiscrete(
  Adjustment adjustment,
  List<AdjustmentActivityValue> values,
) {
  final counts = <AdjustmentValue, int>{};
  final slotCounts = <AdjustmentValue, Map<ComponentSlot?, int>>{};
  for (final entry in values) {
    counts[entry.value!] = (counts[entry.value] ?? 0) + entry.activityCount;
    _addSlotCount(slotCounts, entry.value!, entry);
  }
  final slots = _stackSlots(slotCounts);
  final ordered = counts.keys.toList()..sort(_compareExactValues);
  return AdjustmentActivityHistogram(
    adjustmentId: adjustment.id,
    unitLabel: adjustment.unit?.label,
    bars: List.unmodifiable(
      ordered.map(
        (value) => AdjustmentActivityHistogramBar.exact(
          activityCount: counts[value]!,
          exactValue: value,
          segments: _segments(slots, slotCounts[value]),
        ),
      ),
    ),
    isBinned: false,
    slots: slots,
  );
}

AdjustmentActivityHistogram _groupContinuous(
  Adjustment adjustment,
  List<AdjustmentActivityValue> values,
) {
  final counts = <num, int>{};
  final slotCounts = <num, Map<ComponentSlot?, int>>{};
  final originalValues = <num, AdjustmentValue>{};
  for (final entry in values) {
    final numeric = entry.value!.asNum;
    if (numeric == null || !numeric.isFinite) continue;
    counts[numeric] = (counts[numeric] ?? 0) + entry.activityCount;
    _addSlotCount(slotCounts, numeric, entry);
    originalValues[numeric] = entry.value!;
  }
  if (counts.isEmpty) return AdjustmentActivityHistogram.empty(adjustment.id);
  final slots = _stackSlots(slotCounts);

  final ordered = counts.keys.toList()..sort();
  if (ordered.length <= adjustmentHistogramMaxExactContinuousValues || ordered.first == ordered.last) {
    return AdjustmentActivityHistogram(
      adjustmentId: adjustment.id,
      unitLabel: adjustment.unit?.label,
      bars: List.unmodifiable(
        ordered.map(
          (value) => AdjustmentActivityHistogramBar.exact(
            activityCount: counts[value]!,
            exactValue: originalValues[value],
            segments: _segments(slots, slotCounts[value]),
          ),
        ),
      ),
      isBinned: false,
      slots: slots,
    );
  }

  final min = ordered.first.toDouble();
  final max = ordered.last.toDouble();
  final width = (max - min) / adjustmentHistogramBinCount;
  final binCounts = List<int>.filled(adjustmentHistogramBinCount, 0);
  final binSlotCounts = List.generate(adjustmentHistogramBinCount, (_) => <ComponentSlot?, int>{});
  for (final entry in counts.entries) {
    final bin = _binIndex(entry.key, min, width, adjustmentHistogramBinCount);
    binCounts[bin] += entry.value;
    for (final MapEntry(key: slot, value: count) in slotCounts[entry.key]!.entries) {
      binSlotCounts[bin][slot] = (binSlotCounts[bin][slot] ?? 0) + count;
    }
  }

  return AdjustmentActivityHistogram(
    adjustmentId: adjustment.id,
    unitLabel: adjustment.unit?.label,
    bars: List.unmodifiable(
      List.generate(adjustmentHistogramBinCount, (index) {
        final lower = min + width * index;
        final upper = index == adjustmentHistogramBinCount - 1 ? max : min + width * (index + 1);
        return AdjustmentActivityHistogramBar.range(
          activityCount: binCounts[index],
          lowerBound: lower,
          upperBound: upper,
          includesUpperBound: index == adjustmentHistogramBinCount - 1,
          segments: _segments(slots, binSlotCounts[index]),
        );
      }),
    ),
    isBinned: true,
    hasDurationBounds: adjustment is DurationAdjustment,
    slots: slots,
  );
}

void _addSlotCount<K>(Map<K, Map<ComponentSlot?, int>> slotCounts, K key, AdjustmentActivityValue entry) {
  final counts = slotCounts[key] ??= {};
  counts[entry.slot] = (counts[entry.slot] ?? 0) + entry.activityCount;
}

/// The slots to stack bars by, ordered like the bike's slot lanes with
/// unknown last; empty when every activity shares one slot.
List<ComponentSlot?> _stackSlots(Map<Object, Map<ComponentSlot?, int>> slotCounts) {
  final slots = {for (final counts in slotCounts.values) ...counts.keys};
  if (slots.length < 2) return const [];
  return List.unmodifiable([...slots.nonNulls.toList()..sort(compareSlots), if (slots.contains(null)) null]);
}

List<AdjustmentActivityHistogramSegment> _segments(List<ComponentSlot?> slots, Map<ComponentSlot?, int>? counts) {
  return List.unmodifiable([
    for (final slot in slots)
      if (counts?[slot] case final count? when count > 0) (slot: slot, activityCount: count),
  ]);
}

int _binIndex(num value, double min, double width, int binCount) {
  // The nudge keeps a value on a bin edge out of the bin below: `width` is
  // rarely exact (1.6..2.4 gives 0.09999999999999998), so 1.7 would land at 0.9999999999999989.
  return ((value.toDouble() - min) / width + 1e-9).floor().clamp(0, binCount - 1);
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
  return left.encode().compareTo(right.encode());
}
