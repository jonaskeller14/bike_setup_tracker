import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../models/adjustment/adjustment.dart';
import '../../utils/value_delta.dart';

/// An adjustment as the strategies see it: a coordinate on an ordered grid
/// with bounds and a smallest step, nothing about what the knob does.
///
/// Step and numerical values are their own coordinate, a boolean is 0 / 1 and
/// a categorical value is the index of its option.
@immutable
class StrategyKnob {
  final Adjustment adjustment;
  final double min;
  final double max;

  /// The smallest move, in coordinates.
  final double unit;

  /// A boolean or categorical knob: it moves one option at a time.
  final bool isDiscrete;

  const StrategyKnob._(
    this.adjustment, {
    required this.min,
    required this.max,
    required this.unit,
    this.isDiscrete = false,
  });

  String get id => adjustment.id;
  bool get hasFiniteRange => min.isFinite && max.isFinite;

  /// Null when strategies can't move [adjustment]: a text, a duration, or a
  /// categorical that takes several options at once. [reference] is a typical
  /// value, which sizes the step of a numerical knob without a known unit.
  static StrategyKnob? of(Adjustment adjustment, {AdjustmentValue? reference}) => switch (adjustment) {
    StepAdjustment(:final min, :final max, :final step) => StrategyKnob._(
      adjustment,
      min: min.toDouble(),
      max: max.toDouble(),
      unit: math.max(step, 1).toDouble(),
    ),
    NumericalAdjustment(:final min, :final max) => StrategyKnob._(
      adjustment,
      min: min,
      max: max,
      unit: numericalUnit(adjustment, reference is NumericalValue ? reference.value : null),
    ),
    BooleanAdjustment() => StrategyKnob._(adjustment, min: 0, max: 1, unit: 1, isDiscrete: true),
    CategoricalAdjustment(:final options, :final multiSelect, :final counted)
        when !multiSelect && !counted && options.isNotEmpty =>
      StrategyKnob._(adjustment, min: 0, max: options.length - 1, unit: 1, isDiscrete: true),
    _ => null,
  };

  /// One click of a numerical knob: a usual increment of its unit, otherwise a
  /// twentieth of its range, otherwise 5 % of [reference], rounded to 1, 2 or 5.
  @visibleForTesting
  static double numericalUnit(NumericalAdjustment adjustment, double? reference) {
    final known = switch (adjustment.unit) {
      KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi') => 1.0,
      KnownUnit(quantity: UnitQuantity.pressure, unitId: 'bar') => 0.1,
      KnownUnit(quantity: UnitQuantity.pressure, unitId: 'kiloPascal') => 5.0,
      KnownUnit(quantity: UnitQuantity.length, unitId: 'millimeters') => 1.0,
      KnownUnit(quantity: UnitQuantity.length, unitId: 'centimeters') => 0.1,
      KnownUnit(quantity: UnitQuantity.length, unitId: 'inches') => 0.05,
      CustomUnit(:final label) => switch (label.toLowerCase()) {
        'clicks' || 'tokens' || '%' => 1.0,
        'turns' => 0.25,
        _ => null,
      },
      _ => null,
    };
    if (known != null) return known;
    if (adjustment.min.isFinite && adjustment.max.isFinite && adjustment.max > adjustment.min) {
      return _nice((adjustment.max - adjustment.min) / 20);
    }
    if (reference != null && reference != 0) return _nice(reference.abs() * 0.05);
    return 1;
  }

  /// [x] rounded to 1, 2 or 5 times a power of ten.
  static double _nice(double x) {
    final power = math.pow(10, (math.log(x) / math.ln10).floor()).toDouble();
    final mantissa = x / power;
    final rounded = mantissa < 1.5 ? 1 : (mantissa < 3.5 ? 2 : (mantissa < 7.5 ? 5 : 10));
    return rounded * power;
  }

  double? coordinateOf(AdjustmentValue? value) => switch ((adjustment, value)) {
    (StepAdjustment(), StepValue(:final value)) => value.toDouble(),
    (NumericalAdjustment(), NumericalValue(:final value)) => value,
    (BooleanAdjustment(), BooleanValue(:final value)) => value ? 1 : 0,
    (CategoricalAdjustment(:final options), CategoricalValue(options: [final option])) => switch (options
        .toList()
        .indexOf(option)) {
      -1 => null,
      final index => index.toDouble(),
    },
    _ => null,
  };

  /// [coordinate] inside the bounds and on the grid.
  double snap(double coordinate) {
    final clamped = coordinate.clamp(min, max).toDouble();
    if (isDiscrete || adjustment is StepAdjustment) {
      final snapped = min + ((clamped - min) / unit).round() * unit;
      return snapped > max ? snapped - unit : snapped;
    }
    return _roundToUnitDecimals(clamped);
  }

  /// Numerical values keep their own offset from the grid (26.3 psi moves to
  /// 27.3) and only lose float noise.
  double _roundToUnitDecimals(double value) {
    final decimals = math.max(0, -(math.log(unit) / math.ln10).floor() + 1);
    final factor = math.pow(10, decimals);
    return (value * factor).round() / factor;
  }

  AdjustmentValue valueAt(double coordinate) {
    final snapped = snap(coordinate);
    return switch (adjustment) {
      StepAdjustment() => StepValue(snapped.round()),
      BooleanAdjustment() => BooleanValue(snapped >= 0.5),
      CategoricalAdjustment(:final options) => CategoricalValue([options.elementAt(snapped.round())]),
      _ => NumericalValue(snapped),
    };
  }

  /// [distance] as a whole number of units, at least one.
  double roundToUnits(double distance) => math.max(1, (distance / unit).round()) * unit;

  /// A step of [fraction] of the range, or [fallbackUnits] units without a
  /// finite range; one option for a discrete knob.
  double stepOf(double fraction, {required double fallbackUnits}) {
    if (isDiscrete) return unit;
    if (hasFiniteRange) return roundToUnits(fraction * (max - min));
    return fallbackUnits * unit;
  }

  bool isSame(double a, double b) => (a - b).abs() < unit / 2;

  /// "Rebound +2", "Lockout On", "Mode Firm".
  String describe(double from, double to) {
    final value = valueAt(to);
    final delta = formatValueDelta(valueAt(from), value);
    return '${adjustment.name} ${delta ?? value.display}${delta != null ? adjustment.unitSuffix() : ''}';
  }
}
