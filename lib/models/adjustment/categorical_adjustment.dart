part of 'adjustment.dart';

class CategoricalAdjustment extends Adjustment {
  final Set<String> options;

  static const IconData iconData = Icons.category;

  CategoricalAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
    required super.category,
    required this.options,
  });

  @override
  CategoricalAdjustment deepCopy() {
    return CategoricalAdjustment(
      name: name,
      notes: notes,
      unit: unit,
      category: category,
      options: options,
    );
  }

  @override
  bool isValidValue(dynamic value) {
    return value is String && options.contains(value);
  }

  @override
  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'name': name,
    'notes': notes,
    'type': AdjustmentType.categorical.name,
    'unit': unit,
    'category': category.toString(),
    'options': options.toList(),
  };

  factory CategoricalAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null || 1:
        return CategoricalAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: json['unit'] as String?,
          category: AdjustmentCategory.values.firstWhere(
            (e) => e.toString() == json['category'],
          ),
          options: Set<String>.from(json['options']),
        );
      default: throw Exception("Json Version $version of CategoricalAdjustment incompatible.");
    }
  }

  @override
  IconData getIconData() => CategoricalAdjustment.iconData;

  @override
  String getProperties() {
    return options.join('/');
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CategoricalAdjustment &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        name == other.name &&
        notes == other.notes &&
        unit == other.unit &&
        category == other.category &&
        setEquals(options, other.options);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      notes,
      unit,
      category,
      Object.hashAllUnordered(options),
    );
  }
}
