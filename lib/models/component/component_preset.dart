import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'component.dart';
import 'preset_spec_keys.dart';

/// The catalog selection a component was created from: one `<level>: <node id>`
/// entry per tree level plus one `<axis id>: <value id>` entry per chosen
/// option. Level names differ per brand, so apart from [brand] and
/// [componentType] the entries are read by name.
///
/// It may stop short of a product, or name nodes the catalog has since
/// retired; resolving it against the catalog goes as deep as it still matches.
@immutable
class ComponentPreset {
  static const String brandKey = 'brand';
  static const String componentTypeKey = 'component_type';
  static const String yearKey = 'year';
  static const String revisionKey = 'revision';

  /// Entries that are not tree levels, so no level may be named after them.
  static const Set<String> reservedKeys = {brandKey, componentTypeKey, yearKey, revisionKey};

  final Map<String, Object> _entries;

  ComponentPreset(Map<String, Object> entries) : _entries = Map.unmodifiable(entries);

  /// Null unless [json] is an object of strings and numbers, so a malformed
  /// preset only drops the catalog link.
  static ComponentPreset? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    if (!json.values.every((value) => value is String || value is num)) return null;
    return ComponentPreset(Map<String, Object>.from(json));
  }

  /// A node id or an option value id; null when the selection has no entry.
  Object? operator [](String key) => _entries[key];

  /// The brand file's id (`fox`), not its display name.
  Object? get brand => _entries[brandKey];

  ComponentType? get componentType =>
      ComponentType.values.firstWhereOrNull((type) => type.name == _entries[componentTypeKey]);

  /// The exact model year the rider named; null when none was chosen.
  int? get year => switch (_entries[yearKey]) {
    final int year => year,
    _ => null,
  };

  /// The node ids in the order the levels were stored, whatever the levels are
  /// called. A `moved:` redirect is matched against this path.
  List<String> get nodeIds => [
    for (final MapEntry(:key, :value) in _entries.entries)
      if (!reservedKeys.contains(key) && PresetOptionAxes.byId(key) == null) '$value',
  ];

  Map<String, Object> toJson() => _entries;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ComponentPreset && mapEquals(_entries, other._entries);

  @override
  int get hashCode => Object.hashAllUnordered(_entries.entries.map((e) => Object.hash(e.key, e.value)));

  @override
  String toString() => 'ComponentPreset($_entries)';
}
