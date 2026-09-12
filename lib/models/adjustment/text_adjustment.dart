part of 'adjustment.dart';

class TextAdjustment extends Adjustment {
  static const IconData iconData = Icons.text_snippet;

  TextAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
    super.presetKey,
  });

  @override
  TextAdjustment deepCopy() {
    return TextAdjustment(
      name: name,
      notes: notes,
      unit: unit,
      presetKey: presetKey,
    );
  }

  TextAdjustment copyWith({
    Object? id = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? unit = const _Sentinel(),
    Object? presetKey = const _Sentinel(),
  }) {
    return TextAdjustment(
      id: id is _Sentinel ? this.id : (id as String),
      name: name is _Sentinel ? this.name : (name as String),
      notes: notes is _Sentinel ? this.notes : (notes as String?),
      unit: unit is _Sentinel ? this.unit : (unit as AdjustmentUnit?),
      presetKey: presetKey is _Sentinel ? this.presetKey : (presetKey as String?),
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
    'presetKey': presetKey,
  };

  factory TextAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"] as int?;
    switch (version) {
      case null || 1:
        return TextAdjustment(
          id: json["id"] as String?,
          name: json['name'] as String,
          notes: json['notes'] as String?,
          unit: AdjustmentUnit.decode(json['unit'] as String?),
          presetKey: json['presetKey'] as String?,
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
        unit == other.unit &&
        presetKey == other.presetKey;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, notes, unit, presetKey);
  }
}
