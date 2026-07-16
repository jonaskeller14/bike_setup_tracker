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
      unit: unit is _Sentinel ? this.unit : (unit as AdjustmentUnit?),
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
    // v2: `unit` switched from a plain label ("psi") to the structured
    // AdjustmentUnit encoding ("pressure:psi"). Bumped so an older app hard-
    // rejects a newer backup instead of silently importing the canonical
    // string as a raw custom label.
    'version': 2,
    'id': id,
    'name': name,
    'notes': notes,
    'type': AdjustmentType.numerical.name,
    'unit': unit?.encode(),
    'min': min.isFinite ? min : null,
    'max': max.isFinite ? max : null,
  };

  factory NumericalAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null || 1 || 2:  // also bump version in SagAdjustment
        if (json[adjustmentSubtypeKey] == _sagSubtype) return SagAdjustment.fromJson(json);
        return NumericalAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: AdjustmentUnit.decode(json['unit'] as String?),
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
