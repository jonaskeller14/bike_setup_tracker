part of 'adjustment.dart';

class CategoricalAdjustment extends Adjustment {
  final Set<String> options;
  final bool multiSelect;
  final bool counted;

  static const IconData iconData = Icons.category;

  CategoricalAdjustment({
    super.id,
    required super.name,
    required super.notes,
    required super.unit,
    required this.options,
    this.multiSelect = false,
    this.counted = false,
  });

  @override
  CategoricalAdjustment deepCopy() {
    return CategoricalAdjustment(
      name: name,
      notes: notes,
      unit: unit,
      options: options,
      multiSelect: multiSelect,
      counted: counted,
    );
  }

  @override
  bool isValidValue(dynamic value) {
    // Values are canonically List<String>; a legacy single String is tolerated.
    final list = categoricalValueAsList(value);
    if (list == null || list.isEmpty) return false;
    if (!list.every(options.contains)) return false;
    final distinct = list.toSet();
    if (distinct.length > 1 && !multiSelect) return false;
    if (distinct.length != list.length && !counted) return false;
    return true;
  }

  @override
  Map<String, dynamic> toJson() => {
    'version': counted ? 3 : (multiSelect ? 2 : 1),
    'id': id,
    'name': name,
    'notes': notes,
    'type': AdjustmentType.categorical.name,
    'unit': unit?.encode(),
    'options': options.toList(),
    'multiSelect': multiSelect,
    'counted': counted,
  };

  factory CategoricalAdjustment.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null || 1 || 2 || 3:
        return CategoricalAdjustment(
          id: json["id"],
          name: json['name'],
          notes: json['notes'],
          unit: AdjustmentUnit.decode(json['unit'] as String?),
          options: Set<String>.from(json['options']),
          multiSelect: json['multiSelect'] as bool? ?? false,
          counted: json['counted'] as bool? ?? false,
        );
      default: throw Exception("Json Version $version of CategoricalAdjustment incompatible.");
    }
  }

  factory CategoricalAdjustment.fromYaml(Map<String, dynamic> map) {
    _checkPresetKeys(map, const {'name', 'type', 'options', 'multiSelect', 'counted', 'unit', 'notes'});
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
      counted: map['counted'] as bool? ?? false,
    );
  }

  CategoricalAdjustment copyWith({
    Object? id = const _Sentinel(),
    Object? name = const _Sentinel(),
    Object? notes = const _Sentinel(),
    Object? unit = const _Sentinel(),
    Object? options = const _Sentinel(),
    Object? multiSelect = const _Sentinel(),
    Object? counted = const _Sentinel(),
  }) {
    return CategoricalAdjustment(
      id: id is _Sentinel ? this.id : (id as String),
      name: name is _Sentinel ? this.name : (name as String),
      notes: notes is _Sentinel ? this.notes : (notes as String?),
      unit: unit is _Sentinel ? this.unit : (unit as AdjustmentUnit?),
      options: options is _Sentinel ? this.options : (options as Set<String>),
      multiSelect: multiSelect is _Sentinel ? this.multiSelect : (multiSelect as bool),
      counted: counted is _Sentinel ? this.counted : (counted as bool),
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
        counted == other.counted &&
        setEquals(options, other.options);
  }

  @override
  int get hashCode {
    return Object.hash(id, name, notes, unit, multiSelect, counted, Object.hashAllUnordered(options));
  }
}
