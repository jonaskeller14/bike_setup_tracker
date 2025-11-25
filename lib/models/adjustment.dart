import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

abstract class Adjustment<T> {
  final String id;
  String name;
  final Type valueType;
  String? unit;

  Adjustment({String? id, required this.name, required this.unit})
    : valueType = T,
      id = id ?? const Uuid().v4();

  Adjustment<T> deepCopy();
  bool isValidValue(T value);
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
        return BooleanAdjustment(id: json["id"], name: json['name'], unit: json['unit'] as String?);
      case 'categorical':
        return CategoricalAdjustment(
          id: json["id"],
          name: json['name'],
          unit: json['unit'] as String?,
          options: List<String>.from(json['options']),
        );
      case 'step':
        return StepAdjustment(
          id: json["id"],
          name: json['name'],
          unit: json['unit'] as String?,
          step: (json['step'] as num).toInt(),
          min: (json['min'] as num).toInt(),
          max: (json['max'] as num).toInt(),
        );
      case 'numerical':
        return NumericalAdjustment(
          id: json["id"],
          name: json['name'],
          unit: json['unit'] as String?,
          min: (json['min'] as num?)?.toDouble(),
          max: (json['max'] as num?)?.toDouble(),
        );
      default:
        throw Exception('Unknown adjustment type: $type');
    }
  }
}

class CategoricalAdjustment extends Adjustment<String> {
  List<String> options;

  CategoricalAdjustment({super.id, required super.name, required super.unit, required this.options});

  @override
  CategoricalAdjustment deepCopy() {
    return CategoricalAdjustment(name: name, unit: unit, options: options);
  }

  @override
  bool isValidValue(String value) {
    return options.contains(value);
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': 'categorical',
    'valueType': valueType.toString(),
    'unit': unit,
    'options': options,
  };

  @override
  Icon getIcon({double? size, Color? color}) {
    return Icon(Icons.category, size: size, color: color,);
  }

  @override
  String getProperties() {
    return options.join('/');
  }
}

class StepAdjustment extends Adjustment<int> {
  int step;
  int min;
  int max;

  StepAdjustment({
    super.id,
    required super.name,
    required super.unit,
    required this.step,
    required this.min,
    required this.max,
  });

  @override
  StepAdjustment deepCopy() {
    return StepAdjustment(name: name, unit: unit, step: step, min: min, max: max);
  }

  @override
  bool isValidValue(int value) {
    return value >= min && value <= max && ((value - min) % step == 0);
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': 'step',
    'valueType': valueType.toString(),
    'unit': unit,
    'step': step,
    'min': min,
    'max': max,
  };

  @override
  Icon getIcon({double? size, Color? color}) {
    return Icon(Icons.format_list_numbered, size: size, color: color);
  }

  @override
  String getProperties() {
    return "Range $min..$max, Step $step";
  }
}

class NumericalAdjustment extends Adjustment<double> {
  double min;
  double max;

  NumericalAdjustment({
    super.id,
    required super.name,
    required super.unit,
    double? min,
    double? max,
  }) : min = min ?? double.negativeInfinity,
       max = max ?? double.infinity;

  @override
  NumericalAdjustment deepCopy() {
    return NumericalAdjustment(name: name, unit: unit, min: min, max: max);
  }

  @override
  bool isValidValue(double value) {
    return value >= min && value <= max;
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': 'numerical',
    'valueType': valueType.toString(),
    'unit': unit,
    'min': min.isFinite ? min : null,
    'max': max.isFinite ? max : null,
  };

  @override
  Icon getIcon({double? size, Color? color}) {
    return Icon(Icons.numbers, size: size, color: color);
  }

  @override
  String getProperties() {
    return "Range $min..$max [${unit ?? ''}]";
  }
}

class BooleanAdjustment extends Adjustment<bool> {
  BooleanAdjustment({super.id, required super.name, required super.unit});

  @override
  BooleanAdjustment deepCopy() {
    return BooleanAdjustment(name: name, unit: unit);
  }
  
  @override
  bool isValidValue(bool value) {
    return true;
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': 'boolean',
    'valueType': valueType.toString(),
    'unit': unit,
  };

  @override
  Icon getIcon({double? size, Color? color}) {
    return Icon(Icons.toggle_on, size: size, color: color);
  }

  @override
  String getProperties() {
    return "On/Off";
  }
}
