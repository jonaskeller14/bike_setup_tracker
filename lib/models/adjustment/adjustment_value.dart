import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

import '../../database/adjustment_value_codec.dart';
import 'adjustment.dart';

sealed class AdjustmentValue {
  const AdjustmentValue();

  /// Decodes a stored [raw] string with the adjustment [type]. Returns `null`
  /// for an absent value (JSON `null`, unparseable legacy scalar, empty text).
  static AdjustmentValue? decode(String raw, AdjustmentType type) {
    final decoded = decodeAdjustmentValue(raw, type);
    if (decoded == null) return null;
    return switch (type) {
      AdjustmentType.boolean => BooleanValue(decoded as bool),
      AdjustmentType.step => StepValue(decoded as int),
      AdjustmentType.numerical => NumericalValue(decoded as double),
      AdjustmentType.text => TextValue.orNull(decoded as String),
      AdjustmentType.categorical => CategoricalValue(decoded as List<String>),
      AdjustmentType.duration => DurationValue(decoded as Duration),
    };
  }

  /// Temporary bridge from the untyped runtime maps; removed once the maps are
  /// typed.
  static AdjustmentValue? fromRuntime(dynamic value) {
    return switch (value) {
      null => null,
      bool() => BooleanValue(value),
      int() => StepValue(value),
      double() => NumericalValue(value),
      String() => TextValue.orNull(value),
      List() => CategoricalValue(value.map((e) => e.toString()).toList()),
      Duration() => DurationValue(value),
      _ => throw ArgumentError.value(value, 'value', 'Unsupported adjustment value type ${value.runtimeType}'),
    };
  }

  /// JSON string as stored in the value tables.
  String encode();

  /// Context-free display text, without unit.
  String get display;

  /// Numeric projection for charts; `null` where the value has no order.
  num? get asNum;

  bool matches(AdjustmentType type);
}

final class BooleanValue extends AdjustmentValue {
  final bool value;

  const BooleanValue(this.value);

  @override
  String encode() => jsonEncode(value);

  @override
  String get display => value ? 'On' : 'Off';

  @override
  num? get asNum => value ? 1 : 0;

  @override
  bool matches(AdjustmentType type) => type == AdjustmentType.boolean;

  @override
  bool operator ==(Object other) => other is BooleanValue && other.value == value;

  @override
  int get hashCode => Object.hash(BooleanValue, value);

  @override
  String toString() => 'BooleanValue($value)';
}

final class StepValue extends AdjustmentValue {
  final int value;

  const StepValue(this.value);

  @override
  String encode() => jsonEncode(value);

  @override
  String get display => value.toString();

  @override
  num? get asNum => value;

  @override
  bool matches(AdjustmentType type) => type == AdjustmentType.step;

  @override
  bool operator ==(Object other) => other is StepValue && other.value == value;

  @override
  int get hashCode => Object.hash(StepValue, value);

  @override
  String toString() => 'StepValue($value)';
}

/// Also used for sag values ([SagAdjustment] is a [NumericalAdjustment]).
final class NumericalValue extends AdjustmentValue {
  final double value;

  const NumericalValue(this.value);

  @override
  String encode() => jsonEncode(value);

  @override
  String get display => NumberFormat('0.#####', 'en_US').format(value);

  @override
  num? get asNum => value;

  @override
  bool matches(AdjustmentType type) => type == AdjustmentType.numerical;

  @override
  bool operator ==(Object other) => other is NumericalValue && other.value == value;

  @override
  int get hashCode => Object.hash(NumericalValue, value);

  @override
  String toString() => 'NumericalValue($value)';
}

final class TextValue extends AdjustmentValue {
  final String value;

  const TextValue._(this.value);

  /// Empty text means "no value", so it yields `null` instead of a [TextValue].
  static TextValue? orNull(String value) => value.isEmpty ? null : TextValue._(value);

  @override
  String encode() => jsonEncode(value);

  @override
  String get display => value;

  @override
  num? get asNum => null;

  @override
  bool matches(AdjustmentType type) => type == AdjustmentType.text;

  @override
  bool operator ==(Object other) => other is TextValue && other.value == value;

  @override
  int get hashCode => Object.hash(TextValue, value);

  @override
  String toString() => 'TextValue($value)';
}

/// Single-select is a one-element list. Equality is order-sensitive.
final class CategoricalValue extends AdjustmentValue {
  final List<String> options;

  CategoricalValue(List<String> options) : options = List.unmodifiable(options);

  @override
  String encode() => jsonEncode(options);

  @override
  String get display {
    if (options.isEmpty) return '-';
    final counts = <String, int>{};
    for (final option in options) {
      counts[option] = (counts[option] ?? 0) + 1;
    }
    return counts.entries
        .map((entry) => entry.value == 1 ? entry.key : '${entry.key} (${entry.value})')
        .join(Adjustment.multiValueSeparator);
  }

  @override
  num? get asNum => null;

  @override
  bool matches(AdjustmentType type) => type == AdjustmentType.categorical;

  @override
  bool operator ==(Object other) =>
      other is CategoricalValue && const ListEquality<String>().equals(other.options, options);

  @override
  int get hashCode => Object.hash(CategoricalValue, const ListEquality<String>().hash(options));

  @override
  String toString() => 'CategoricalValue($options)';
}

final class DurationValue extends AdjustmentValue {
  final Duration value;

  const DurationValue(this.value);

  @override
  String encode() => jsonEncode(value.inMicroseconds);

  @override
  String get display {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(value.inHours)}:${twoDigits(value.inMinutes.remainder(60))}:${twoDigits(value.inSeconds.remainder(60))}';
  }

  /// Seconds.
  @override
  num? get asNum => value.inMicroseconds / Duration.microsecondsPerSecond;

  @override
  bool matches(AdjustmentType type) => type == AdjustmentType.duration;

  @override
  bool operator ==(Object other) => other is DurationValue && other.value == value;

  @override
  int get hashCode => Object.hash(DurationValue, value);

  @override
  String toString() => 'DurationValue($value)';
}

/// A stored value whose adjustment definition is missing, kept losslessly as
/// its [raw] string so it can be written back unchanged.
final class UnresolvedValue extends AdjustmentValue {
  final String raw;

  const UnresolvedValue(this.raw);

  @override
  String encode() => raw;

  @override
  String get display => raw;

  @override
  num? get asNum => null;

  @override
  bool matches(AdjustmentType type) => false;

  @override
  bool operator ==(Object other) => other is UnresolvedValue && other.raw == raw;

  @override
  int get hashCode => Object.hash(UnresolvedValue, raw);

  @override
  String toString() => 'UnresolvedValue($raw)';
}
