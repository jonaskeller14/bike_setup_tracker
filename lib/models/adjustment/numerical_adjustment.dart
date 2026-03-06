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
    required super.category,
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
      category: category,
      min: min,
      max: max,
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
    'category': category.toString(),
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
          category: AdjustmentCategory.values.firstWhere(
            (e) => e.toString() == json['category'],
          ),
          min: (json['min'] as num?)?.toDouble(),
          max: (json['max'] as num?)?.toDouble(),
        );
      default: throw Exception("Json Version $version of NumericalAdjustment incompatible.");
    }
  }

  @override
  IconData getIconData() => NumericalAdjustment.iconData;

  @override
  String getProperties() {
    return "Range ${min == double.negativeInfinity ? '-∞' : Adjustment.formatValue(min)}..${max == double.infinity ? '∞' : Adjustment.formatValue(max)}";
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NumericalAdjustment &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        name == other.name &&
        notes == other.notes &&
        unit == other.unit &&
        category == other.category &&
        min == other.min &&
        max == other.max;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      notes,
      unit,
      category,
      min,
      max,
    );
  }
}
