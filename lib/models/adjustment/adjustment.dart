import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'adjustment_unit.dart';
import 'adjustment_value.dart';

export 'adjustment_unit.dart';
export 'adjustment_value.dart';
export 'value_unit_conversion.dart';

part 'boolean_adjustment.dart';
part 'categorical_adjustment.dart';
part 'duration_adjustment.dart';
part 'numerical_adjustment.dart';
part 'sag_adjustment.dart';
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
  final String? presetKey;

  Adjustment({
    String? id,
    required this.name,
    required this.notes,
    required this.unit,
    this.presetKey,
  }) : id = id ?? const Uuid().v4();

  Adjustment deepCopy();
  bool isValidValue(AdjustmentValue value);
  Map<String, dynamic> toJson();
  IconData getIconData();

  AdjustmentType get type => switch (this) {
    BooleanAdjustment() => AdjustmentType.boolean,
    CategoricalAdjustment() => AdjustmentType.categorical,
    StepAdjustment() => AdjustmentType.step,
    NumericalAdjustment() => AdjustmentType.numerical,
    TextAdjustment() => AdjustmentType.text,
    DurationAdjustment() => AdjustmentType.duration,
  };

  String unitSuffix() {
    return unit == null ? "" : " ${unit!.label}";
  }

  static const String multiValueSeparator = ', ';

  static Adjustment fromJson(Map<String, dynamic> json) {
    final int? version = json["version"] as int?;
    switch (version) {
      case null || 1 || 2 || 3:
        final typeString = json['type'] as String;
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

  static Adjustment fromYaml(Map<String, dynamic> map) {
    final typeString = map['type'];
    if (typeString == null) {
      throw ArgumentError('Preset adjustment is missing the required "type" key: $map');
    }
    final type = AdjustmentType.values.firstWhereOrNull((e) => e.name == typeString);
    switch (type) {
      case AdjustmentType.step: return StepAdjustment.fromYaml(map);
      case AdjustmentType.numerical: return NumericalAdjustment.fromYaml(map);
      case AdjustmentType.categorical: return CategoricalAdjustment.fromYaml(map);
      case AdjustmentType.boolean: return BooleanAdjustment.fromYaml(map);
      case AdjustmentType.text:
      case AdjustmentType.duration:
        throw ArgumentError('Preset adjustment type "$typeString" is not supported in data.');
      case null:
        throw ArgumentError('Unknown preset adjustment type "$typeString".');
    }
  }
}

void _checkPresetKeys(Map<String, dynamic> map, Set<String> allowed) {
  final unknown = map.keys.where((k) => !allowed.contains(k)).toList();
  if (unknown.isNotEmpty) {
    throw ArgumentError('Unknown preset adjustment key(s) ${unknown.join(', ')} in $map');
  }
}

String _requirePresetName(Map<String, dynamic> map) {
  final name = map['name'];
  if (name is! String || name.isEmpty) {
    throw ArgumentError('Preset adjustment requires a non-empty "name": $map');
  }
  return name;
}

class _Sentinel {
  const _Sentinel();
}
