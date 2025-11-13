import 'package:uuid/uuid.dart';

abstract class Adjustment<T> {
  final String id;
  final String name;
  final Type valueType;

  Adjustment({String? id, required this.name})
    : valueType = T,
      id = id ?? const Uuid().v4();

  bool isValidValue(T value);
  Map<String, dynamic> toJson();

  static Adjustment fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    switch (type) {
      case 'boolean':
        return BooleanAdjustment(id: json["id"], name: json['name']);
      case 'categorical':
        return CategoricalAdjustment(
          id: json["id"],
          name: json['name'],
          options: List<String>.from(json['options']),
        );
      case 'step':
        return StepAdjustment(
          id: json["id"],
          name: json['name'],
          step: json['step'],
          min: json['min'],
          max: json['max'],
        );
      case 'numerical':
        return NumericalAdjustment(
          id: json["id"],
          name: json['name'],
          min: (json['min'] as num?)?.toDouble(),
          max: (json['max'] as num?)?.toDouble(),
          unit: json['unit'] as String?, // read unit from JSON
        );
      default:
        throw Exception('Unknown adjustment type: $type');
    }
  }
}

class CategoricalAdjustment extends Adjustment<String> {
  final List<String> options;

  CategoricalAdjustment({super.id, required super.name, required this.options});

  @override
  bool isValidValue(String value) {
    return options.contains(value);
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': 'step',
    'valueType': valueType.toString(),
    'options': options,
  };
}

class StepAdjustment extends Adjustment<int> {
  final int step;
  final int min;
  final int max;

  StepAdjustment({
    super.id,
    required super.name,
    required this.step,
    required this.min,
    required this.max,
  });

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
    'step': step,
    'min': min,
    'max': max,
  };
}

class NumericalAdjustment extends Adjustment<double> {
  final double min;
  final double max;
  final String? unit;

  NumericalAdjustment({
    super.id,
    required super.name,
    double? min,
    double? max,
    this.unit,
  }) : min = min ?? double.negativeInfinity,
       max = max ?? double.infinity;

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
    'min': min.isFinite ? min : null,
    'max': max.isFinite ? max : null,
    'unit': unit,
  };
}

class BooleanAdjustment extends Adjustment<bool> {
  BooleanAdjustment({super.id, required super.name});

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
  };
}
