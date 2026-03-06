part of 'adjustment.dart';

class BooleanAdjustment extends Adjustment {
  static const IconData iconData = Icons.toggle_on;
  
  BooleanAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
    required super.category,
  });

  @override
  BooleanAdjustment deepCopy() {
    return BooleanAdjustment(
      name: name,
      notes: notes,
      unit: unit,
      category: category,
    );
  }
  
  @override
  bool isValidValue(dynamic value) {
    return value is bool;
  }

  @override
  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'name': name,
    'notes': notes,
    'type': AdjustmentType.boolean.name,
    'unit': unit,
    'category': category.toString(),
  };

  factory BooleanAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null || 1:
        return BooleanAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: json['unit'] as String?,
          category: AdjustmentCategory.values.firstWhere(
            (e) => e.toString() == json['category'],
          ),
        );
      default: throw Exception("Json Version $version of BooleanAdjustment incompatible.");
    }
  }

  @override
  IconData getIconData() => BooleanAdjustment.iconData;

  @override
  String getProperties() {
    return "On/Off";
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BooleanAdjustment &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        name == other.name &&
        notes == other.notes &&
        unit == other.unit &&
        category == other.category;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      notes,
      unit,
      category,
    );
  }
}
