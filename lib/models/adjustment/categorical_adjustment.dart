part of 'adjustment.dart';

class CategoricalAdjustment extends Adjustment {
  final Set<String> options;
  final bool multiSelect;

  static const IconData iconData = Icons.category;

  CategoricalAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
    required this.options,
    this.multiSelect = false,
  });

  @override
  CategoricalAdjustment deepCopy() {
    return CategoricalAdjustment(
      name: name,
      notes: notes,
      unit: unit,
      options: options,
      multiSelect: multiSelect,
    );
  }

  @override
  bool isValidValue(dynamic value) {
    // Values are canonically List<String>; a legacy single String is tolerated.
    final list = categoricalValueAsList(value);
    if (list == null || list.isEmpty) return false;
    if (!multiSelect && list.length > 1) return false;
    return list.every(options.contains);
  }

  @override
  Map<String, dynamic> toJson() => {
    'version': multiSelect ? 2 : 1,
    'id': id,
    'name': name,
    'notes': notes,
    'type': AdjustmentType.categorical.name,
    'unit': unit?.encode(),
    'options': options.toList(),
    'multiSelect': multiSelect,
  };

  factory CategoricalAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null || 1 || 2:
        return CategoricalAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: AdjustmentUnit.decode(json['unit'] as String?),
          options: Set<String>.from(json['options']),
          multiSelect: json['multiSelect'] as bool? ?? false,
        );
      default: throw Exception("Json Version $version of CategoricalAdjustment incompatible.");
    }
  }

  factory CategoricalAdjustment.fromYaml(Map<String, dynamic> map) {
    _checkPresetKeys(map, const {'name', 'type', 'options', 'multiSelect', 'unit', 'notes'});
    final rawOptions = map['options'];
    if (rawOptions is! List || rawOptions.isEmpty) {
      throw ArgumentError('Categorical adjustment "${map['name']}" requires a non-empty "options" list');
    }
    return CategoricalAdjustment(
      name: _requirePresetName(map),
      notes: map['notes'] as String?,
      unit: AdjustmentUnit.fromLegacy(map['unit'] as String?),
      options: rawOptions.map((e) => e.toString()).toSet(),
      multiSelect: map['multiSelect'] as bool? ?? false,
    );
  }

  @override
  IconData getIconData() => CategoricalAdjustment.iconData;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CategoricalAdjustment &&
        runtimeType == other.runtimeType &&
        id == other.id &&
        name == other.name &&
        notes == other.notes &&
        unit == other.unit &&
        multiSelect == other.multiSelect &&
        setEquals(options, other.options);
  }

  @override
  int get hashCode {
    return Object.hash(id, name, notes, unit, multiSelect, Object.hashAllUnordered(options));
  }
}
