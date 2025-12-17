part of 'adjustment.dart';

class NumericalAdjustment extends Adjustment<double> {
  double min;
  double max;

  NumericalAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
    double? min,
    double? max,
  }) : min = min ?? double.negativeInfinity,
       max = max ?? double.infinity;

  @override
  NumericalAdjustment deepCopy() {
    return NumericalAdjustment(name: name, notes: notes, unit: unit, min: min, max: max);
  }

  @override
  bool isValidValue(dynamic value) {
    return value is double && value >= min && value <= max;
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'notes': notes,
    'type': 'numerical',
    'valueType': valueType.toString(),
    'unit': unit,
    'min': min.isFinite ? min : null,
    'max': max.isFinite ? max : null,
  };

  @override
  Icon getIcon({double? size, Color? color}) {
    return getIconStatic(size: size, color: color);
  }

  static Icon getIconStatic({double? size, Color? color}) {
    return Icon(Icons.speed, size: size, color: color);
  }

  @override
  String getProperties() {
    return "Range ${min == double.negativeInfinity ? '-∞' : min}..${max == double.infinity ? '∞' : max}, Unit [${unit ?? ''}]";
  }
}
