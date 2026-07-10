import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'adjustment_unit.dart';

export 'adjustment_unit.dart';
export 'value_unit_conversion.dart';

part 'boolean_adjustment.dart';
part 'categorical_adjustment.dart';
part 'duration_adjustment.dart';
part 'numerical_adjustment.dart';
part 'step_adjustment.dart';
part 'text_adjustment.dart';

enum AdjustmentType {
  boolean,
  categorical,
  step,
  numerical,
  text,
  duration;
}

sealed class Adjustment {
  final String id;
  final String name;
  final String? notes;
  final AdjustmentUnit? unit;

  Adjustment({
    String? id,
    required this.name,
    required this.notes,
    required this.unit,
  }) : id = id ?? const Uuid().v4();

  Adjustment deepCopy();
  bool isValidValue(dynamic value);
  Map<String, dynamic> toJson();
  IconData getIconData();

  String unitSuffix() {
    return unit == null ? "" : " ${unit!.label}";
  }

  static const String multiValueSeparator = ', ';

  static String formatValue(dynamic value) {
    switch (value) {
      case null: return '-';
      case String(): return value;
      case bool(): return value ? 'On' : 'Off';
      case double(): return NumberFormat('0.#####', 'en_US').format(value);
      case int(): return value.toString();
      case Duration():
        String twoDigits(int n) => n.toString().padLeft(2, '0');
        return '${twoDigits(value.inHours)}:${twoDigits(value.inMinutes.remainder(60))}:${twoDigits(value.inSeconds.remainder(60))}';
      case List(): return value.isEmpty ? '-' : value.map(formatValue).join(multiValueSeparator);
      default: return value.toString();
    }
  }

  static Adjustment fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null || 1 || 2:
        final typeString = json['type'];
        final type = AdjustmentType.values.firstWhere(
          (e) => e.name == typeString,
          orElse: () => throw Exception('Unknown adjustment type: $typeString'),
        );
        switch (type) {
          case AdjustmentType.boolean: return BooleanAdjustment.fromJson(json);
          case AdjustmentType.categorical: return CategoricalAdjustment.fromJson(json);
          case AdjustmentType.step: return StepAdjustment.fromJson(json);
          case AdjustmentType.numerical: return NumericalAdjustment.fromJson(json);
          case AdjustmentType.text: return TextAdjustment.fromJson(json);
          case AdjustmentType.duration: return DurationAdjustment.fromJson(json);
        }
      default: throw Exception("Json Version $version of Adjustment incompatible.");
    }
  }
}

bool adjustmentValuesEqual(dynamic a, dynamic b) =>
    const DeepCollectionEquality().equals(a, b);

List<String>? categoricalValueAsList(dynamic value) {
  if (value == null) return null;
  if (value is List) return value.cast<String>();
  if (value is String) return [value];
  return null;
}

/// Coerces a stored value to a plain `String` for a [TextAdjustment] field. A
/// correctly-typed value is already a `String`; anything else (e.g. a stray
/// `List` from a malformed/foreign backup) is formatted to text rather than
/// being handed to a `TextEditingController`, which would crash on a non-String.
String? textValueAsString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return Adjustment.formatValue(value);
}

class _Sentinel {
  const _Sentinel();
}
