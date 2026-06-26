part of 'adjustment.dart';

class NumericalAdjustment extends Adjustment {
  final double min;
  final double max;

  static const IconData iconData = Icons.speed;

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
    return NumericalAdjustment(
      name: name,
      notes: notes,
      unit: unit,
      min: min,
      max: max,
    );
  }

  NumericalAdjustment copyWith({
    Object? id = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? unit = const _Sentinel(),
    Object? min = const _Sentinel(),
    Object? max = const _Sentinel(),
  }) {
    return NumericalAdjustment(
      id: id is _Sentinel ? this.id : (id as String),
      name: name is _Sentinel ? this.name : (name as String),
      notes: notes is _Sentinel ? this.notes : (notes as String?),
      unit: unit is _Sentinel ? this.unit : (unit as String?),
      min: min is _Sentinel ? this.min : (min as double?),
      max: max is _Sentinel ? this.max : (max as double?),
    );
  }

  @override
  bool isValidValue(dynamic value) {
    return value is double && value >= min && value <= max;
  }

  @override
  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'name': name,
    'notes': notes,
    'type': AdjustmentType.numerical.name,
    'unit': unit,
    'min': min.isFinite ? min : null,
    'max': max.isFinite ? max : null,
  };

  factory NumericalAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null || 1:
        return NumericalAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: json['unit'] as String?,
          min: (json['min'] as num?)?.toDouble(),
          max: (json['max'] as num?)?.toDouble(),
        );
      default: throw Exception("Json Version $version of NumericalAdjustment incompatible.");
    }
  }

  @override
  IconData getIconData() => NumericalAdjustment.iconData;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NumericalAdjustment &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        name == other.name &&
        notes == other.notes &&
        unit == other.unit &&
        min == other.min &&
        max == other.max;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, notes, unit, min, max);
  }
}
