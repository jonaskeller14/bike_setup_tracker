part of 'adjustment.dart';

class BooleanAdjustment extends Adjustment {
  static const IconData iconData = Icons.toggle_on;
  
  BooleanAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
  });

  @override
  BooleanAdjustment deepCopy() {
    return BooleanAdjustment(
      name: name,
      notes: notes,
      unit: unit,
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
    'unit': unit?.encode(),
  };

  factory BooleanAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null || 1:
        return BooleanAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: AdjustmentUnit.decode(json['unit'] as String?),
        );
      default: throw Exception("Json Version $version of BooleanAdjustment incompatible.");
    }
  }

  factory BooleanAdjustment.fromYaml(Map<String, dynamic> map) {
    _checkPresetKeys(map, const {'name', 'type', 'unit', 'notes'});
    return BooleanAdjustment(
      name: _requirePresetName(map),
      notes: map['notes'] as String?,
      unit: AdjustmentUnit.fromLegacy(map['unit'] as String?),
    );
  }

  @override
  IconData getIconData() => BooleanAdjustment.iconData;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BooleanAdjustment &&
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
