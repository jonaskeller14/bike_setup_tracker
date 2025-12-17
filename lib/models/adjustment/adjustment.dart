import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

part 'boolean_adjustment.dart';
part 'categorical_adjustment.dart';
part 'step_adjustment.dart';
part 'numerical_adjustment.dart';
part 'text_adjustment.dart';

abstract class Adjustment<T> {
  final String id;
  String name;
  String? notes;
  final Type valueType;
  String? unit;

  Adjustment({String? id, required this.name, required this.notes, required this.unit})
    : valueType = T,
      id = id ?? const Uuid().v4();

  Adjustment<T> deepCopy();
  bool isValidValue(dynamic value);
  Map<String, dynamic> toJson();
  Icon getIcon({double? size, Color? color});
  String getProperties();

  static String formatValue(dynamic value) {
    if (value == null) {
      return '-';
    } else if (value is String) {
      return value;
    } else if (value is bool) {
      return value ? 'On' : 'Off';
    } else if (value is double) {
      if (value.toInt().toDouble() == value) {
        return value.toInt().toString();
      } else {
        return value.toStringAsFixed(5).replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), '');
      }
    } else if (value is int) {
      return value.toString();
    } else {
      return value.toString();
    }
  }

  static Adjustment fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    switch (type) {
      case 'boolean':
        return BooleanAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: json['unit'] as String?,
        );
      case 'categorical':
        return CategoricalAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: json['unit'] as String?,
          options: List<String>.from(json['options']),
        );
      case 'step':
        return StepAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: json['unit'] as String?,
          step: (json['step'] as num).toInt(),
          min: (json['min'] as num).toInt(),
          max: (json['max'] as num).toInt(),
          visualization: StepAdjustmentVisualization.values.firstWhere(
            (e) => e.toString() == json['visualization'],
            orElse: () => StepAdjustmentVisualization.slider,
          ),
        );
      case 'numerical':
        return NumericalAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: json['unit'] as String?,
          min: (json['min'] as num?)?.toDouble(),
          max: (json['max'] as num?)?.toDouble(),
        );
      case 'text':
        return TextAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: json['unit'] as String?,
        );
      default:
        throw Exception('Unknown adjustment type: $type');
    }
  }
}
