import 'package:flutter/foundation.dart';

import 'adjustment_value.dart';

@immutable
sealed class ValueRange {
  const ValueRange();

  /// Whether [value] is of the type this range constrains.
  bool appliesTo(AdjustmentValue value);

  /// Whether [value] is of the constrained type and inside the range.
  bool contains(AdjustmentValue value);

  /// [value] moved to the nearest value inside the range; values of another
  /// type pass through.
  AdjustmentValue clamp(AdjustmentValue value);
}

final class NumericalRange extends ValueRange {
  final double min;
  final double max;

  const NumericalRange(this.min, this.max);

  @override
  bool appliesTo(AdjustmentValue value) => value is NumericalValue;

  @override
  bool contains(AdjustmentValue value) => value is NumericalValue && value.value >= min && value.value <= max;

  @override
  AdjustmentValue clamp(AdjustmentValue value) => switch (value) {
    NumericalValue(value: final v) when v < min => NumericalValue(min),
    NumericalValue(value: final v) when v > max => NumericalValue(max),
    _ => value,
  };

  @override
  bool operator ==(Object other) => other is NumericalRange && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(NumericalRange, min, max);

  @override
  String toString() => 'NumericalRange($min..$max)';
}

final class StepGrid extends ValueRange {
  final int min;
  final int max;
  final int step;

  const StepGrid(this.min, this.max, this.step);

  @override
  bool appliesTo(AdjustmentValue value) => value is StepValue;

  @override
  bool contains(AdjustmentValue value) =>
      value is StepValue && value.value >= min && value.value <= max && (value.value - min) % step == 0;

  /// Also snaps a value between grid points to the nearest one.
  @override
  AdjustmentValue clamp(AdjustmentValue value) => value is StepValue ? StepValue(_snap(value.value)) : value;

  int _snap(int value) {
    if (value <= min) return min;
    if (step <= 0) return value < max ? value : max;
    final snapped = min + ((value - min) / step).round() * step;
    if (snapped <= max) return snapped;
    return min + (max - min) ~/ step * step;
  }

  @override
  bool operator ==(Object other) => other is StepGrid && other.min == min && other.max == max && other.step == step;

  @override
  int get hashCode => Object.hash(StepGrid, min, max, step);

  @override
  String toString() => 'StepGrid($min..$max step $step)';
}

final class DurationRange extends ValueRange {
  final Duration? min;
  final Duration? max;

  const DurationRange(this.min, this.max);

  @override
  bool appliesTo(AdjustmentValue value) => value is DurationValue;

  @override
  bool contains(AdjustmentValue value) =>
      value is DurationValue &&
      (min == null || value.value.compareTo(min!) >= 0) &&
      (max == null || value.value.compareTo(max!) <= 0);

  @override
  AdjustmentValue clamp(AdjustmentValue value) => switch (value) {
    DurationValue(value: final v) when min != null && v < min! => DurationValue(min!),
    DurationValue(value: final v) when max != null && v > max! => DurationValue(max!),
    _ => value,
  };

  @override
  bool operator ==(Object other) => other is DurationRange && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(DurationRange, min, max);

  @override
  String toString() => 'DurationRange(${min ?? '-'}..${max ?? '-'})';
}
