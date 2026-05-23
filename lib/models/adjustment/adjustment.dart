import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../icons/bike_icons.dart';

part 'boolean_adjustment.dart';
part 'categorical_adjustment.dart';
part 'duration_adjustment.dart';
part 'numerical_adjustment.dart';
part 'step_adjustment.dart';
part 'text_adjustment.dart';

enum AdjustmentCategory {
  component('Component'),
  rating('Rating'),
  body('Body'),
  nutrition('Nutrition'),
  equipment('Equipment');

  final String value;
  const AdjustmentCategory(this.value);
  IconData getIconData() {
    switch (this) {
      case component: return Icons.grid_view_sharp;
      case rating: return Icons.star;
      case body: return Icons.man;
      case nutrition: return Icons.fastfood;
      case equipment: return BikeIcons.equipment;
    }
  }
}

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
  final String? unit;
  final AdjustmentCategory category;

  Adjustment({
    String? id,
    required this.name,
    required this.notes,
    required this.unit,
    required this.category,
  }) : id = id ?? const Uuid().v4();

  Adjustment deepCopy();
  bool isValidValue(dynamic value);
  Map<String, dynamic> toJson();
  IconData getIconData();
  String getProperties();

  String unitSuffix() {
    return unit == null ? "" : " $unit";
  }

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
      default: return value.toString();
    }
  }

  static Adjustment fromJson(Map<String, dynamic> json, {required AdjustmentCategory defaultCategory}) {
    final int? version = json["version"];
    switch (version) {
      case null || 1:
        final typeString = json['type'];
        final type = AdjustmentType.values.firstWhere(
          (e) => e.name == typeString,
          orElse: () => throw Exception('Unknown adjustment type: $typeString'),
        );
        json['category'] = json['category'] ?? defaultCategory.toString();
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

class _Sentinel {
  const _Sentinel();
}
