import 'package:yaml/yaml.dart';

import '../models/component.dart';
import '../models/component_preset.dart';

/// Parses one brand YAML file (e.g. `fork/fox.yaml`) into a flat list of
/// user-selectable [ComponentPresetVariant]s — one per brand × model × trim.
///
/// Pure function over a `String` so the app (asset bundle) and the CI test
/// (filesystem) share it verbatim. YAML anchors/aliases are resolved by the
/// `yaml` package before this parser sees them. Throws a descriptive
/// [FormatException] on malformed data; the repository catches and skips a bad
/// file at runtime, and the CI catalog test is the correctness gate.
List<ComponentPresetVariant> parseBrandFile(String yamlSource) {
  final doc = loadYaml(yamlSource);
  if (doc is! YamlMap) {
    throw const FormatException('Preset file root is not a YAML map');
  }

  final brand = _requireString(doc, 'brand');
  final typeString = _requireString(doc, 'component_type');
  final componentType = ComponentType.values.firstWhere(
    (e) => e.name == typeString,
    orElse: () => throw FormatException('Unknown component_type "$typeString"'),
  );

  // Dampers, keyed for reference by each trim.
  final dampers = <String, DamperSpec>{};
  final rawDampers = doc['dampers'];
  if (rawDampers is YamlMap) {
    for (final entry in rawDampers.entries) {
      final key = entry.key.toString();
      dampers[key] = _parseDamper(key, entry.value, brand);
    }
  }

  // Models live under a key named after the type: `forks` / `shocks`.
  final modelsKey = '${componentType.name}s';
  final rawModels = doc[modelsKey];
  if (rawModels is! YamlList) {
    throw FormatException('Preset file for $brand is missing a "$modelsKey" list');
  }

  final variants = <ComponentPresetVariant>[];
  for (final rawModel in rawModels) {
    if (rawModel is! YamlMap) {
      throw FormatException('A $modelsKey entry for $brand is not a map');
    }
    final model = _requireString(rawModel, 'model');
    final complete = _boolOrTrue(rawModel['complete']);
    final category = rawModel['category']?.toString();
    final yearRange = rawModel['year_range']?.toString();
    final modelUrl = rawModel['url']?.toString();
    final modelSpring = rawModel['spring']?.toString();
    final wheelSizes = _stringList(rawModel['wheel_size']);
    final modelNote = rawModel['note']?.toString();

    final rawTrims = rawModel['trims'];
    if (rawTrims is! YamlList) {
      throw FormatException('Model "$model" ($brand) is missing a "trims" list');
    }

    for (final rawTrim in rawTrims) {
      if (rawTrim is! YamlMap) {
        throw FormatException('A trim of model "$model" ($brand) is not a map');
      }
      final trim = _requireString(rawTrim, 'trim');

      final trimDampers = _stringList(rawTrim['dampers']).map((key) {
        final spec = dampers[key];
        if (spec == null) {
          throw FormatException('Trim "$model $trim" ($brand) references unknown damper "$key"');
        }
        return spec;
      }).toList();

      variants.add(ComponentPresetVariant(
        brand: brand,
        model: model,
        trim: trim,
        componentType: componentType,
        category: category,
        yearRange: yearRange,
        url: rawTrim['url']?.toString() ?? modelUrl,
        wheelSizes: wheelSizes,
        travelOptions: _numList(rawTrim['travel_mm']),
        strokeOptions: _stringList(rawTrim['stroke_mm']),
        springLabel: rawTrim['spring']?.toString() ?? modelSpring,
        adjustmentSpecs: _parseAdjustmentSpecs(rawTrim['adjustments'], '$model $trim', brand),
        dampers: trimDampers,
        stanchion: rawTrim['stanchion']?.toString(),
        note: rawTrim['note']?.toString() ?? modelNote,
        complete: complete,
      ));
    }
  }

  return variants;
}

DamperSpec _parseDamper(String key, dynamic raw, String brand) {
  if (raw is! YamlMap) {
    throw FormatException('Damper "$key" ($brand) is not a map');
  }
  final info = <String, dynamic>{};
  for (final entry in raw.entries) {
    final k = entry.key.toString();
    if (k == 'name' || k == 'description' || k == 'adjustments') continue;
    info[k] = _normalize(entry.value);
  }
  return DamperSpec(
    key: key,
    name: raw['name']?.toString() ?? key,
    description: raw['description']?.toString(),
    adjustmentSpecs: _parseAdjustmentSpecs(raw['adjustments'], 'damper $key', brand),
    info: info,
  );
}

List<PresetAdjustmentSpec> _parseAdjustmentSpecs(dynamic raw, String context, String brand) {
  if (raw == null) return const [];
  if (raw is! YamlList) {
    throw FormatException('"adjustments" of $context ($brand) is not a list');
  }
  return raw.map((item) {
    final normalized = _normalize(item);
    if (normalized is! Map<String, dynamic>) {
      throw FormatException('An adjustment of $context ($brand) is not a map');
    }
    return PresetAdjustmentSpec(normalized);
  }).toList();
}

/// Recursively converts YAML nodes into plain Dart collections so downstream
/// code (and tests) never depend on `YamlMap`/`YamlList`.
dynamic _normalize(dynamic node) {
  if (node is YamlMap) {
    return <String, dynamic>{
      for (final entry in node.entries) entry.key.toString(): _normalize(entry.value),
    };
  }
  if (node is YamlList) {
    return node.map(_normalize).toList();
  }
  return node;
}

String _requireString(YamlMap map, String key) {
  final value = map[key];
  if (value == null || value.toString().isEmpty) {
    throw FormatException('Missing required "$key"');
  }
  return value.toString();
}

List<String> _stringList(dynamic raw) {
  if (raw == null) return const [];
  if (raw is YamlList) return raw.map((e) => e.toString()).toList();
  return [raw.toString()];
}

List<num> _numList(dynamic raw) {
  if (raw is! YamlList) return const [];
  return raw.whereType<num>().toList();
}

bool _boolOrTrue(dynamic raw) {
  if (raw is bool) return raw;
  return true;
}
