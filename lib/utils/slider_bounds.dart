import 'dart:math';

/// A slider track from 0 that just covers [dataMax], or [fallbackMax] while
/// there is no data. The step is the finest of 1, 2 or 5 × 10ⁿ that keeps the
/// track within [maxDivisions], and the track end is the next multiple of it,
/// so both thumb values and the end stay round numbers.
({double max, double step}) sliderBounds(double? dataMax, {required double fallbackMax, int maxDivisions = 40}) {
  final target = dataMax == null || dataMax <= 0 ? fallbackMax : dataMax;
  // The epsilon keeps floating-point noise (e.g. 30.000000000000004) from adding a division.
  int divisionsFor(double step) => (target / step - 1e-9).ceil();

  // 10 × magnitude always fits, as magnitude ≥ target / maxDivisions / 10.
  final magnitude = pow(10, (log(target / maxDivisions) / ln10).floor()).toDouble();
  final step = const [1, 2, 5, 10].map((f) => f * magnitude).firstWhere((s) => divisionsFor(s) <= maxDivisions);
  return (max: divisionsFor(step) * step, step: step);
}
