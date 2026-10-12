import 'package:collection/collection.dart';
import 'package:yaml/yaml.dart';

import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/component/component_catalog.dart';
import '../models/component/preset_spec_keys.dart';
import '../models/component/setup_guide.dart';
import '../models/task/task_rule.dart';
import '../models/task/task_template.dart';
import '../models/task/task_threshold/task_threshold.dart';
import 'task_presets.dart';
import 'unit_conversion.dart';

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

  final parser = _CatalogParser(brand, componentType)
    ..parseOptionValues(doc['option_values'])
    ..parseGuides(doc['guides']);

  final rawNodes = doc['nodes'];
  if (rawNodes is! YamlList || rawNodes.isEmpty) {
    throw FormatException('Catalog file for $brand is missing a "nodes" list');
  }

  final nodes = parser.parseNodes(rawNodes, const _Inherited());
  parser.checkGuides(nodes);
  return BrandCatalog(
    brand: brand,
    id: _slug(brand),
    componentType: componentType,
    nodes: nodes,
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
  final String? setupGuide;
  final SetupGuide? guide;
  final String? note;
  final List<String> missingAdjustments;
  final Map<String, TaskTemplateOverride> tasks;
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
    this.setupGuide,
    this.guide,
    this.note,
    this.missingAdjustments = const [],
    this.tasks = const {},
    this.adjustments,
    this.options,
  });
}

typedef _Size = ({num? eyeToEyeMm, num strokeMm, String? mount, String? label});

/// A product a guide is attached to, with the node id of each level on its path.
typedef _Attachment = ({Map<String, String> levels, CatalogProduct product});

/// A guide rule's target as the rider gets it. [unknownMax] marks a step
/// adjuster authored with `max: ~`, whose built max is only a placeholder.
typedef _Target = ({Adjustment adjustment, bool unknownMax});

class _CatalogParser {
  final String brand;
  final ComponentType componentType;

  /// `option_values`: axis id → value id → definition.
  final Map<String, Map<String, OptionValue>> _definitions = {};

  /// `guides`: guide id → guide, referenced from nodes by `guide:`.
  final Map<String, SetupGuide> _guides = {};

  _CatalogParser(this.brand, this.componentType);

  static final _levelPattern = RegExp(r'^[a-z][a-z0-9_]*$');
  static final _sizeShorthand = RegExp(
    r'^(?:(\d+(?:\.\d+)?)x)?(\d+(?:\.\d+)?(?:/\d+(?:\.\d+)?)*)$',
  );
  static final _taskKeyPattern = RegExp(r'^([a-z][a-z0-9_]*):[a-z][a-z0-9_]*$');
  static final _closedBracket = RegExp(r'^(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)$');
  static final _openBelow = RegExp(r'^<\s*(\d+(?:\.\d+)?)$');
  static final _openAbove = RegExp(r'^(\d+(?:\.\d+)?)\s*\+$');
  static final _rangeRef = RegExp(r'^(min|max|mid)(?:\s*([+-])\s*(\d+(?:\.\d+)?))?$');

  bool get _injectsSag => componentType == ComponentType.fork || componentType == ComponentType.shock;

  /// A `tasks:` key outside these is brand-only.
  late final Set<String> _genericTaskKeys = {
    for (final template in taskPresets[componentType] ?? const <TaskTemplate>[]) template.key,
  };

  /// The `<type>` part of an adjuster preset key, e.g. `fork` in `fork:hsc`.
  late final String _adjusterKeyPrefix =
      componentType.name.replaceAllMapped(RegExp('[A-Z]'), (match) => '_${match[0]!.toLowerCase()}');

  /// The `<type>` part a task key of this component type may start with.
  late final Set<String> _taskKeyPrefixes = _genericTaskKeys.isEmpty
      ? {_adjusterKeyPrefix}
      : {for (final key in _genericTaskKeys) key.substring(0, key.indexOf(':'))};

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
      missingAdjustments: _parseNames(raw['missing_adjustments'], '"missing_adjustments" of $where'),
      tasks: raw.containsKey('tasks') ? _parseTasks(raw['tasks'], where) : const {},
    );
  }

  List<String> _parseNames(Object? raw, String where) {
    if (raw == null) return const [];
    if (raw is! YamlList || raw.isEmpty || raw.any((name) => name is! String || name.isEmpty)) {
      throw _error('$where is not a non-empty list of names');
    }
    return List.unmodifiable(raw.cast<String>());
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
      setupGuide: _inheritText(raw, 'setup_guide', parent.setupGuide),
      guide: raw.containsKey('guide') ? _guideReference(raw['guide'], where) : parent.guide,
      note: _inheritText(raw, 'note', parent.note),
      missingAdjustments: raw.containsKey('missing_adjustments')
          ? _parseNames(raw['missing_adjustments'], '"missing_adjustments" of $where')
          : parent.missingAdjustments,
      tasks: raw.containsKey('tasks') ? mergeTaskOverrides(parent.tasks, _parseTasks(raw['tasks'], where)) : parent.tasks,
      adjustments: raw.containsKey('adjustments') ? raw['adjustments'] : parent.adjustments,
      options: raw.containsKey('options') ? raw['options'] : parent.options,
    );

    if (!raw.containsKey('children')) {
      final product = CatalogProduct(
        id: id,
        label: label,
        level: level,
        draft: scope.draft,
        specs: scope.specs,
        category: scope.category,
        years: scope.years,
        url: scope.url,
        setupGuide: scope.setupGuide,
        guide: scope.guide,
        note: scope.note,
        missingAdjustments: scope.missingAdjustments,
        tasks: scope.tasks,
        adjustments: _parseAdjustmentSpecs(scope.adjustments, where),
        options: _parseOptions(scope.options, scope),
      );
      _checkAdjusterIds(product, where);
      return product;
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
      setupGuide: scope.setupGuide,
      guide: scope.guide,
      note: scope.note,
      missingAdjustments: scope.missingAdjustments,
      tasks: scope.tasks,
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

  /// `tasks:` of a node or an option value, by role key. A `~` entry restores
  /// the generic template.
  Map<String, TaskTemplateOverride?> _parseTasks(Object? raw, String where) {
    if (raw is! YamlMap) throw _error('"tasks" of $where is not a map');
    final tasks = <String, TaskTemplateOverride?>{};
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      final prefix = _taskKeyPattern.firstMatch(key)?.group(1);
      if (prefix == null || !_taskKeyPrefixes.contains(prefix)) {
        throw _error('Task key "$key" of $where is not "${_taskKeyPrefixes.join('|')}:<snake_case>"');
      }
      tasks[key] = entry.value == null ? null : _parseTask(key, entry.value, 'task "$key" of $where');
    }
    return tasks;
  }

  TaskTemplateOverride _parseTask(String key, Object? raw, String where) {
    if (raw is! YamlMap) throw _error('${_capitalize(where)} is not a map');
    const templateFields = {'name', 'priority', 'preselected'};
    final unknown = raw.keys
        .map((key) => key.toString())
        .where((key) => !const {'interval', 'fallback', 'source', ...templateFields}.contains(key));
    if (unknown.isNotEmpty) throw _error('Unknown key(s) ${unknown.join(', ')} in $where');

    final generic = _genericTaskKeys.contains(key);
    if (generic && raw.keys.any((field) => templateFields.contains(field.toString()))) {
      throw _error('${_capitalize(where)} overrides a generic task, which keeps its name, priority and preselection');
    }
    final name = raw['name']?.toString();
    if (!generic && (name == null || name.isEmpty)) {
      throw _error('${_capitalize(where)} is no generic ${componentType.name} task, so it needs a "name"');
    }
    final source = raw['source']?.toString();
    if (source == null || source.isEmpty) throw _error('${_capitalize(where)} needs a "source"');

    final interval = _parseThreshold(raw['interval'], '"interval" of $where');
    final fallback = raw['fallback'] == null ? null : _parseThreshold(raw['fallback'], '"fallback" of $where');
    if (fallback != null && !interval.requiresActivityData) {
      throw _error('${_capitalize(where)} has a "fallback", but its interval is already time-based');
    }
    if (fallback != null && fallback.requiresActivityData) {
      throw _error('"fallback" of $where is not in months or days');
    }

    final preselected = raw['preselected'];
    if (preselected != null && preselected is! bool) throw _error('"preselected" of $where is not a boolean');
    final rawPriority = raw['priority'];
    final priority = rawPriority == null
        ? null
        : TaskPriority.values.firstWhere(
            (priority) => priority.name == rawPriority,
            orElse: () => throw _error(
              '"priority" of $where is not one of ${TaskPriority.values.map((priority) => priority.name).join(', ')}',
            ),
          );

    return TaskTemplateOverride(
      interval: interval,
      fallbackInterval: fallback,
      source: source,
      name: name,
      priority: priority,
      preselected: preselected as bool?,
    );
  }

  static final Map<String, ({bool whole, TaskThreshold Function(num value) build})> _thresholdUnits = {
    'distance_km': (whole: false, build: (value) => DistanceThreshold((value * 1000).toDouble())),
    'moving_time_h': (whole: false, build: (value) => MovingTimeThreshold(_hours(value))),
    'elapsed_time_h': (whole: false, build: (value) => ElapsedTimeThreshold(_hours(value))),
    'elevation_m': (whole: false, build: (value) => ElevationThreshold(value.toDouble())),
    'activities': (whole: true, build: (value) => ActivityCountThreshold(value.toInt())),
    'kj': (whole: false, build: (value) => KilojoulesThreshold(value.toDouble())),
    // A month is 30 days, as in the task form.
    'months': (whole: true, build: (value) => DurationThreshold(Duration(days: 30 * value.toInt()))),
    'days': (whole: true, build: (value) => DurationThreshold(Duration(days: value.toInt()))),
  };

  static Duration _hours(num value) => Duration(minutes: (value * 60).round());

  /// A single `unit: value` entry, e.g. `{ moving_time_h: 125 }`.
  TaskThreshold _parseThreshold(Object? raw, String where) {
    if (raw is! YamlMap || raw.length != 1) {
      throw _error('$where is not a single "unit: value" map like { moving_time_h: 125 }');
    }
    final MapEntry(key: rawUnit, :value) = raw.entries.single;
    final unit = _thresholdUnits[rawUnit.toString()];
    if (unit == null) {
      throw _error('Unknown unit "$rawUnit" in $where; use one of ${_thresholdUnits.keys.join(', ')}');
    }
    if (value is! num || value <= 0 || (unit.whole && value is! int)) {
      throw _error('$where needs a positive ${unit.whole ? 'whole number' : 'number'}, not "$value"');
    }
    return unit.build(value);
  }

  List<PresetAdjustmentSpec> _parseAdjustmentSpecs(Object? raw, String where) {
    if (raw == null) return const [];
    if (raw is! YamlList) throw _error('"adjustments" of $where is not a list');
    return raw.map((item) {
      final normalized = _normalize(item);
      if (normalized is! Map<String, dynamic>) {
        throw _error('An adjustment of $where is not a map');
      }
      return PresetAdjustmentSpec(normalized, presetKey: '$_adjusterKeyPrefix:${_adjusterId(normalized, where)}');
    }).toList();
  }

  /// The explicit `id:`, else the slug of `name` with underscores, which is the
  /// id space of the generic template keys (`fork:volume_spacers`).
  String _adjusterId(Map<String, dynamic> raw, String where) {
    final name = raw['name'];
    final explicit = raw['id'];
    if (explicit != null && (explicit is! String || !_levelPattern.hasMatch(explicit))) {
      throw _error('The "id" of adjustment "$name" in $where is not lower_snake_case');
    }
    if (explicit != null) return explicit as String;
    if (name is! String || name.isEmpty) return '';
    final id = _slug(name).replaceAll('-', '_');
    if (!_levelPattern.hasMatch(id)) {
      throw _error('Adjustment "$name" in $where needs an explicit "id"');
    }
    return id;
  }

  /// Ids must be unique within every adjuster set a rider can end up with: the
  /// product's own adjusters plus one choice per required axis.
  void _checkAdjusterIds(CatalogProduct product, String where) {
    final reserved = _injectsSag ? const {kSagAdjusterId} : const <String>{};
    void check(Iterable<PresetAdjustmentSpec> specs, String scope) {
      final seen = {...reserved};
      for (final spec in specs) {
        if (!seen.add(spec.id)) {
          throw _error('Adjuster id "${spec.id}" is used twice in $scope of $where; give one an explicit "id"');
        }
      }
    }

    check(product.adjustments, 'the product');
    for (final axis in product.options.values) {
      for (final value in axis.values) {
        if (value.adjustments.isEmpty) continue;
        check([...product.adjustments, ...value.adjustments], 'option "${axis.id}.${value.id}"');
      }
    }
  }

  /// Parses each guide on its own; what its rules reference is checked by
  /// [checkGuides] once the tree is known.
  void parseGuides(Object? raw) {
    if (raw == null) return;
    if (raw is! YamlMap) throw _error('"guides" is not a map');
    for (final entry in raw.entries) {
      final id = entry.key.toString();
      if (!_levelPattern.hasMatch(id)) throw _error('Guide id "$id" is not lower_snake_case');
      _guides[id] = _parseGuide(id, entry.value);
    }
  }

  SetupGuide? _guideReference(Object? raw, String where) {
    if (raw == null) return null;
    return _guides[raw.toString()] ?? (throw _error('$where references undefined guide "$raw"'));
  }

  SetupGuide _parseGuide(String id, Object? raw) {
    final where = 'guide "$id"';
    if (raw is! YamlMap) throw _error('${_capitalize(where)} is not a map');
    _rejectUnknownKeys(raw, const {'label', 'source', 'rules'}, where);
    final label = raw['label'];
    if (label is! String || label.isEmpty) throw _error('${_capitalize(where)} needs a "label"');
    final source = raw['source'];
    if (source is! String || source.isEmpty) throw _error('${_capitalize(where)} needs a "source"');
    final rawRules = raw['rules'];
    if (rawRules is! YamlList || rawRules.isEmpty) throw _error('"rules" of $where is not a non-empty list');

    final rules = [for (final (index, rule) in rawRules.indexed) _parseRule(rule, 'rule ${index + 1} of $where')];
    _checkSpecificity(rules, where);
    return SetupGuide(id: id, label: label, source: source, rules: _dependencyOrder(rules, where));
  }

  void _rejectUnknownKeys(YamlMap raw, Set<String> allowed, String where) {
    final unknown = raw.keys.map((key) => key.toString()).where((key) => !allowed.contains(key));
    if (unknown.isNotEmpty) throw _error('Unknown key(s) ${unknown.join(', ')} in $where');
  }

  GuideRule _parseRule(Object? raw, String where) {
    if (raw is! YamlMap) throw _error('${_capitalize(where)} is not a map');
    _rejectUnknownKeys(
      raw,
      const {'target', 'unit', 'input', 'input_unit', 'when', 'value', 'rows', 'range', 'comfort_at', 'note'},
      where,
    );

    final target = raw['target'];
    if (target is! String || !_levelPattern.hasMatch(target)) {
      throw _error('${_capitalize(where)} needs a lower_snake_case "target" adjuster id');
    }
    final input = raw['input'] == null ? null : _parseGuideInput(raw['input'].toString(), where);

    final outputs = const ['value', 'rows', 'range'].where(raw.containsKey).toList();
    if (outputs.length != 1) throw _error('${_capitalize(where)} needs exactly one of "value", "rows" or "range"');
    if (outputs.single == 'rows' && input == null) throw _error('"rows" of $where need an "input"');
    if (outputs.single != 'rows' && input != null) throw _error('"input" of $where only applies to "rows"');
    if (raw.containsKey('comfort_at') && outputs.single != 'range') {
      throw _error('"comfort_at" of $where only applies to a "range"');
    }
    final output = switch (outputs.single) {
      'value' => ConstantOutput(_parseCell(raw['value'], '"value" of $where')),
      'range' => switch (raw['range']) {
        [final num min, final num max] when min < max => RangeOutput(
          min,
          max,
          comfortAt: _parseComfortAt(raw['comfort_at'], where),
        ),
        _ => throw _error('"range" of $where is not a [min, max] pair with min < max'),
      },
      _ => LookupOutput(_parseRows(raw['rows'], input!, where)),
    };

    final note = raw['note'];
    if (note != null && (note is! String || note.isEmpty)) throw _error('"note" of $where is not a text');

    return GuideRule(
      target: target,
      unit: _parseGuideUnit(raw['unit'], '"unit" of $where'),
      input: input,
      inputUnit: _parseInputUnit(raw['input_unit'], input, where),
      when: _parseWhen(raw['when'], where),
      output: output,
      note: note as String?,
    );
  }

  GuideAnchor? _parseComfortAt(Object? raw, String where) => switch (raw) {
    null => null,
    'min' => GuideAnchor.min,
    'max' => GuideAnchor.max,
    _ => throw _error('"comfort_at" of $where is neither min nor max'),
  };

  /// A rider input, else a registered option axis or numeric spec key of the
  /// component type, else an adjuster of the product.
  GuideInput _parseGuideInput(String id, String where) {
    if (GuideInputKey.values.firstWhereOrNull((key) => key.id == id) case final key?) return RiderGuideInput(key);

    final axis = PresetOptionAxes.byId(id);
    final spec = PresetSpecKeys.byId(id);
    if (axis != null || spec != null) {
      if (!(axis?.componentTypes ?? spec!.componentTypes).contains(componentType)) {
        throw _error('Input "$id" of $where does not apply to a ${componentType.name}');
      }
      if (axis == null && spec is! SpecKey<num>) throw _error('Input "$id" of $where is a text spec, not a number');
      return PresetGuideInput(id, numeric: axis != null ? axis.spec is SpecKey<num> : true);
    }

    if (!_levelPattern.hasMatch(id)) throw _error('"input" of $where is neither a known input nor an adjuster id');
    return AdjusterGuideInput(id);
  }

  /// The unit of an adjuster input is checked against that adjuster later.
  KnownUnit? _parseInputUnit(Object? raw, GuideInput? input, String where) {
    final unit = _parseGuideUnit(raw, '"input_unit" of $where');
    if (unit != null && input == null) throw _error('"input_unit" of $where needs an "input"');
    if (unit != null && unit is! KnownUnit) throw _error('"input_unit" of $where is not a convertible unit');
    final quantity = switch (input) {
      RiderGuideInput(:final key) => key.quantity,
      _ => null,
    };
    if (input is! AdjusterGuideInput && quantity == null && unit != null) {
      throw _error('Input "${input!.id}" of $where takes no "input_unit"');
    }
    if (quantity != null && (unit as KnownUnit?)?.quantity != quantity) {
      throw _error('Input "${input!.id}" of $where needs an "input_unit" of ${quantity.label.toLowerCase()}');
    }
    return unit as KnownUnit?;
  }

  AdjustmentUnit? _parseGuideUnit(Object? raw, String where) {
    if (raw == null) return null;
    final unit = AdjustmentUnit.fromLegacy(raw.toString());
    if (unit is CustomUnit && !blessedCustomUnitLabels.contains(unit.label)) {
      throw _error('Unknown unit "$raw" in $where');
    }
    return unit;
  }

  /// Whether the cell fits the adjuster is checked by [checkGuides]. Any text
  /// that is no range reference is an option.
  GuideCell _parseCell(Object? raw, String where) {
    if (_parseScalar(raw) case final scalar?) return scalar;
    return switch (raw) {
      bool() => GuideBoolean(raw),
      String() when raw.isNotEmpty => GuideOption(raw),
      [final rawMin, final rawMax] => switch ((_parseScalar(rawMin), _parseScalar(rawMax))) {
        (final min?, final max?) when _ascends(min, max) => GuideBand(min, max),
        _ => throw _error('${_capitalize(where)} is not an ascending [min, max] band of numbers or range references'),
      },
      _ => throw _error(
        '${_capitalize(where)} is not a number, a range reference, a [min, max] band, an option or a boolean',
      ),
    };
  }

  GuideScalar? _parseScalar(Object? raw) {
    if (raw is num) return GuideNumber(raw);
    final match = raw is String ? _rangeRef.firstMatch(raw.trim()) : null;
    if (match == null) return null;
    final anchor = GuideAnchor.values.byName(match[1]!);
    final offset = match[3] == null ? 0 : num.parse(match[3]!) * (match[2] == '-' ? -1 : 1);
    if ((anchor == GuideAnchor.min && offset < 0) || (anchor == GuideAnchor.max && offset > 0)) {
      throw _error('"$raw" lies outside the adjuster range');
    }
    return GuideRangeRef(anchor, offset);
  }

  /// False only where the order is wrong whatever the adjuster's range is.
  static bool _ascends(GuideScalar min, GuideScalar max) => switch ((min, max)) {
    (GuideNumber(value: final a), GuideNumber(value: final b)) => a < b,
    (GuideRangeRef(anchor: final a, offset: final x), GuideRangeRef(anchor: final b, offset: final y)) when a == b =>
      x < y,
    (GuideRangeRef(anchor: GuideAnchor.max), _) || (_, GuideRangeRef(anchor: GuideAnchor.min)) => false,
    _ => true,
  };

  Map<String, List<Object>> _parseWhen(Object? raw, String where) {
    if (raw == null) return const {};
    if (raw is! YamlMap || raw.isEmpty) throw _error('"when" of $where is not a non-empty map');
    return {
      for (final MapEntry(:key, :value) in raw.entries)
        key.toString(): [
          for (final item in value is YamlList && value.isNotEmpty ? value : [value])
            _whenValue(key.toString(), item, where),
        ],
    };
  }

  /// Typed like the persisted preset entry it is compared with: a number for a
  /// literal numeric axis, text otherwise.
  Object _whenValue(String key, Object? raw, String where) {
    if (raw == null || raw is YamlList || raw is YamlMap) {
      throw _error('"when.$key" of $where is not a value or a non-empty list of values');
    }
    if (PresetOptionAxes.byId(key)?.spec case final spec?) return _specValue(spec, raw, where);
    return raw is num ? formatSpecNumber(raw) : raw.toString();
  }

  /// Numeric rows come back sorted ascending.
  List<GuideRow> _parseRows(Object? raw, GuideInput input, String where) {
    if (raw is! YamlMap || raw.isEmpty) throw _error('"rows" of $where is not a non-empty map');
    final rows = [
      for (final MapEntry(:key, :value) in raw.entries)
        GuideRow(
          input.numeric ? _numericRowKey(key, where) : _literalRowKey(input, key, where),
          _parseCell(value, 'row "$key" of $where'),
        ),
    ];
    if (!input.numeric) return rows;
    rows.sort((a, b) => _lowerBound(a.key).compareTo(_lowerBound(b.key)));
    _checkNumericRows(rows, where);
    return rows;
  }

  GuideRowKey _numericRowKey(Object? key, String where) {
    if (key is num) return GuidePoint(key);
    final text = key.toString().trim();
    if (_closedBracket.firstMatch(text) case final match?) {
      final from = num.parse(match[1]!);
      final to = num.parse(match[2]!);
      if (from >= to) throw _error('Bracket "$key" in "rows" of $where does not ascend');
      return GuideBracket(from, to);
    }
    if (_openBelow.firstMatch(text) case final match?) return GuideBracket(null, num.parse(match[1]!));
    if (_openAbove.firstMatch(text) case final match?) return GuideBracket(num.parse(match[1]!), null);
    throw _error('"$key" in "rows" of $where is not a number or a bracket like 120-130, <120 or 250+');
  }

  GuideRowKey _literalRowKey(GuideInput input, Object? key, String where) {
    final value = key is num ? formatSpecNumber(key) : key.toString();
    if (input.id == kRidingStyleKey && !GuideRidingStyle.values.any((style) => style.name == value)) {
      throw _error(
        '"$value" in "rows" of $where is not a riding style (${GuideRidingStyle.values.map((style) => style.name).join(', ')})',
      );
    }
    return GuidePoint(value);
  }

  static num _lowerBound(GuideRowKey key) => switch (key) {
    GuideBracket(:final from) => from ?? double.negativeInfinity,
    GuidePoint(:final value) => value as num,
  };

  /// Closed brackets must be contiguous; an open-ended row continues the
  /// table at its edge.
  void _checkNumericRows(List<GuideRow> rows, String where) {
    final brackets = rows.map((row) => row.key).whereType<GuideBracket>();
    final closed = brackets.where((bracket) => bracket.from != null && bracket.to != null).toList();
    final below = brackets.where((bracket) => bracket.from == null).toList();
    final above = brackets.where((bracket) => bracket.to == null).toList();
    final points = [
      for (final row in rows)
        if (row.key case GuidePoint(:final num value)) value,
    ];
    if (closed.isNotEmpty && points.isNotEmpty) throw _error('"rows" of $where mix brackets and points');
    if (below.length > 1 || above.length > 1) throw _error('"rows" of $where have two open-ended rows at one edge');

    for (var i = 1; i < closed.length; i++) {
      final previous = closed[i - 1].to!;
      final next = closed[i].from!;
      if (previous < next) {
        throw _error('"rows" of $where have a gap between ${formatSpecNumber(previous)} and ${formatSpecNumber(next)}');
      }
      if (previous > next) throw _error('"rows" of $where overlap below ${formatSpecNumber(previous)}');
    }

    final lowEdge = closed.firstOrNull?.from ?? points.firstOrNull ?? above.firstOrNull?.from;
    final highEdge = closed.lastOrNull?.to ?? points.lastOrNull ?? below.firstOrNull?.to;
    if (below.firstOrNull?.to case final edge? when lowEdge != null && edge != lowEdge) {
      throw _error('Open-ended row "<${formatSpecNumber(edge)}" of $where is not at the lower edge of the table');
    }
    if (above.firstOrNull?.from case final edge? when highEdge != null && edge != highEdge) {
      throw _error('Open-ended row "${formatSpecNumber(edge)}+" of $where is not at the upper edge of the table');
    }
  }

  void _checkSpecificity(List<GuideRule> rules, String where) {
    for (var i = 0; i < rules.length; i++) {
      for (var j = i + 1; j < rules.length; j++) {
        final (a, b) = (rules[i], rules[j]);
        if (a.target != b.target || a.specificity != b.specificity) continue;
        final canBothMatch = a.when.keys
            .where(b.when.containsKey)
            .every((key) => a.when[key]!.any(b.when[key]!.contains));
        if (canBothMatch) {
          throw _error(
            'Rules ${i + 1} and ${j + 1} of $where can both recommend "${a.target}" with equal specificity; '
            'tell them apart with "when"',
          );
        }
      }
    }
  }

  /// Stable: a rule moves back only behind the rules that target its input.
  List<GuideRule> _dependencyOrder(List<GuideRule> rules, String where) {
    final remaining = [...rules];
    final ordered = <GuideRule>[];
    while (remaining.isNotEmpty) {
      final next = remaining.firstWhereOrNull(
        (rule) => switch (rule.input) {
          AdjusterGuideInput(:final adjusterId) => !remaining.any((other) => other.target == adjusterId),
          _ => true,
        },
      );
      if (next == null) {
        final edges = {for (final rule in remaining) '${rule.input!.id} → ${rule.target}'};
        throw _error('The adjuster inputs of $where form a cycle: ${edges.join(', ')}');
      }
      remaining.remove(next);
      ordered.add(next);
    }
    return ordered;
  }

  /// Checks every guide's `when:`, targets, inputs and units against the
  /// products it is attached to.
  void checkGuides(List<CatalogNode> nodes) {
    final levelIds = <String, Set<String>>{};
    final axisIds = <String, Set<Object>>{};
    final attachments = <SetupGuide, List<_Attachment>>{};
    void visit(CatalogNode node, Map<String, String> parentLevels) {
      final levels = {...parentLevels, node.level: node.id};
      levelIds.putIfAbsent(node.level, () => {}).add(node.id);
      switch (node) {
        case CatalogGroup(:final children):
          for (final child in children) {
            visit(child, levels);
          }
        case CatalogProduct(:final options):
          for (final axis in options.values) {
            axisIds.putIfAbsent(axis.id, () => {}).addAll(axis.values.map((value) => value.id));
          }
          if (node.guide case final guide?) (attachments[guide] ??= []).add((levels: levels, product: node));
      }
    }

    for (final node in nodes) {
      visit(node, const {});
    }
    for (final MapEntry(key: id, value: guide) in _guides.entries) {
      final products = attachments[guide];
      if (products == null) throw _error('Guide "$id" is not referenced by any product');
      for (final rule in guide.rules) {
        _checkRule(rule, products, levelIds, axisIds, 'a "${rule.target}" rule of guide "$id"');
      }
    }
  }

  void _checkRule(
    GuideRule rule,
    List<_Attachment> attachments,
    Map<String, Set<String>> levelIds,
    Map<String, Set<Object>> axisIds,
    String where,
  ) {
    for (final MapEntry(:key, :value) in rule.when.entries) {
      final Set<Object>? known = key == kRidingStyleKey
          ? {for (final style in GuideRidingStyle.values) style.name}
          : levelIds[key] ?? axisIds[key];
      if (known == null) throw _error('Unknown "when" key "$key" in $where');
      for (final item in value) {
        if (!known.contains(item)) throw _error('"when.$key" of $where names unknown "$item"');
      }
    }

    if (rule.input case PresetGuideInput(numeric: false, :final id)) {
      for (final row in (rule.output as LookupOutput).rows) {
        final value = (row.key as GuidePoint).value;
        if (!(axisIds[id]?.contains(value) ?? false)) {
          throw _error('Row "$value" of $where is no $id offered in this file');
        }
      }
    }

    final applicable = attachments.where((attachment) => _canApply(rule, attachment)).toList();
    if (applicable.isEmpty) throw _error('${_capitalize(where)} matches no product the guide is attached to');

    final targets = [for (final attachment in applicable) ?_adjuster(attachment.product, rule.target)];
    if (targets.isEmpty) {
      throw _error('${_capitalize(where)} targets an adjuster that no product it applies to has');
    }
    final cells = switch (rule.output) {
      ConstantOutput(:final value) => [value],
      LookupOutput(:final rows) => [for (final row in rows) row.cell],
      RangeOutput(:final min, :final max) => [GuideNumber(min), GuideNumber(max)],
    };
    for (final target in targets) {
      _checkUnit(rule.unit, target.adjustment.unit, rule.target, '"unit" of $where');
      for (final cell in cells) {
        _checkCell(cell, target, rule, where);
      }
    }

    if (rule.input case AdjusterGuideInput(:final adjusterId)) {
      for (final attachment in applicable) {
        final adjuster = _adjuster(attachment.product, adjusterId);
        if (adjuster == null) {
          throw _error(
            '${_capitalize(where)} reads adjuster "$adjusterId", which "${attachment.levels.values.join('/')}" does not have',
          );
        }
        _checkUnit(rule.inputUnit, adjuster.adjustment.unit, adjusterId, '"input_unit" of $where');
      }
    }
  }

  /// Every cell must turn into a valid value of the target adjustment.
  void _checkCell(GuideCell cell, _Target target, GuideRule rule, String where) {
    final adjustment = target.adjustment;
    switch ((adjustment, cell)) {
      case (StepAdjustment() || NumericalAdjustment(), GuideNumber(:final value)):
        _checkLimits(value, target, rule.unit, where);
      case (StepAdjustment() || NumericalAdjustment(), GuideRangeRef(:final anchor, :final offset)):
        _checkRangeRef(cell, anchor, offset, target, rule.unit, where);
      case (StepAdjustment() || NumericalAdjustment(), GuideBand(:final min, :final max)):
        _checkCell(min, target, rule, where);
        _checkCell(max, target, rule, where);
      case (CategoricalAdjustment(:final options), GuideOption(:final option)):
        if (!options.contains(option)) {
          throw _error('${_capitalize(where)} recommends "$option", which is no option of "${adjustment.name}"');
        }
      case (BooleanAdjustment(), GuideBoolean()):
        break;
      default:
        throw _error(
          '${_capitalize(where)} recommends ${_describe(cell)}, which a ${adjustment.runtimeType} '
          '"${adjustment.name}" cannot take',
        );
    }
  }

  /// A number must lie within the adjuster's published range, converted into
  /// its unit. SAG authored as a length has no range to compare with.
  void _checkLimits(num value, _Target target, AdjustmentUnit? unit, String where) {
    final converted = _toAdjusterUnit(value, unit, target.adjustment);
    if (converted != null) _checkInRange(converted, formatSpecNumber(value), target, where);
  }

  /// The anchor must be published; where the range is fully known, the
  /// resolved position must lie inside it too.
  void _checkRangeRef(GuideCell cell, GuideAnchor anchor, num offset, _Target target, AdjustmentUnit? unit, String where) {
    final (min, max) = _range(target);
    final base = switch (anchor) {
      GuideAnchor.min => min,
      GuideAnchor.max => max,
      GuideAnchor.mid => (min + max) / 2,
    };
    if (!base.isFinite) {
      // Resolved once the rider enters the real click count.
      if (target.unknownMax) return;
      throw _error(
        '${_capitalize(where)} recommends ${_describe(cell)}, but "${target.adjustment.name}" publishes no '
        '${anchor == GuideAnchor.mid ? 'range' : '${anchor.name}imum'}',
      );
    }
    final shift = _toAdjusterUnit(offset, unit, target.adjustment);
    final zero = _toAdjusterUnit(0, unit, target.adjustment);
    if (shift != null && zero != null) _checkInRange(base + shift - zero, _describe(cell), target, where);
  }

  /// Null where the units cannot be compared.
  static num? _toAdjusterUnit(num value, AdjustmentUnit? unit, Adjustment adjustment) =>
      switch ((unit, adjustment.unit)) {
        (final KnownUnit from, final KnownUnit to) => convertUnit(value.toDouble(), from, to),
        (KnownUnit(), _) => null,
        _ => value,
      };

  static (num, num) _range(_Target target) => switch (target.adjustment) {
    StepAdjustment(:final min, :final max) => (min, target.unknownMax ? double.infinity : max),
    NumericalAdjustment(:final min, :final max) => (min, max),
    _ => throw StateError('No range on ${target.adjustment.runtimeType}'),
  };

  void _checkInRange(num converted, String shown, _Target target, String where) {
    final (min, max) = _range(target);
    // Unit conversions are not exact.
    const tolerance = 1e-6;
    if (converted > max + tolerance) {
      throw _error('${_capitalize(where)} recommends $shown, above the adjuster maximum ${formatSpecNumber(max)}');
    }
    if (converted < min - tolerance) {
      throw _error('${_capitalize(where)} recommends $shown, below the adjuster minimum ${formatSpecNumber(min)}');
    }
  }

  static String _describe(GuideCell cell) => switch (cell) {
    GuideNumber(:final value) => formatSpecNumber(value),
    GuideRangeRef(:final anchor, :final offset) =>
      offset == 0 ? anchor.name : '${anchor.name}${offset < 0 ? '-' : '+'}${formatSpecNumber(offset.abs())}',
    GuideBand(:final min, :final max) => '[${_describe(min)}, ${_describe(max)}]',
    GuideOption(:final option) => '"$option"',
    GuideBoolean(:final value) => '$value',
  };

  /// Whether [rule]'s `when:` can match some configuration of the product. A
  /// rider-side key always can; an axis the product lacks never does.
  bool _canApply(GuideRule rule, _Attachment attachment) => rule.when.entries.every(
    (entry) => switch (entry.key) {
      kRidingStyleKey => true,
      final key when attachment.levels.containsKey(key) => entry.value.contains(attachment.levels[key]),
      final key => attachment.product.options[key]?.values.any((value) => entry.value.contains(value.id)) ?? false,
    },
  );

  /// Adjuster [id] of [product] (option values included) as built, or null
  /// when the product has no such adjuster.
  _Target? _adjuster(CatalogProduct product, String id) {
    if (id == kSagAdjusterId && _injectsSag) {
      return (adjustment: SagAdjustment(name: 'SAG', notes: null), unknownMax: false);
    }
    final spec = [
      ...product.adjustments,
      for (final axis in product.options.values)
        for (final value in axis.values) ...value.adjustments,
    ].firstWhereOrNull((spec) => spec.id == id);
    if (spec == null) return null;
    return (adjustment: spec.build(), unknownMax: spec.raw.containsKey('max') && spec.raw['max'] == null);
  }

  /// A guide value converts into the adjuster's unit, so both must measure the
  /// same quantity. SAG may also be authored as a length.
  void _checkUnit(AdjustmentUnit? authored, AdjustmentUnit? adjuster, String adjusterId, String where) {
    if (adjusterId == kSagAdjusterId && _injectsSag) {
      if (authored == null || authored == adjuster) return;
      if (authored is KnownUnit && authored.quantity == UnitQuantity.length) return;
      throw _error('$where is neither % nor a length, as SAG needs');
    }
    if (adjuster is KnownUnit) {
      if (authored is KnownUnit && authored.quantity == adjuster.quantity) return;
      throw _error('$where needs a unit of ${adjuster.quantity.label.toLowerCase()}, like the adjuster\'s ${adjuster.label}');
    }
    if (authored is KnownUnit) throw _error('$where is ${authored.label}, but adjuster "$adjusterId" has no convertible unit');
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
