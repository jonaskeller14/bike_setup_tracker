part of 'adjustment.dart';

class TextAdjustment extends Adjustment {
  static const IconData iconData = Icons.text_snippet;

  TextAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
    required super.category,
  });

  @override
  TextAdjustment deepCopy() {
    return TextAdjustment(
      name: name,
      notes: notes,
      unit: unit,
      category: category,
    );
  }
  
  @override
  bool isValidValue(dynamic value) {
    return value is String;
  }

  @override
  Map<String, dynamic> toJson() => {
    'version': 1,
    'id': id,
    'name': name,
    'notes': notes,
    'type': 'text',
    'unit': unit,
    'category': category.toString(),
  };

  factory TextAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null || 1:
        return TextAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: json['unit'] as String?,
          category: AdjustmentCategory.values.firstWhere(
            (e) => e.toString() == json['category'],
          ),
        );
      default: throw Exception("Json Version $version of TextAdjustment incompatible.");
    }
  }

  @override
  IconData getIconData() => TextAdjustment.iconData;

  @override
  String getProperties() {
    return "Text";
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TextAdjustment &&
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
