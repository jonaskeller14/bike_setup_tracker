import 'package:yaml/yaml.dart';

import '../models/component/component.dart';
import '../models/component/component_catalog.dart';
import '../models/component/preset_spec_keys.dart';

/// Parses one brand YAML file of the generic catalog (e.g. `fork/fox.yaml`)
/// into its node tree, with inheritance already applied.
///
/// Pure function over a `String` so the app (asset bundle) and the CI test
/// (filesystem) share it verbatim. YAML anchors/aliases are resolved by the
/// `yaml` package before this parser sees them. Throws a descriptive
/// [FormatException] on malformed data.
BrandCatalog parseCatalogFile(String yamlSource) {
  final doc = loadYaml(yamlSource);
  if (doc is! YamlMap) {
    throw const FormatException('Catalog file root is not a YAML map');
  }

  final brand = _requireString(doc, 'brand');
  final typeString = _requireString(doc, 'component_type');
  final componentType = ComponentType.values.firstWhere(
    (e) => e.name == typeString,
    orElse: () => throw FormatException('Unknown component_type "$typeString"'),
  );

  final parser = _CatalogParser(brand, componentType)..parseOptionValues(doc['option_values']);

  final rawNodes = doc['nodes'];
  if (rawNodes is! YamlList || rawNodes.isEmpty) {
    throw FormatException('Catalog file for $brand is missing a "nodes" list');
  }

  return BrandCatalog(
    brand: brand,
    id: _slug(brand),
    componentType: componentType,
    nodes: parser.parseNodes(rawNodes, const _Inherited()),
  );
}

/// What a node hands down to its subtree. `adjustments` and `options` stay raw
/// until a product is reached, because only the nearest declaration is parsed.
class _Inherited {
  /// Map keys already taken on the path. Level names share this namespace with
  /// the product's option axes, and with the two entries every preset map has.
  final List<String> levels;
  final String path;
  final bool draft;
  final Specs specs;
  final String? category;
  final String? years;
  final String? url;
  final String? note;
  final Object? adjustments;
  final Object? options;

  const _Inherited({
    this.levels = const ['brand', 'component_type'],
    this.path = '',
    this.draft = false,
    this.specs = Specs.empty,
    this.category,
    this.years,
    this.url,
    this.note,
    this.adjustments,
    this.options,
  });
}

typedef _Size = ({num? eyeToEyeMm, num strokeMm, String? mount, String? label});

class _CatalogParser {
  final String brand;
  final ComponentType componentType;

  /// `option_values`: axis id → value id → definition.
  final Map<String, Map<String, OptionValue>> _definitions = {};

  _CatalogParser(this.brand, this.componentType);

  static final _levelPattern = RegExp(r'^[a-z][a-z0-9_]*$');
  static final _sizeShorthand = RegExp(
    r'^(?:(\d+(?:\.\d+)?)x)?(\d+(?:\.\d+)?(?:/\d+(?:\.\d+)?)*)$',
  );

  FormatException _error(String message) => FormatException('$message ($brand)');

  void parseOptionValues(Object? raw) {
    if (raw == null) return;
    if (raw is! YamlMap) throw _error('"option_values" is not a map');
    for (final axisEntry in raw.entries) {
      final axisId = axisEntry.key.toString();
      final axis = _requireAxis(axisId, '"option_values"');
      if (axis.spec != null || axis == PresetOptionAxes.size) {
        throw _error(
          'Option axis "$axisId" lists its values inline, not under "option_values"',
        );
      }
      final rawValues = axisEntry.value;
      if (rawValues is! YamlMap) {
        throw _error('"option_values.$axisId" is not a map');
      }
      _definitions[axisId] = {
        for (final entry in rawValues.entries)
          entry.key.toString(): _parseOptionValue(
            axisId,
            entry.key.toString(),
            entry.value,
          ),
      };
    }
  }

  OptionValue _parseOptionValue(String axisId, String id, Object? raw) {
    final where = 'option value "$axisId.$id"';
    if (raw is! YamlMap) throw _error('${_capitalize(where)} is not a map');
    return OptionValue(
      id: id,
      label: raw['name']?.toString() ?? id,
      description: raw['description']?.toString(),
      specs: _parseSpecs(raw['specs'], where),
      adjustments: _parseAdjustmentSpecs(raw['adjustments'], where),
    );
  }

  List<CatalogNode> parseNodes(YamlList raw, _Inherited parent) {
    final nodes = <CatalogNode>[];
    final ids = <String>{};
    for (final rawNode in raw) {
      final node = _parseNode(rawNode, parent);
      if (!ids.add(node.id)) {
        final siblings = parent.path.isEmpty ? 'the top-level nodes' : 'the children of "${parent.path}"';
        throw _error('Duplicate id "${node.id}" among $siblings');
      }
      nodes.add(node);
    }
    return nodes;
  }

  CatalogNode _parseNode(Object? raw, _Inherited parent) {
    if (raw is! YamlMap) {
      throw _error(
        parent.path.isEmpty ? 'A top-level node is not a map' : 'A child of "${parent.path}" is not a map',
      );
    }
    final label = raw['label']?.toString();
    if (label == null || label.isEmpty) {
      throw _error(
        parent.path.isEmpty
            ? 'A top-level node is missing its "label"'
            : 'A child of "${parent.path}" is missing its "label"',
      );
    }
    final path = parent.path.isEmpty ? label : '${parent.path} › $label';
    final where = '"$path"';

    final level = raw['level']?.toString();
    if (level == null || !_levelPattern.hasMatch(level)) {
      throw _error('$where needs a lower_snake_case "level"');
    }
    if (parent.levels.contains(level)) {
      throw _error('Level "$level" of $where is already taken on its path');
    }

    // The old flat schema put these directly on the trim.
    for (final key in raw.keys) {
      final name = key.toString();
      if (PresetSpecKeys.byId(name) != null || PresetOptionAxes.byId(name) != null) {
        throw _error('"$name" of $where belongs under "specs" or "options"');
      }
    }

    final id = raw.containsKey('id') ? raw['id']?.toString() ?? '' : _slug(label);
    if (id.isEmpty) throw _error('$where needs an explicit "id"');

    final draft = raw.containsKey('draft') ? raw['draft'] : parent.draft;
    if (draft is! bool) throw _error('"draft" of $where is not a boolean');

    final scope = _Inherited(
      levels: [...parent.levels, level],
      path: path,
      draft: draft,
      specs: parent.specs.mergedWith(_parseSpecs(raw['specs'], where)),
      category: _inheritText(raw, 'category', parent.category),
      years: _inheritText(raw, 'years', parent.years),
      url: _inheritText(raw, 'url', parent.url),
      note: _inheritText(raw, 'note', parent.note),
      adjustments: raw.containsKey('adjustments') ? raw['adjustments'] : parent.adjustments,
      options: raw.containsKey('options') ? raw['options'] : parent.options,
    );

    if (!raw.containsKey('children')) {
      return CatalogProduct(
        id: id,
        label: label,
        level: level,
        draft: scope.draft,
        specs: scope.specs,
        category: scope.category,
        years: scope.years,
        url: scope.url,
        note: scope.note,
        adjustments: _parseAdjustmentSpecs(scope.adjustments, where),
        options: _parseOptions(scope.options, scope),
      );
    }

    final rawChildren = raw['children'];
    if (rawChildren is! YamlList || rawChildren.isEmpty) {
      throw _error('"children" of $where is not a non-empty list');
    }
    return CatalogGroup(
      id: id,
      label: label,
      level: level,
      draft: scope.draft,
      specs: scope.specs,
      category: scope.category,
      years: scope.years,
      url: scope.url,
      note: scope.note,
      children: parseNodes(rawChildren, scope),
    );
  }

  Map<String, OptionAxis> _parseOptions(Object? raw, _Inherited scope) {
    if (raw == null) return const {};
    if (raw is! YamlMap) throw _error('"options" of "${scope.path}" is not a map');

    final axes = <String, OptionAxis>{};
    for (final entry in raw.entries) {
      final axisId = entry.key.toString();
      final where = 'option "$axisId" of "${scope.path}"';
      final axis = _requireAxis(axisId, where);
      if (scope.levels.contains(axisId)) {
        throw _error('${_capitalize(where)} collides with a level of the same name');
      }

      final rawValue = entry.value;
      final rawValues = rawValue is YamlList ? rawValue.toList() : [rawValue];
      if (rawValues.isEmpty) throw _error('${_capitalize(where)} has no values');

      final List<OptionValue> values;
      if (axis == PresetOptionAxes.size) {
        values = _expandSizes(rawValues, where);
      } else if (axis.spec case final spec?) {
        values = [
          for (final raw in rawValues) _literalValue(spec, raw, where),
        ];
      } else {
        values = [
          for (final raw in rawValues) _definedValue(axisId, raw, where),
        ];
      }

      final ids = <Object>{};
      for (final value in values) {
        if (!ids.add(value.id)) {
          throw _error('${_capitalize(where)} lists "${value.id}" twice');
        }
      }
      axes[axisId] = OptionAxis(key: axis, values: values);
    }
    return axes;
  }

  OptionValue _literalValue(SpecKey<Object> spec, Object? raw, String where) {
    final value = _specValue(spec, raw, where);
    return OptionValue(
      id: value,
      label: spec.format(value),
      specs: Specs({spec.id: value}),
    );
  }

  OptionValue _definedValue(String axisId, Object? raw, String where) {
    final value = _definitions[axisId]?[raw.toString()];
    if (value == null) {
      throw _error('${_capitalize(where)} references undefined option value "$raw"');
    }
    return value;
  }

  List<OptionValue> _expandSizes(List<Object?> rawValues, String where) {
    final sizes = <_Size>[
      for (final raw in rawValues)
        ...switch (raw) {
          num() => [(eyeToEyeMm: null, strokeMm: raw, mount: null, label: null)],
          String() => _parseSizeShorthand(raw, where),
          YamlMap() => _parseSizeMap(raw, where),
          _ => throw _error('A value of $where is neither a size nor a map'),
        },
    ];

    final counts = <String, int>{};
    for (final size in sizes) {
      counts.update(_sizeId(size), (count) => count + 1, ifAbsent: () => 1);
    }

    return [
      for (final size in sizes)
        OptionValue(
          // The mount only joins the id where it is what tells two sizes apart.
          id: size.mount != null && counts[_sizeId(size)]! > 1
              ? '${_sizeId(size)}-${_slug(size.mount!)}'
              : _sizeId(size),
          label: size.label ?? '${_sizeId(size)} mm',
          specs: Specs({
            PresetSpecKeys.strokeMm.id: size.strokeMm,
            PresetSpecKeys.eyeToEyeMm.id: ?size.eyeToEyeMm,
            PresetSpecKeys.mount.id: ?size.mount,
          }),
        ),
    ];
  }

  /// `"210x50/52.5/55"` is three sizes sharing one eye-to-eye length.
  List<_Size> _parseSizeShorthand(String text, String where) {
    final match = _sizeShorthand.firstMatch(text.trim());
    if (match == null) {
      throw _error(
        '"$text" in $where is not a size like "210x50/52.5/55"; use the map form',
      );
    }
    final eyeToEye = match.group(1);
    return [
      for (final stroke in match.group(2)!.split('/'))
        (
          eyeToEyeMm: eyeToEye == null ? null : num.parse(eyeToEye),
          strokeMm: num.parse(stroke),
          mount: null,
          label: null,
        ),
    ];
  }

  List<_Size> _parseSizeMap(YamlMap raw, String where) {
    const allowed = {'size', 'eye_to_eye_mm', 'stroke_mm', 'mount', 'label'};
    final unknown = raw.keys.map((key) => key.toString()).where((key) => !allowed.contains(key));
    if (unknown.isNotEmpty) {
      throw _error('Unknown key(s) ${unknown.join(', ')} in a size of $where');
    }

    final List<_Size> sizes;
    if (raw.containsKey('size')) {
      if (raw.containsKey('stroke_mm') || raw.containsKey('eye_to_eye_mm')) {
        throw _error('A size of $where mixes "size" with explicit lengths');
      }
      final shorthand = raw['size'];
      sizes = shorthand is num
          ? [(eyeToEyeMm: null, strokeMm: shorthand, mount: null, label: null)]
          : _parseSizeShorthand(shorthand.toString(), where);
    } else {
      final eyeToEye = raw['eye_to_eye_mm'];
      sizes = [
        (
          eyeToEyeMm: eyeToEye == null ? null : _specValue(PresetSpecKeys.eyeToEyeMm, eyeToEye, where),
          strokeMm: _specValue(PresetSpecKeys.strokeMm, raw['stroke_mm'], where),
          mount: null,
          label: null,
        ),
      ];
    }

    final label = raw['label']?.toString();
    if (label != null && sizes.length > 1) {
      throw _error('"label" of a size in $where names ${sizes.length} sizes at once');
    }
    final rawMount = raw['mount'];
    final mount = rawMount == null ? null : _specValue(PresetSpecKeys.mount, rawMount, where);
    return [
      for (final size in sizes)
        (
          eyeToEyeMm: size.eyeToEyeMm,
          strokeMm: size.strokeMm,
          mount: mount,
          label: label,
        ),
    ];
  }

  Specs _parseSpecs(Object? raw, String where) {
    if (raw == null) return Specs.empty;
    if (raw is! YamlMap) throw _error('"specs" of $where is not a map');
    final values = <String, Object>{};
    for (final entry in raw.entries) {
      final id = entry.key.toString();
      final key = PresetSpecKeys.byId(id);
      if (key == null) throw _error('Unknown spec key "$id" in $where');
      if (!key.componentTypes.contains(componentType)) {
        throw _error('Spec key "$id" in $where does not apply to a ${componentType.name}');
      }
      values[id] = _specValue(key, entry.value, where);
    }
    return Specs(values);
  }

  T _specValue<T extends Object>(SpecKey<T> key, Object? raw, String where) {
    try {
      return key.parse(raw);
    } on FormatException catch (e) {
      throw _error('${e.message} in $where');
    }
  }

  OptionAxisKey _requireAxis(String id, String where) {
    final axis = PresetOptionAxes.byId(id);
    if (axis == null) throw _error('Unknown option axis "$id" in $where');
    if (!axis.componentTypes.contains(componentType)) {
      throw _error('Option axis "$id" in $where does not apply to a ${componentType.name}');
    }
    return axis;
  }

  List<PresetAdjustmentSpec> _parseAdjustmentSpecs(Object? raw, String where) {
    if (raw == null) return const [];
    if (raw is! YamlList) throw _error('"adjustments" of $where is not a list');
    return raw.map((item) {
      final normalized = _normalize(item);
      if (normalized is! Map<String, dynamic>) {
        throw _error('An adjustment of $where is not a map');
      }
      return PresetAdjustmentSpec(normalized);
    }).toList();
  }
}

String _sizeId(_Size size) {
  final stroke = formatSpecNumber(size.strokeMm);
  final eyeToEye = size.eyeToEyeMm;
  return eyeToEye == null ? stroke : '${formatSpecNumber(eyeToEye)}x$stroke';
}

String? _inheritText(YamlMap raw, String key, String? inherited) =>
    raw.containsKey(key) ? raw[key]?.toString() : inherited;

String _capitalize(String text) => text[0].toUpperCase() + text.substring(1);

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

/// Accented characters are spelled out rather than stripped — "Öhlins" has to
/// slug to `ohlins`, not `hlins`. Anything unlisted throws (see [_slug]) so a
/// label cannot silently lose a character from an id that is then frozen.
const Map<String, String> _transliterations = <String, String>{
  'ö': 'o',
  'ø': 'o',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ä': 'a',
  'å': 'a',
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ü': 'u',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ñ': 'n',
  'ç': 'c',
  'ý': 'y',
  'æ': 'ae',
  'œ': 'oe',
  'ß': 'ss',
};

String _slug(String input) {
  var value = input.toLowerCase().replaceAll('+', ' plus ').replaceAll('&', ' and ');
  for (final MapEntry(key: from, value: to) in _transliterations.entries) {
    value = value.replaceAll(from, to);
  }
  for (final int rune in value.runes) {
    if (rune > 0x7F) {
      throw FormatException(
        'No transliteration for "${String.fromCharCode(rune)}" in "$input" — give it an '
        'explicit "id", or add one to _transliterations.',
      );
    }
  }
  return value.replaceAll(RegExp('[^a-z0-9]+'), '-').replaceAll(RegExp('^-+|-+\$'), '');
}
