import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

part 'boolean_adjustment.dart';
part 'categorical_adjustment.dart';
part 'step_adjustment.dart';
part 'numerical_adjustment.dart';
part 'text_adjustment.dart';
part 'duration_adjustment.dart';

abstract class Adjustment<T> {
  final String id;
  final String name;
  final String? notes;
  final Type valueType;
  final String? unit;

  Adjustment({String? id, required this.name, required this.notes, required this.unit})
    : valueType = T,
      id = id ?? const Uuid().v4();

  Adjustment<T> deepCopy();
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
      case double():
        if (value.toInt().toDouble() == value) {
          return value.toInt().toString();
        } else {
          return value.toStringAsFixed(5).replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), '');
        }
      case int(): return value.toString();
      case Duration():
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        final String hours = twoDigits(value.inHours);
        final String minutes = twoDigits(value.inMinutes.remainder(60));
        final String seconds = twoDigits(value.inSeconds.remainder(60));
        return "$hours:$minutes:$seconds";
      default: return value.toString();
    }
  }

  static Adjustment fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null:
        final type = json['type'];
        switch (type) {
          case 'boolean': return BooleanAdjustment.fromJson(json);
          case 'categorical': return CategoricalAdjustment.fromJson(json);
          case 'step': return StepAdjustment.fromJson(json);
          case 'numerical': return NumericalAdjustment.fromJson(json);
          case 'text': return TextAdjustment.fromJson(json);
          case 'duration': return DurationAdjustment.fromJson(json);
          default:
            throw Exception('Unknown adjustment type: $type');
        }
      default: throw Exception("Json Version $version of Adjustment incompatible."); 
    }
  }
}
