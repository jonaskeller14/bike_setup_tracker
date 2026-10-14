import 'package:collection/collection.dart';
import 'package:units_converter/units_converter.dart';

import '../models/adjustment/adjustment.dart';
import '../models/component/component_catalog.dart';
import '../models/component/preset_spec_keys.dart';
import '../models/component/setup_guide.dart';
import 'adjustment_role.dart';
import 'component_preset_resolver.dart';
import 'unit_conversion.dart';

/// Targets whose values are parts you fit, so a value between two rows
/// doesn't exist.
const Set<String> _discreteTargets = {'spring_rate', 'volume_spacers'};

const KnownUnit _millimeters = KnownUnit(quantity: UnitQuantity.length, unitId: 'millimeters');

/// Unit conversions are not exact.
const double _epsilon = 1e-6;

/// The recommendations of [preset]'s setup guide for [adjustments], in their
/// order. Per target the most specific matching rule wins; a target without a
/// matching adjustment is left out.
///
/// [currentValues] are keyed by adjustment id: what the rider has entered,
/// read by rules keyed by another adjuster and compared in
/// [GuideRecommendation.deviation].
List<GuideRecommendation> evaluateSetupGuide(
  ResolvedPreset preset,
  List<Adjustment> adjustments,
  GuideInputs inputs,
  Map<String, AdjustmentValue> currentValues,
) {
  final guide = preset.node.guide;
  if (guide == null) return const [];

  final winners = <String, GuideRule>{};
  for (final rule in guide.rules) {
    if (!_matches(rule, preset, inputs)) continue;
    final best = winners[rule.target];
    if (best == null || rule.specificity > best.specificity) winners[rule.target] = rule;
  }

  Adjustment? adjustmentFor(String role) => adjustments.firstWhereOrNull((a) => adjustmentRole(a) == role);

  // Dependency order: a rule reading another adjuster comes after its rules.
  final results = <String, GuideRecommendation>{};
  for (final rule in guide.rules) {
    if (!identical(winners[rule.target], rule)) continue;
    final adjustment = adjustmentFor(rule.target);
    if (adjustment == null) continue;
    results[rule.target] = _RuleEvaluation(
      guide: guide,
      rule: rule,
      adjustment: adjustment,
      preset: preset,
      inputs: inputs,
      current: currentValues[adjustment.id],
      readAdjuster: (id) {
        final input = adjustmentFor(id);
        if (input == null) return null;
        final value = currentValues[input.id] ?? results[id]?.value;
        return value == null ? null : (input, value);
      },
    ).evaluate();
  }
  return results.values.sortedBy<num>((result) => adjustments.indexOf(result.adjustment));
}

/// A rider-side key matches the rider's input; a level its node; an axis the
/// chosen value, so a skipped option matches nothing.
bool _matches(GuideRule rule, ResolvedPreset preset, GuideInputs inputs) => rule.when.entries.every((entry) {
  final Object? actual = entry.key == kRidingStyleKey
      ? inputs.ridingStyle?.name
      : preset.path.firstWhereOrNull((node) => node.level == entry.key)?.id ?? preset.selections[entry.key]?.id;
  return actual != null && entry.value.contains(actual);
});

/// Ends an evaluation without a value.
class _Failure implements Exception {
  final GuideIssue issue;

  /// What the guide asks for, where that is known but can't be applied.
  final AdjustmentValue? unapplied;

  const _Failure(this.issue, [this.unapplied]);
}

/// How the catalog dial's counting relates to the rider's step adjuster.
enum _Counting {
  /// Both count from the same end; the ranges may be shifted.
  same,

  /// The dials turn the other way, so one counts from closed, the other from
  /// open.
  mirrored,

  /// A stepper or slider on another range: which end it counts from is unknown.
  unknown,
}

/// A cell resolved against the rider's adjustment.
sealed class _Cell {
  const _Cell();
}

/// In the adjustment's unit; [min] == [max] for a single value.
final class _NumericCell extends _Cell {
  final double min;
  final double max;
  final bool isBand;

  const _NumericCell(this.min, this.max, {required this.isBand});

  double get center => (min + max) / 2;
}

final class _DiscreteCell extends _Cell {
  final AdjustmentValue value;

  const _DiscreteCell(this.value);
}

/// A stretch of a numeric table between the rows [lower] and [upper] (equal
/// for a flat stretch). [neighbour] is the row whose distance sets the
/// tolerance of a flat stretch.
class _Piece {
  final double from;
  final double to;
  final bool toInclusive;
  final int lower;
  final int upper;
  final int neighbour;

  const _Piece(this.from, this.to, {required this.lower, int? upper, int? neighbour, this.toInclusive = false})
    : upper = upper ?? lower,
      neighbour = neighbour ?? lower;

  bool contains(double x) => from <= x && (x < to || (toInclusive && x == to));

  /// 0 at [from], 1 at [to]; 0 for a flat or unbounded stretch.
  double position(double x) => lower == upper || !from.isFinite || !to.isFinite ? 0 : (x - from) / (to - from);
}

class _RuleEvaluation {
  final SetupGuide guide;
  final GuideRule rule;
  final Adjustment adjustment;
  final ResolvedPreset preset;
  final GuideInputs inputs;
  final AdjustmentValue? current;
  final (Adjustment, AdjustmentValue)? Function(String adjusterId) readAdjuster;

  _RuleEvaluation({
    required this.guide,
    required this.rule,
    required this.adjustment,
    required this.preset,
    required this.inputs,
    required this.current,
    required this.readAdjuster,
  });

  String? _inputText;
  bool _interpolated = false;
  bool _converted = false;
  ({double min, double max})? _riderWeightRange;

  GuideRecommendation evaluate() {
    try {
      final (value, band) = switch (rule.output) {
        ConstantOutput(:final value) => _fromCell(_resolve(value), tolerance: 0),
        RangeOutput() => _fromRange(),
        LookupOutput(:final rows) => _fromLookup(rows),
      };
      return _recommendation(value: value, band: band);
    } on _Failure catch (failure) {
      return _recommendation(issue: failure.issue, unappliedValue: failure.unapplied);
    }
  }

  GuideRecommendation _recommendation({
    AdjustmentValue? value,
    ({double min, double max})? band,
    GuideIssue? issue,
    AdjustmentValue? unappliedValue,
  }) => GuideRecommendation(
    guide: guide,
    rule: rule,
    adjustment: adjustment,
    value: value,
    issue: issue,
    unappliedValue: unappliedValue,
    converted: _converted,
    band: band == null ? null : _settableBand(band),
    current: current,
    inputText: _inputText,
    interpolated: _interpolated,
    riderWeightRange: _riderWeightRange,
  );

  (AdjustmentValue, ({double min, double max})?) _fromRange() {
    final RangeOutput(:min, :max, :comfortAt) = rule.output as RangeOutput;
    final (low, high) = (_toRiderDial(_toAdjustmentUnit(min)), _toRiderDial(_toAdjustmentUnit(max)));
    final cell = _bandCell(low, high);
    final comfort = comfortAt == GuideAnchor.min ? low : high;
    final race = comfortAt == GuideAnchor.min ? high : low;
    final point = switch (comfortAt == null ? null : inputs.ridingStyle) {
      GuideRidingStyle.comfort => comfort,
      GuideRidingStyle.race => race,
      GuideRidingStyle.balanced || null => cell.center,
    };
    return (_numericValue(point), (min: cell.min, max: cell.max));
  }

  (AdjustmentValue, ({double min, double max})?) _fromLookup(List<GuideRow> rows) {
    final input = rule.input!;
    if (!input.numeric) {
      final key = _literalInput(input);
      final row = rows.firstWhereOrNull((row) => (row.key as GuidePoint).value == key);
      if (row == null) throw const _Failure(GuideIssue.outsideRange);
      return _fromCell(_resolve(row.cell), tolerance: 0);
    }

    final cells = [for (final row in rows) _resolve(row.cell)];
    final interpolates = !_discreteTargets.contains(rule.target) && cells.every((cell) => cell is _NumericCell);
    final pieces = interpolates ? _interpolatedPieces(rows) : _steppedPieces(rows);
    double tolerance(_Piece piece) => interpolates ? _tolerance(cells, piece) : 0;

    if (input case RiderGuideInput(key: GuideInputKey.riderWeight)) {
      _riderWeightRange = _reverseLookup(pieces, cells, tolerance);
    }

    final x = _numericInput(input);
    final piece = pieces.firstWhereOrNull((piece) => piece.contains(x));
    if (piece == null) throw const _Failure(GuideIssue.outsideRange);
    final t = piece.position(x);
    if (t == 0 || t == 1) return _fromCell(cells[t == 0 ? piece.lower : piece.upper], tolerance: tolerance(piece));

    _interpolated = true;
    final (a, b) = (cells[piece.lower] as _NumericCell, cells[piece.upper] as _NumericCell);
    double lerp(double from, double to) => from + (to - from) * t;
    return _fromCell(
      _NumericCell(lerp(a.min, b.min), lerp(a.max, b.max), isBand: a.isBand || b.isBand),
      tolerance: tolerance(piece),
    );
  }

  /// A single value gets [tolerance] either side; a band is its own tolerance.
  (AdjustmentValue, ({double min, double max})?) _fromCell(_Cell cell, {required double tolerance}) => switch (cell) {
    _DiscreteCell(:final value) => (value, null),
    _NumericCell(isBand: true) => (_numericValue(cell.center), (min: cell.min, max: cell.max)),
    _NumericCell(:final center) => (
      _numericValue(center),
      tolerance > 0 ? (min: center - tolerance, max: center + tolerance) : null,
    ),
  };

  /// Bracket midpoints and points are joined linearly; the outer half of an
  /// outermost bracket and an open-ended row are flat.
  List<_Piece> _interpolatedPieces(List<GuideRow> rows) {
    final pieces = <_Piece>[];
    final knots = <(double, int)>[];
    final last = rows.length - 1;
    // The next row towards the inside of the table, else the one outside.
    int neighbour(int i, int inward) =>
        last == 0 ? i : ((i + inward).clamp(0, last) == i + inward ? i + inward : i - inward);
    for (final (i, row) in rows.indexed) {
      switch (row.key) {
        case GuideBracket(from: null, :final to?):
          pieces.add(_Piece(double.negativeInfinity, to.toDouble(), lower: i, neighbour: neighbour(i, 1)));
        case GuideBracket(:final from?, to: null):
          pieces.add(_Piece(from.toDouble(), double.infinity, lower: i, neighbour: neighbour(i, -1)));
        case GuideBracket(:final from?, :final to?):
          knots.add(((from + to) / 2, i));
        case GuidePoint(value: final num value):
          knots.add((value.toDouble(), i));
        default:
          throw StateError('Unexpected row key ${row.key}');
      }
    }
    if (knots.isEmpty) return pieces;

    final (firstX, first) = knots.first;
    if (rows[first].key case GuideBracket(:final from?)) {
      pieces.add(
        _Piece(from.toDouble(), firstX, lower: first, neighbour: neighbour(first, 1), toInclusive: true),
      );
    }
    for (var k = 0; k + 1 < knots.length; k++) {
      final ((fromX, lower), (toX, upper)) = (knots[k], knots[k + 1]);
      pieces.add(_Piece(fromX, toX, lower: lower, upper: upper, toInclusive: true));
    }
    final (lastX, lastRow) = knots.last;
    switch (rows[lastRow].key) {
      case GuideBracket(:final to?):
        pieces.add(_Piece(lastX, to.toDouble(), lower: lastRow, neighbour: neighbour(lastRow, -1)));
      case GuidePoint() when knots.length == 1:
        pieces.add(_Piece(lastX, lastX, lower: lastRow, toInclusive: true));
      default:
        break;
    }
    return pieces;
  }

  /// Each bracket covers itself, each point up to halfway to its neighbours
  /// (the lower one on a tie).
  List<_Piece> _steppedPieces(List<GuideRow> rows) {
    final points = [
      for (final (i, row) in rows.indexed)
        if (row.key case GuidePoint(value: final num value)) (value.toDouble(), i),
    ];
    return [
      for (final (i, row) in rows.indexed)
        if (row.key case GuideBracket(:final from, :final to))
          _Piece(from?.toDouble() ?? double.negativeInfinity, to?.toDouble() ?? double.infinity, lower: i),
      for (final (k, (x, i)) in points.indexed)
        _Piece(
          k == 0 ? x : (points[k - 1].$1 + x) / 2,
          k == points.length - 1 ? x : (x + points[k + 1].$1) / 2,
          lower: i,
          toInclusive: true,
        ),
    ].sortedBy<num>((piece) => piece.from);
  }

  /// Half the difference to the neighbouring row.
  static double _tolerance(List<_Cell> cells, _Piece piece) {
    final other = piece.lower == piece.upper ? piece.neighbour : piece.upper;
    return ((cells[other] as _NumericCell).center - (cells[piece.lower] as _NumericCell).center).abs() / 2;
  }

  /// The rider weights whose recommendation the current value is on guide for.
  ({double min, double max})? _reverseLookup(
    List<_Piece> pieces,
    List<_Cell> cells,
    double Function(_Piece) tolerance,
  ) {
    final now = current?.asNum?.toDouble();
    if (now == null || cells.any((cell) => cell is! _NumericCell)) return null;

    double? low;
    double? high;
    for (final piece in pieces) {
      final (a, b) = (cells[piece.lower] as _NumericCell, cells[piece.upper] as _NumericCell);
      final margin = (a.isBand || b.isBand ? 0 : tolerance(piece)) + _epsilon;
      // Along the piece the band's ends move linearly with t in [0, 1].
      final (fromLow, toLow) = _where(a.min, b.min, now + margin, atMost: true);
      final (fromHigh, toHigh) = _where(a.max, b.max, now - margin, atMost: false);
      final (tFrom, tTo) = (fromLow > fromHigh ? fromLow : fromHigh, toLow < toHigh ? toLow : toHigh);
      if (tFrom > tTo) continue;
      final (from, to) = piece.lower == piece.upper
          ? (piece.from, piece.to)
          : (piece.from + (piece.to - piece.from) * tFrom, piece.from + (piece.to - piece.from) * tTo);
      low = low == null || from < low ? from : low;
      high = high == null || to > high ? to : high;
    }
    if (low == null || high == null) return null;
    double toRider(double weight) =>
        weight.isFinite ? convertUnit(weight, rule.inputUnit!, inputs.riderWeightUnit) : weight;
    return (min: toRider(low), max: toRider(high));
  }

  /// The part of t in [0, 1] where `from + (to - from) * t` is at most (or at
  /// least) [bound]; empty when start > end.
  static (double, double) _where(double from, double to, double bound, {required bool atMost}) {
    final slope = to - from;
    if (slope == 0) return (atMost ? from <= bound : from >= bound) ? (0, 1) : (1, 0);
    final t = (bound - from) / slope;
    final (start, end) = atMost == slope > 0 ? (double.negativeInfinity, t) : (t, double.infinity);
    return (start < 0 ? 0 : start, end > 1 ? 1 : end);
  }

  Object _literalInput(GuideInput input) {
    final value = switch (input) {
      RiderGuideInput(key: GuideInputKey.ridingStyle) => inputs.ridingStyle?.name,
      PresetGuideInput(:final id) => preset.selections[id]?.id,
      _ => throw StateError('Input "${input.id}" is numeric'),
    };
    if (value == null) throw const _Failure(GuideIssue.missingInput);
    _inputText = switch (input) {
      PresetGuideInput(:final id) => preset.selections[id]!.label,
      _ => inputs.ridingStyle!.label,
    };
    return value is num ? formatSpecNumber(value) : value;
  }

  /// In the rule's `input_unit`, where it has one.
  double _numericInput(GuideInput input) {
    switch (input) {
      case RiderGuideInput(key: GuideInputKey.riderWeight):
        final weight = inputs.riderWeight;
        if (weight == null) throw const _Failure(GuideIssue.missingInput);
        _inputText = '${formatSpecNumber(_round(weight, 1))} ${inputs.riderWeightUnit.label}';
        return convertUnit(weight, inputs.riderWeightUnit, rule.inputUnit!);
      case PresetGuideInput(:final id):
        final spec = PresetSpecKeys.byId(id);
        final value = spec == null ? null : preset.effectiveSpecs.get(spec);
        if (spec == null || value is! num) throw const _Failure(GuideIssue.missingInput);
        _inputText = spec.format(value);
        return value.toDouble();
      case AdjusterGuideInput(:final adjusterId):
        final (input, value) = readAdjuster(adjusterId) ?? (throw const _Failure(GuideIssue.missingInput));
        final number = value.asNum?.toDouble() ?? (throw const _Failure(GuideIssue.missingInput));
        _inputText = '${input.name} ${value.display}${input.unitSuffix()}';
        return switch ((input.unit, rule.inputUnit)) {
          (final KnownUnit from, final KnownUnit to) when from.quantity == to.quantity => convertUnit(number, from, to),
          (_, KnownUnit()) => throw const _Failure(GuideIssue.incompatible),
          _ => number,
        };
      case RiderGuideInput():
        throw StateError('Input "${input.id}" is not numeric');
    }
  }

  _Cell _resolve(GuideCell cell) => switch (cell) {
    GuideNumber(:final value) => () {
      final number = _toRiderDial(_toAdjustmentUnit(value));
      return _NumericCell(number, number, isBand: false);
    }(),
    GuideRangeRef() => () {
      final number = _resolveRangeRef(cell);
      return _NumericCell(number, number, isBand: false);
    }(),
    GuideBand(:final min, :final max) => _bandCell(_resolveScalar(min), _resolveScalar(max)),
    GuideOption(:final option) => switch (adjustment) {
      CategoricalAdjustment(:final options) when options.contains(option) => _DiscreteCell(CategoricalValue([option])),
      _ => throw const _Failure(GuideIssue.incompatible),
    },
    GuideBoolean(:final value) => switch (adjustment) {
      BooleanAdjustment() => _DiscreteCell(BooleanValue(value)),
      _ => throw const _Failure(GuideIssue.incompatible),
    },
  };

  /// A step band with its ends on the nearest clicks, as the value is rounded;
  /// otherwise a click the band reaches by less than half could count as off.
  ({double min, double max}) _settableBand(({double min, double max}) band) {
    final adjustment = this.adjustment;
    if (adjustment is! StepAdjustment) return band;
    final (min, step) = (adjustment.min, adjustment.step);
    double snap(double value) => (min + ((value - min) / step).round() * step).toDouble();
    return (min: snap(band.min), max: snap(band.max));
  }

  /// Mirrored ends of a band trade places.
  static _NumericCell _bandCell(double a, double b) => _NumericCell(a < b ? a : b, a < b ? b : a, isBand: true);

  double _resolveScalar(GuideScalar scalar) => switch (scalar) {
    GuideNumber(:final value) => _toRiderDial(_toAdjustmentUnit(value)),
    GuideRangeRef() => _resolveRangeRef(scalar),
  };

  /// Against the rider's range, so a corrected `max` corrects the value. On a
  /// mirrored dial the catalog's `max` end is the rider's `min`.
  double _resolveRangeRef(GuideRangeRef ref) {
    final dial = _dial;
    if (dial != null && dial.counting == _Counting.unknown) {
      // Only shown, in the catalog's counting.
      if (ref.anchor != GuideAnchor.min && _catalogMaxUnknown) throw const _Failure(GuideIssue.placeholderMax);
      return _anchored(dial.catalog.min.toDouble(), dial.catalog.max.toDouble(), ref.anchor, ref.offset);
    }
    final (min, max) = switch (adjustment) {
      StepAdjustment(:final min, :final max) => (min.toDouble(), max.toDouble()),
      NumericalAdjustment(:final min, :final max) => (min, max),
      _ => throw const _Failure(GuideIssue.incompatible),
    };
    if (ref.anchor != GuideAnchor.min && _hasPlaceholderMax) throw const _Failure(GuideIssue.placeholderMax);
    if (dial?.counting != _Counting.mirrored) return _anchored(min, max, ref.anchor, ref.offset);
    _converted = true;
    final anchor = switch (ref.anchor) {
      GuideAnchor.min => GuideAnchor.max,
      GuideAnchor.max => GuideAnchor.min,
      GuideAnchor.mid => GuideAnchor.mid,
    };
    return _anchored(min, max, anchor, -ref.offset);
  }

  double _anchored(double min, double max, GuideAnchor anchor, num offset) {
    final base = switch (anchor) {
      GuideAnchor.min => min,
      GuideAnchor.max => max,
      GuideAnchor.mid => (min + max) / 2,
    };
    if (!base.isFinite) throw const _Failure(GuideIssue.incompatible);
    return base + _toAdjustmentUnit(offset) - _toAdjustmentUnit(0);
  }

  /// The catalog adjuster [rule] targets.
  late final PresetAdjustmentSpec? _catalogSpec = [
    ...?preset.product?.adjustments,
    for (final value in preset.selections.values) ...value.adjustments,
  ].firstWhereOrNull((spec) => spec.id == rule.target);

  /// The catalog says `max: ~`.
  bool get _catalogMaxUnknown {
    final spec = _catalogSpec;
    return spec != null && spec.raw.containsKey('max') && spec.raw['max'] == null;
  }

  /// The catalog says `max: ~` and the rider hasn't entered the real count.
  bool get _hasPlaceholderMax {
    final adjustment = this.adjustment;
    if (adjustment is! StepAdjustment || adjustment.max != StepAdjustment.unknownMaxPlaceholder) return false;
    return _catalogMaxUnknown;
  }

  /// Guide clicks are authored on the catalog's dial; a turning direction is
  /// known from a dial visualization only.
  late final ({_Counting counting, StepAdjustment catalog})? _dial = () {
    final (adjustment, catalog) = (this.adjustment, _catalogSpec?.build());
    if (adjustment is! StepAdjustment || catalog is! StepAdjustment) return null;
    final (own, theirs) = (adjustment.visualization, catalog.visualization);
    final counting = own.hasDial && theirs.hasDial
        ? (own.isClockwiseDial == theirs.isClockwiseDial ? _Counting.same : _Counting.mirrored)
        : (adjustment.min == catalog.min ? _Counting.same : _Counting.unknown);
    return (counting: counting, catalog: catalog);
  }();

  /// A position on the catalog's dial as one on the rider's: the same number
  /// of clicks from the same end.
  double _toRiderDial(double value) {
    final dial = _dial;
    if (dial == null) return value;
    final (rider, clicks) = (adjustment as StepAdjustment, value - dial.catalog.min);
    switch (dial.counting) {
      case _Counting.same:
        if (rider.min != dial.catalog.min) _converted = true;
        return rider.min + clicks;
      case _Counting.mirrored:
        if (_hasPlaceholderMax) throw const _Failure(GuideIssue.placeholderMax);
        _converted = true;
        return rider.max - clicks;
      case _Counting.unknown:
        return value;
    }
  }

  /// From the rule's `unit` into the adjustment's; SAG may be authored as a
  /// length of its reference travel.
  double _toAdjustmentUnit(num value) {
    final (unit, adjustment) = (rule.unit, this.adjustment);
    if (adjustment is SagAdjustment && unit is KnownUnit && unit.quantity == UnitQuantity.length) {
      return adjustment.fromMillimeters(convertUnit(value.toDouble(), unit, _millimeters)) ??
          (throw const _Failure(GuideIssue.incompatible));
    }
    return switch ((unit, adjustment.unit)) {
      (final KnownUnit from, final KnownUnit to) when from.quantity == to.quantity => convertUnit(
        value.toDouble(),
        from,
        to,
      ),
      (KnownUnit(), _) => throw const _Failure(GuideIssue.incompatible),
      _ => value.toDouble(),
    };
  }

  /// Rounded to what the rider can set: the nearest click; 1 psi or 0.1 bar.
  /// Never capped, so a value beyond the range shows as itself.
  AdjustmentValue _numericValue(double value) {
    switch (adjustment) {
      case StepAdjustment(:final min, :final max, :final step):
        if (_dial case (counting: _Counting.unknown, :final catalog)) {
          final clicks = ((value - catalog.min) / catalog.step).round();
          throw _Failure(GuideIssue.directionUnknown, StepValue(catalog.min + clicks * catalog.step));
        }
        final clicks = ((value - min) / step).round();
        final rounded = StepValue(min + clicks * step);
        if (clicks > (max - min) ~/ step) throw _Failure(GuideIssue.aboveMax, rounded);
        if (clicks < 0) throw _Failure(GuideIssue.belowMin, rounded);
        return rounded;
      case NumericalAdjustment(:final min, :final max, :final unit):
        final rounded = _round(value, _decimals(unit));
        if (rounded > max + _epsilon) throw _Failure(GuideIssue.aboveMax, NumericalValue(rounded));
        if (rounded < min - _epsilon) throw _Failure(GuideIssue.belowMin, NumericalValue(rounded));
        return NumericalValue(rounded);
      default:
        throw const _Failure(GuideIssue.incompatible);
    }
  }

  static int _decimals(AdjustmentUnit? unit) => switch (unit) {
    KnownUnit(quantity: UnitQuantity.pressure, :final unitId) => unitId == PRESSURE.bar.name ? 1 : 0,
    _ => 1,
  };

  static double _round(double value, int decimals) => double.parse(value.toStringAsFixed(decimals));
}
