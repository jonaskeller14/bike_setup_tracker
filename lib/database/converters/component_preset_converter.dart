import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/component/component_preset.dart';

export '../../models/component/component_preset.dart';

class ComponentPresetConverter extends TypeConverter<ComponentPreset?, String?> {
  const ComponentPresetConverter();

  @override
  ComponentPreset? fromSql(String? fromDb) {
    if (fromDb == null) return null;
    try {
      return ComponentPreset.tryFromJson(json.decode(fromDb));
    } on FormatException {
      // The preset only links back to the catalog, so a broken one must not hide the component.
      return null;
    }
  }

  @override
  String? toSql(ComponentPreset? value) => value == null ? null : json.encode(value.toJson());
}
