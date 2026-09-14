part of 'adjustment.dart';

class BooleanAdjustment extends Adjustment {
  static const IconData iconData = Icons.toggle_on;
  
  BooleanAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
    super.presetKey,
  });

  @override
  BooleanAdjustment deepCopy() {
    return BooleanAdjustment(
      name: name,
      notes: notes,
      unit: unit,
      presetKey: presetKey,
    );
  }

  BooleanAdjustment copyWith({
    Object? id = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? unit = const _Sentinel(),
    Object? presetKey = const _Sentinel(),
  }) {
    return BooleanAdjustment(
      id: id is _Sentinel ? this.id : (id as String),
      name: name is _Sentinel ? this.name : (name as String),
      notes: notes is _Sentinel ? this.notes : (notes as String?),
      unit: unit is _Sentinel ? this.unit : (unit as AdjustmentUnit?),
      presetKey: presetKey is _Sentinel ? this.presetKey : (presetKey as String?),
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
    'presetKey': presetKey,
  };

  factory BooleanAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"] as int?;
    switch (version) {
      case null || 1:
        return BooleanAdjustment(
          id: json["id"] as String?,
          name: json['name'] as String,
          notes: json['notes'] as String?,
          unit: AdjustmentUnit.decode(json['unit'] as String?),
          presetKey: json['presetKey'] as String?,
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
        unit == other.unit &&
        presetKey == other.presetKey;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, notes, unit, presetKey);
  }
}
