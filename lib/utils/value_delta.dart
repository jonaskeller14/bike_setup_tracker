import '../models/adjustment/adjustment.dart';
import 'unit_conversion.dart';

/// `+2`, `−1.5`, `±0`: a difference with its sign spelled out. [magnitude] is
/// the already formatted absolute difference.
String formatSignedDelta(num difference, String magnitude) => difference > 0
    ? '+$magnitude'
    : difference < 0
    ? '−$magnitude'
    : '±$magnitude';

/// The signed difference from [previous] to [current], for the value types that
/// have an order (step, numerical including sag, duration). Null for boolean,
/// categorical and text values, and when either side is missing.
String? formatValueDelta(AdjustmentValue? previous, AdjustmentValue? current) => switch ((previous, current)) {
  (StepValue(value: final p), StepValue(value: final c)) => formatSignedDelta(c - p, '${(c - p).abs()}'),
  (NumericalValue(value: final p), NumericalValue(value: final c)) => formatSignedDelta(
    c - p,
    formatConverted((c - p).abs()),
  ),
  // Hours are dropped while they are zero: `+00:05` reads better than `+00:00:05`.
  (DurationValue(value: final p), DurationValue(value: final c)) => formatSignedDelta(
    (c - p).inMicroseconds,
    DurationValue((c - p).abs()).display.replaceFirst(RegExp('^00:'), ''),
  ),
  _ => null,
};
