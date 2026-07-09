part of 'adjustment.dart';

class TextAdjustment extends Adjustment {
  static const IconData iconData = Icons.text_snippet;

  TextAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
  });

  @override
  TextAdjustment deepCopy() {
    return TextAdjustment(
      name: name,
      notes: notes,
      unit: unit,
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
    'type': AdjustmentType.text.name,
    'unit': unit?.encode(),
  };

  factory TextAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null || 1:
        return TextAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: AdjustmentUnit.decode(json['unit'] as String?),
        );
      default: throw Exception("Json Version $version of TextAdjustment incompatible.");
    }
  }

  @override
  IconData getIconData() => TextAdjustment.iconData;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TextAdjustment &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        name == other.name &&
        notes == other.notes &&
        unit == other.unit;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, notes, unit);
  }
}
