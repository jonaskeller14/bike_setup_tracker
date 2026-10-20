import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/component_catalog.dart';
import 'package:bike_setup_tracker/models/component/preset_spec_keys.dart';
import 'package:bike_setup_tracker/models/component/setup_guide.dart';
import 'package:bike_setup_tracker/models/component/year_span.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_template.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// The generic catalog parser: a node tree for identity, option axes for
/// configuration, with inheritance applied while parsing.

const _fork = '''
brand: FOX
component_type: fork
option_values:
  damper:
    grip_x2:
      name: GRIP X2
      description: Four-way adjustable.
      valves: 23
      adjustments:
        - { name: HSC, type: step, max: 8 }
        - { name: LSC, type: step, max: ~ }
    grip_x:
      name: GRIP X
      adjustments:
        - { name: Rebound, type: step, max: 17 }
nodes:
  - label: "36"
    level: model
    category: All-Mountain
    note: Model note
    specs: { spring: Air }
    adjustments: &air_spring
      - { name: Pressure, type: numerical, unit: psi, min: 0 }
    children:
      - label: "2025–2026"
        level: generation
        id: "2025"
        years: "2025-2026"
        url: https://ridefox.com/pages/fox-36
        options:
          wheel_size: [29, 27.5]
        children:
          - label: Factory
            level: trim
            specs: { stanchion: Kashima }
            offset_mm: 44
            options:
              damper: [grip_x2, grip_x]
              travel_mm: [150, 160]
              wheel_size: [29, 27.5]
          - label: Performance Elite
            level: trim
            url: https://ridefox.com/pages/fox-36-performance-elite
            note: ~
            specs: { spring: Coil }
            adjustments: []
      - label: "2021–2024"
        level: generation
        id: "2021"
        draft: true
        children:
          - label: Factory
            level: trim
          - label: Rhythm
            level: trim
            draft: false
''';

String _shock(String sizes) =>
    '''
brand: Öhlins
component_type: shock
nodes:
  - label: TTX22
    level: model
    options:
      size: $sizes
''';

CatalogGroup _group(CatalogNode node) => node as CatalogGroup;
CatalogProduct _product(CatalogNode node) => node as CatalogProduct;

/// The first `nodes:` entry of [_fork], re-indented below a wrapper that
/// replaces the file header.
String _forkWith(String header) => '$header\n${_fork.substring(_fork.indexOf('nodes:'))}';

Matcher _throwsFormat(String fragment) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(fragment)),
);

void main() {
  group('tree', () {
    late BrandCatalog catalog;
    late CatalogGroup model;
    late CatalogGroup generation;
    late CatalogProduct factory;
    late CatalogProduct elite;

    setUpAll(() {
      catalog = parseCatalogFile(_fork);
      model = _group(catalog.nodes.single);
      generation = _group(model.children.first);
      factory = _product(generation.children[0]);
      elite = _product(generation.children[1]);
    });

    test('reads the file header', () {
      expect(catalog.brand, 'FOX');
      expect(catalog.id, 'fox');
      expect(catalog.componentType, ComponentType.fork);
    });

    test('a node without children is a product', () {
      expect(model.level, 'model');
      expect(generation.level, 'generation');
      expect(factory.level, 'trim');
      expect(generation.children, everyElement(isA<CatalogProduct>()));
    });

    test('the id defaults to the slug of the label', () {
      expect(model.id, '36');
      expect(factory.id, 'factory');
      expect(elite.id, 'performance-elite');
    });

    test('an explicit id wins over the label', () {
      expect(generation.label, '2025–2026');
      expect(generation.id, '2025');
    });

    test('the brand id spells out accented characters', () {
      expect(parseCatalogFile(_shock('[55]')).id, 'ohlins');
    });

    test('ignores freeform keys', () {
      // `offset_mm` on the trim and `valves` on the damper are human-only.
      expect(factory.specs.keys, unorderedEquals(['spring', 'stanchion']));
    });
  });

  group('inheritance', () {
    late CatalogGroup model;
    late CatalogGroup generation;
    late CatalogProduct factory;
    late CatalogProduct elite;

    setUpAll(() {
      model = _group(parseCatalogFile(_fork).nodes.single);
      generation = _group(model.children.first);
      factory = _product(generation.children[0]);
      elite = _product(generation.children[1]);
    });

    test('url, category, years and note come from the nearest declaration', () {
      expect(factory.category, 'All-Mountain');
      expect(factory.years, const YearSpan(2025, 2026));
      expect(factory.url, 'https://ridefox.com/pages/fox-36');
      expect(factory.note, 'Model note');
      expect(model.years, isNull);

      expect(elite.url, 'https://ridefox.com/pages/fox-36-performance-elite');
    });

    test('an explicit null clears an inherited value', () {
      expect(elite.note, isNull);
    });

    test('specs are merged per key', () {
      expect(factory.specs.get(PresetSpecKeys.spring), 'Air');
      expect(factory.specs.get(PresetSpecKeys.stanchion), 'Kashima');

      expect(elite.specs.get(PresetSpecKeys.spring), 'Coil');
      expect(elite.specs.get(PresetSpecKeys.stanchion), isNull);
    });

    test('adjustments come from the nearest declaration', () {
      expect(factory.adjustments.map((spec) => spec.build().name), ['Pressure']);
      expect(elite.adjustments, isEmpty);
    });

    test('options are replaced as a whole, not merged per axis', () {
      expect(factory.options.keys, ['damper', 'travel_mm', 'wheel_size']);
      expect(elite.options.keys, ['wheel_size']);
    });

    test('draft covers the subtree until a child overrides it', () {
      final legacy = _group(model.children[1]);
      expect(model.draft, isFalse);
      expect(factory.draft, isFalse);
      expect(legacy.draft, isTrue);
      expect(legacy.children[0].draft, isTrue);
      expect(legacy.children[1].draft, isFalse);
    });
  });

  group('options', () {
    late CatalogProduct factory;

    setUpAll(() {
      final model = _group(parseCatalogFile(_fork).nodes.single);
      factory = _product(_group(model.children.first).children.first);
    });

    test('a defined axis resolves its references', () {
      final damper = factory.options['damper']!;
      expect(damper.key, PresetOptionAxes.damper);
      expect(damper.values.map((value) => value.id), ['grip_x2', 'grip_x']);

      final gripX2 = damper.values.first;
      expect(gripX2.label, 'GRIP X2');
      expect(gripX2.description, 'Four-way adjustable.');
      expect(gripX2.adjustments, hasLength(2));
    });

    test('a literal axis turns each value into a spec', () {
      final travel = factory.options['travel_mm']!;
      expect(travel.values.map((value) => value.id), [150, 160]);
      expect(travel.values.map((value) => value.label), ['150 mm', '160 mm']);
      expect(travel.values.last.specs.get(PresetSpecKeys.travelMm), 160);

      final wheel = factory.options['wheel_size']!;
      expect(wheel.values.map((value) => value.id), ['29', '27.5']);
      expect(wheel.values.first.specs.get(PresetSpecKeys.wheelSize), '29');
    });

    test('an axis is required when any value carries adjustments', () {
      expect(factory.options['damper']!.required, isTrue);
      expect(factory.options['travel_mm']!.required, isFalse);
      expect(factory.options['wheel_size']!.required, isFalse);
    });

    test('a single scalar is an axis with one value', () {
      final catalog = parseCatalogFile('''
brand: FOX
component_type: fork
nodes:
  - label: "40"
    level: model
    options: { travel_mm: 203 }
''');
      final travel = _product(catalog.nodes.single).options['travel_mm']!;
      expect(travel.values.single.id, 203);
    });

    test('an unknown max survives into the built adjustment', () {
      final lsc = factory.options['damper']!.values.first.adjustments.last.build();
      expect((lsc as StepAdjustment).max, StepAdjustment.unknownMaxPlaceholder);
      expect(lsc.notes, StepAdjustment.unknownMaxWarning);
    });
  });

  group('size', () {
    List<OptionValue> sizes(String yaml) =>
        _product(parseCatalogFile(_shock(yaml)).nodes.single).options['size']!.values;

    test('the shorthand expands to one value per stroke', () {
      final values = sizes('["210x50/52.5/55", "230x65"]');

      expect(values.map((value) => value.id), ['210x50', '210x52.5', '210x55', '230x65']);
      expect(values.first.label, '210x50 mm');
      expect(values[1].specs.get(PresetSpecKeys.eyeToEyeMm), 210);
      expect(values[1].specs.get(PresetSpecKeys.strokeMm), 52.5);
      expect(values[1].specs.get(PresetSpecKeys.mount), isNull);
    });

    test('a bare number is a stroke-only value', () {
      final values = sizes('[55, 62.5]');

      expect(values.map((value) => value.id), ['55', '62.5']);
      expect(values.first.label, '55 mm');
      expect(values.first.specs.get(PresetSpecKeys.strokeMm), 55);
      expect(values.first.specs.get(PresetSpecKeys.eyeToEyeMm), isNull);
    });

    test('the map form keeps the authored text as the label', () {
      final values = sizes(
        '[{ eye_to_eye_mm: 215.9, stroke_mm: 63.5, label: "8.5x2.5in" }]',
      );

      expect(values.single.id, '215.9x63.5');
      expect(values.single.label, '8.5x2.5in');
      expect(values.single.specs.get(PresetSpecKeys.strokeMm), 63.5);
    });

    test('the map form attaches a mount to a shorthand', () {
      final values = sizes('[{ size: "185x50/55", mount: Trunnion }]');

      expect(values.map((value) => value.id), ['185x50', '185x55']);
      expect(
        values.map((value) => value.specs.get(PresetSpecKeys.mount)),
        everyElement('Trunnion'),
      );
    });

    test('the mount joins the id only where the same size exists twice', () {
      final values = sizes(
        '[{ size: "185x55", mount: Trunnion }, { size: "185x55/50", mount: Standard }]',
      );

      expect(values.map((value) => value.id), [
        '185x55-trunnion',
        '185x55-standard',
        '185x50',
      ]);
    });

    test('a size axis is optional', () {
      final axis = _product(parseCatalogFile(_shock('[55]')).nodes.single).options['size']!;
      expect(axis.required, isFalse);
    });

    test('rejects text that is not a size', () {
      expect(() => sizes('["9.5x3.0in"]'), _throwsFormat('is not a size'));
      expect(() => sizes('["185x55 (Trunnion)"]'), _throwsFormat('is not a size'));
    });

    test('rejects a label that would name several sizes', () {
      expect(
        () => sizes('[{ size: "185x50/55", label: Short }]'),
        _throwsFormat('names 2 sizes'),
      );
    });

    test('rejects unknown keys in the map form', () {
      expect(
        () => sizes('[{ stroke_mm: 55, stroke: 55 }]'),
        _throwsFormat('Unknown key(s) stroke'),
      );
    });

    test('rejects a map form without a stroke', () {
      expect(
        () => sizes('[{ eye_to_eye_mm: 210 }]'),
        _throwsFormat('Spec "stroke_mm"'),
      );
    });

    test('rejects the same size twice', () {
      expect(() => sizes('["210x55", "210x50/55"]'), _throwsFormat('twice'));
    });
  });

  group('rejects', () {
    String fork(String node) =>
        '''
brand: FOX
component_type: fork
option_values:
  damper:
    grip_x2: { name: GRIP X2 }
nodes:
$node
''';

    test('a root that is not a map', () {
      expect(() => parseCatalogFile('- a\n- b'), throwsFormatException);
    });

    test('a level named like a reserved entry of the persisted map', () {
      for (final level in ['year', 'revision', 'brand', 'component_type']) {
        expect(
          () => parseCatalogFile(fork('  - { label: "36", level: $level }')),
          _throwsFormat('already taken'),
          reason: level,
        );
      }
    });

    test('years that are not YYYY or YYYY-YYYY in ascending order', () {
      for (final years in ['"2025–2026"', '"2026-2025"', '"2025-26"', 'soon', '2026']) {
        expect(
          () => parseCatalogFile(fork('  - { label: "36", level: model, years: $years }')),
          _throwsFormat('"years"'),
          reason: years,
        );
      }
    });

    test('a missing brand or component type', () {
      expect(
        () => parseCatalogFile('component_type: fork\nnodes: []'),
        _throwsFormat('"brand"'),
      );
      expect(
        () => parseCatalogFile(_forkWith('brand: FOX\ncomponent_type: spork')),
        _throwsFormat('Unknown component_type'),
      );
    });

    test('a file without nodes', () {
      expect(
        () => parseCatalogFile('brand: FOX\ncomponent_type: fork'),
        _throwsFormat('missing a "nodes" list'),
      );
    });

    test('a node without a label or level', () {
      expect(
        () => parseCatalogFile(fork('  - level: model')),
        _throwsFormat('missing its "label"'),
      );
      expect(
        () => parseCatalogFile(fork('  - label: "36"')),
        _throwsFormat('"level"'),
      );
      expect(
        () => parseCatalogFile(fork('  - { label: "36", level: Model }')),
        _throwsFormat('lower_snake_case'),
      );
    });

    test('an unknown spec key', () {
      expect(
        () => parseCatalogFile(
          fork('  - { label: "36", level: model, specs: { travel_m: 160 } }'),
        ),
        _throwsFormat('Unknown spec key "travel_m"'),
      );
    });

    test('a spec key of another component type', () {
      expect(
        () => parseCatalogFile(
          fork('  - { label: "36", level: model, specs: { stroke_mm: 55 } }'),
        ),
        _throwsFormat('does not apply to a fork'),
      );
    });

    test('a spec value of the wrong type', () {
      expect(
        () => parseCatalogFile(
          fork('  - { label: "36", level: model, specs: { travel_mm: long } }'),
        ),
        _throwsFormat('Spec "travel_mm" expects a num'),
      );
    });

    test('a spec key or option axis placed directly on a node', () {
      expect(
        () => parseCatalogFile(
          fork('  - { label: "36", level: model, travel_mm: [150, 160] }'),
        ),
        _throwsFormat('belongs under "specs" or "options"'),
      );
    });

    test('an unknown option axis', () {
      expect(
        () => parseCatalogFile(
          fork('  - { label: "36", level: model, options: { axle: [15] } }'),
        ),
        _throwsFormat('Unknown option axis "axle"'),
      );
    });

    test('an option axis of another component type', () {
      expect(
        () => parseCatalogFile(
          fork('  - { label: "36", level: model, options: { size: [55] } }'),
        ),
        _throwsFormat('does not apply to a fork'),
      );
    });

    test('an unknown or inline axis under option_values', () {
      expect(
        () => parseCatalogFile(
          _forkWith('''
brand: FOX
component_type: fork
option_values:
  cartridge:
    grip: { name: GRIP }'''),
        ),
        _throwsFormat('Unknown option axis "cartridge"'),
      );
      expect(
        () => parseCatalogFile(
          _forkWith('''
brand: FOX
component_type: fork
option_values:
  travel_mm:
    long: { name: Long }'''),
        ),
        _throwsFormat('lists its values inline'),
      );
    });

    test('a level that collides with an option axis', () {
      expect(
        () => parseCatalogFile(
          fork('''
  - label: GRIP X2
    level: damper
    children:
      - label: Factory
        level: trim
        options: { damper: [grip_x2] }'''),
        ),
        _throwsFormat('collides with a level'),
      );
    });

    test('a level used twice on one path, or a reserved one', () {
      expect(
        () => parseCatalogFile(
          fork('''
  - label: "36"
    level: model
    children:
      - { label: Factory, level: model }'''),
        ),
        _throwsFormat('Level "model"'),
      );
      expect(
        () => parseCatalogFile(fork('  - { label: "36", level: brand }')),
        _throwsFormat('Level "brand"'),
      );
    });

    test('duplicate sibling ids', () {
      expect(
        () => parseCatalogFile(
          fork('''
  - { label: "36", level: model }
  - { label: "36", level: model }'''),
        ),
        _throwsFormat('Duplicate id "36" among the top-level nodes'),
      );
      expect(
        () => parseCatalogFile(
          fork('''
  - label: "36"
    level: model
    children:
      - { label: Factory, level: trim }
      - { label: Kashima, level: trim, id: factory }'''),
        ),
        _throwsFormat('Duplicate id "factory" among the children of "36"'),
      );
    });

    test('a reference to an undefined option value', () {
      expect(
        () => parseCatalogFile(
          fork('  - { label: "36", level: model, options: { damper: [grip_x] } }'),
        ),
        _throwsFormat('references undefined option value "grip_x"'),
      );
    });

    test('an axis without values, or with a value twice', () {
      expect(
        () => parseCatalogFile(
          fork('  - { label: "36", level: model, options: { travel_mm: [] } }'),
        ),
        _throwsFormat('has no values'),
      );
      expect(
        () => parseCatalogFile(
          fork('  - { label: "36", level: model, options: { travel_mm: [160, 160] } }'),
        ),
        _throwsFormat('twice'),
      );
    });

    test('a label that cannot be slugged without an explicit id', () {
      expect(
        () => parseCatalogFile(fork('  - { label: "2025–2026", level: generation }')),
        _throwsFormat('No transliteration'),
      );
      expect(
        () => parseCatalogFile(fork('  - { label: "+", level: trim, id: "" }')),
        _throwsFormat('explicit "id"'),
      );
    });

    test('a draft flag that is not a boolean', () {
      expect(
        () => parseCatalogFile(fork('  - { label: "36", level: model, draft: maybe }')),
        _throwsFormat('"draft"'),
      );
    });

    test('an empty children list', () {
      expect(
        () => parseCatalogFile(fork('  - { label: "36", level: model, children: [] }')),
        _throwsFormat('"children"'),
      );
    });

    test('names the brand and the path in the message', () {
      expect(
        () => parseCatalogFile(
          fork('''
  - label: "36"
    level: model
    children:
      - { label: Factory, level: trim, specs: { colour: black } }'''),
        ),
        _throwsFormat('"36 › Factory" (FOX)'),
      );
    });
  });

  group('adjuster ids', () {
    String fork(String adjustments, {String damper = 'grip_x2: { name: GRIP X2 }'}) =>
        '''
brand: FOX
component_type: fork
option_values:
  damper:
    $damper
nodes:
  - label: "36"
    level: model
    adjustments:
$adjustments
    options:
      damper: [grip_x2]
''';

    CatalogProduct only(String yaml) => _product(parseCatalogFile(yaml).nodes.single);

    test('default to the underscore slug of the name', () {
      final yaml = fork('''
      - { name: Volume Spacers, type: step, max: 6 }
      - { name: HSC, type: step, max: 6 }
      - { name: Pressure (main), type: numerical }''');

      expect(only(yaml).adjustments.map((spec) => spec.id), ['volume_spacers', 'hsc', 'pressure_main']);
    });

    test('an explicit id wins and is not an adjuster key', () {
      final spec = only(fork('      - { name: Rebound, id: lsr, type: step, max: 6 }')).adjustments.single;
      final built = spec.build();

      expect(spec.id, 'lsr');
      expect(built.name, 'Rebound');
      expect(built.presetKey, 'fork:lsr');
    });

    test('a damper adjuster carries its id too', () {
      final product = only(fork(
        '      - { name: Pressure, type: numerical }',
        damper: 'grip_x2: { name: GRIP X2, adjustments: [{ name: LSR, type: step, max: 8 }] }',
      ));

      expect(product.options['damper']!.values.single.adjustments.single.build().presetKey, 'fork:lsr');
    });

    test('reject a duplicate within the product', () {
      expect(
        () => parseCatalogFile(fork('''
      - { name: Pressure, type: numerical }
      - { name: pressure, type: numerical }''')),
        _throwsFormat('Adjuster id "pressure" is used twice'),
      );
    });

    test('reject a duplicate between the product and its damper', () {
      expect(
        () => parseCatalogFile(fork(
          '      - { name: HSC, type: step, max: 6 }',
          damper: 'grip_x2: { name: GRIP X2, adjustments: [{ name: HSC, type: step, max: 8 }] }',
        )),
        _throwsFormat('Adjuster id "hsc" is used twice'),
      );
    });

    test('reject a catalog adjuster that would collide with the injected SAG', () {
      expect(
        () => parseCatalogFile(fork('      - { name: SAG, type: numerical }')),
        _throwsFormat('Adjuster id "sag" is used twice'),
      );
    });

    test('reject an id that is not lower_snake_case', () {
      expect(
        () => parseCatalogFile(fork('      - { name: Rebound, id: LSR, type: step, max: 6 }')),
        _throwsFormat('lower_snake_case'),
      );
    });

    test('reject a name that needs an explicit id', () {
      expect(
        () => parseCatalogFile(fork('      - { name: "2-Step", type: step, max: 6 }')),
        _throwsFormat('needs an explicit "id"'),
      );
    });
  });

  group('tasks', () {
    const tasksYaml = '''
brand: FOX
component_type: fork
option_values:
  damper:
    grip_x2:
      name: GRIP X2
      tasks:
        fork:full_service: { interval: { moving_time_h: 100 }, source: GRIP X2 manual }
    grip:
      name: GRIP
      tasks:
        fork:lower_leg_service: ~
nodes:
  - label: "36"
    level: model
    tasks:
      fork:lower_leg_service: { interval: { moving_time_h: 125 }, fallback: { months: 12 }, source: FOX manual }
      fork:full_service: { interval: { moving_time_h: 125 }, source: FOX manual }
    children:
      - label: Factory
        level: trim
        tasks:
          fork:full_service: { interval: { moving_time_h: 250 }, source: Factory manual }
          fork:air_spring_service:
            name: Air spring service
            interval: { distance_km: 1500 }
            priority: high
            preselected: true
            source: https://example.com/fox
        options:
          damper: [grip_x2, grip]
      - label: Rhythm
        level: trim
        tasks:
          fork:lower_leg_service: ~
''';

    late CatalogGroup model;
    late CatalogProduct factory;
    late CatalogProduct rhythm;

    setUpAll(() {
      model = _group(parseCatalogFile(tasksYaml).nodes.single);
      factory = _product(model.children.first);
      rhythm = _product(model.children.last);
    });

    String fileWith(String tasks) =>
        '''
brand: FOX
component_type: fork
nodes:
  - label: "36"
    level: model
    tasks: $tasks
''';

    TaskTemplateOverride taskOf(String task) => parseCatalogFile(fileWith('{ $task }')).nodes.single.tasks.values.single;

    test('a node overrides a generic key with its source', () {
      final lowerLeg = model.tasks['fork:lower_leg_service']!;
      expect(lowerLeg.interval, const MovingTimeThreshold(Duration(hours: 125)));
      expect(lowerLeg.fallbackInterval, const DurationThreshold(Duration(days: 360)));
      expect(lowerLeg.source, 'FOX manual');
      expect(lowerLeg.name, isNull);
    });

    test('are inherited per key, the nearest declaration wins', () {
      expect(factory.tasks.keys, {'fork:lower_leg_service', 'fork:full_service', 'fork:air_spring_service'});
      expect(factory.tasks['fork:lower_leg_service']!.source, 'FOX manual');
      expect(factory.tasks['fork:full_service']!.interval, const MovingTimeThreshold(Duration(hours: 250)));
    });

    test('~ clears an inherited override', () {
      expect(rhythm.tasks.keys, ['fork:full_service']);
    });

    test('a brand-only key carries its own name, priority and preselection', () {
      final airSpring = factory.tasks['fork:air_spring_service']!;
      expect(airSpring.name, 'Air spring service');
      expect(airSpring.interval, const DistanceThreshold(1500000));
      expect(airSpring.priority, TaskPriority.high);
      expect(airSpring.preselected, isTrue);
    });

    test('an option value keeps its changes, ~ included', () {
      final damper = factory.options['damper']!.values;
      expect(damper.first.tasks['fork:full_service']!.source, 'GRIP X2 manual');
      expect(damper.last.tasks, {'fork:lower_leg_service': null});
    });

    test('reads every threshold unit', () {
      TaskThreshold interval(String unit) => taskOf('fork:full_service: { interval: { $unit }, source: s }').interval;

      expect(interval('distance_km: 2.5'), const DistanceThreshold(2500));
      expect(interval('moving_time_h: 1.5'), const MovingTimeThreshold(Duration(minutes: 90)));
      expect(interval('elapsed_time_h: 50'), const ElapsedTimeThreshold(Duration(hours: 50)));
      expect(interval('elevation_m: 20000'), const ElevationThreshold(20000));
      expect(interval('activities: 5'), const ActivityCountThreshold(5));
      expect(interval('kj: 50000'), const KilojoulesThreshold(50000));
      expect(interval('months: 6'), const DurationThreshold(Duration(days: 180)));
      expect(interval('days: 10'), const DurationThreshold(Duration(days: 10)));
    });

    group('rejects', () {
      test('an unknown unit, or more than one', () {
        expect(
          () => taskOf('fork:full_service: { interval: { hours: 50 }, source: s }'),
          _throwsFormat('Unknown unit "hours"'),
        );
        expect(
          () => taskOf('fork:full_service: { interval: { moving_time_h: 50, days: 10 }, source: s }'),
          _throwsFormat('single "unit: value" map'),
        );
      });

      test('a value that is not positive, or not whole where it must be', () {
        expect(
          () => taskOf('fork:full_service: { interval: { moving_time_h: 0 }, source: s }'),
          _throwsFormat('positive number'),
        );
        expect(
          () => taskOf('fork:full_service: { interval: { distance_km: -5 }, source: s }'),
          _throwsFormat('positive number'),
        );
        expect(
          () => taskOf('fork:full_service: { interval: { months: 1.5 }, source: s }'),
          _throwsFormat('positive whole number'),
        );
      });

      test('a key that is not <type>:<snake_case> for its component type', () {
        expect(
          () => taskOf('full_service: { interval: { days: 10 }, source: s }'),
          _throwsFormat('Task key "full_service"'),
        );
        expect(
          () => taskOf('fork:Full-Service: { interval: { days: 10 }, source: s }'),
          _throwsFormat('Task key "fork:Full-Service"'),
        );
        expect(
          () => taskOf('shock:full_service: { interval: { days: 10 }, source: s }'),
          _throwsFormat('is not "fork:<snake_case>"'),
        );
      });

      test('a key that is no generic task of the type and has no name', () {
        expect(
          () => taskOf('fork:lower_legs: { interval: { days: 10 }, source: s }'),
          _throwsFormat('is no generic fork task, so it needs a "name"'),
        );
      });

      test('a name, priority or preselection on a generic key', () {
        expect(
          () => taskOf('fork:full_service: { name: Service, interval: { days: 10 }, source: s }'),
          _throwsFormat('overrides a generic task'),
        );
        expect(
          () => taskOf('fork:full_service: { preselected: false, interval: { days: 10 }, source: s }'),
          _throwsFormat('overrides a generic task'),
        );
      });

      test('a missing source or interval, or an unknown field', () {
        expect(
          () => taskOf('fork:full_service: { interval: { days: 10 } }'),
          _throwsFormat('needs a "source"'),
        );
        expect(
          () => taskOf('fork:full_service: { source: s }'),
          _throwsFormat('"interval" of task "fork:full_service"'),
        );
        expect(
          () => taskOf('fork:full_service: { interval: { days: 10 }, source: s, notes: x }'),
          _throwsFormat('Unknown key(s) notes'),
        );
      });

      test('a fallback that is ride-based, or for a time-based interval', () {
        expect(
          () => taskOf('fork:full_service: { interval: { moving_time_h: 50 }, fallback: { distance_km: 10 }, source: s }'),
          _throwsFormat('not in months or days'),
        );
        expect(
          () => taskOf('fork:full_service: { interval: { months: 6 }, fallback: { months: 12 }, source: s }'),
          _throwsFormat('already time-based'),
        );
      });

      test('an unknown priority, or a preselection that is not a boolean', () {
        expect(
          () => taskOf('fork:extra: { name: Extra, interval: { days: 10 }, priority: urgent, source: s }'),
          _throwsFormat('"priority"'),
        );
        expect(
          () => taskOf('fork:extra: { name: Extra, interval: { days: 10 }, preselected: maybe, source: s }'),
          _throwsFormat('"preselected"'),
        );
      });

      test('tasks that are not a map, naming the path', () {
        expect(
          () => parseCatalogFile(fileWith('[a]')),
          _throwsFormat('"tasks" of "36" is not a map (FOX)'),
        );
      });
    });
  });

  group('guides', () {
    String guideFork(String rules, {String guideHeader = ''}) =>
        '''
brand: FOX
component_type: fork
guides:
  fox_36:
    label: FOX 36 owner's manual (2027)
    source: https://tech.ridefox.com/fox-36
$guideHeader    rules:
$rules
option_values:
  damper:
    grip_x2:
      name: GRIP X2
      adjustments:
        - { name: HSC, type: step, max: 8 }
        - { name: LSR, type: step, max: 16 }
        - { name: Compression Mode, type: categorical, options: [Open, Medium, Firm] }
        - { name: Lockout, type: boolean }
    grip:
      name: GRIP
      adjustments:
        - { name: Rebound, type: step, max: 13 }
        - { name: LSC, type: step, max: ~ }
nodes:
  - label: "36"
    level: model
    guide: fox_36
    adjustments:
      - { name: Pressure, type: numerical, unit: psi, min: 0, max: 150 }
      - { name: Volume Spacers, type: step, max: 6, visualization: stepper }
      - { name: Preload, type: numerical, unit: mm }
    children:
      - label: Factory
        level: trim
        options:
          damper: [grip_x2]
          travel_mm: [150, 160]
          wheel_size: [29, 27.5]
      - label: Rhythm
        level: trim
        options:
          damper: [grip]
          travel_mm: [150, 160]
      - label: Performance
        level: trim
        guide: ~
''';

    const pressureRule = '''
      - target: pressure
        unit: psi
        input: rider_weight
        input_unit: lb
        rows: { 130-140: 58, 120-130: 54, 140-150: 62 }''';

    List<CatalogNode> trims(String rules) => _group(parseCatalogFile(guideFork(rules)).nodes.single).children;
    List<GuideRule> rulesOf(String rules) => trims(rules).first.guide!.rules;
    GuideRule ruleOf(String rule) => rulesOf(rule).single;
    List<GuideRow> rowsOf(String rule) => (ruleOf(rule).output as LookupOutput).rows;

    group('reads', () {
      test('the guide on every node below its reference, until "guide: ~" clears it', () {
        final [factory, rhythm, performance] = trims(pressureRule);

        expect(factory.guide, same(rhythm.guide));
        expect(factory.guide!.id, 'fox_36');
        expect(factory.guide!.label, "FOX 36 owner's manual (2027)");
        expect(factory.guide!.source, 'https://tech.ridefox.com/fox-36');
        expect(performance.guide, isNull);
      });

      test('bracket rows sorted ascending, with units and input', () {
        final rule = ruleOf(pressureRule);
        final rows = (rule.output as LookupOutput).rows;

        expect(rule.target, 'pressure');
        expect(rule.unit, AdjustmentUnit.fromLegacy('psi'));
        expect((rule.input! as RiderGuideInput).key, GuideInputKey.riderWeight);
        expect(rule.inputUnit, AdjustmentUnit.fromLegacy('lb'));
        expect(rule.when, isEmpty);
        expect([for (final row in rows) ((row.key as GuideBracket).from, (row.key as GuideBracket).to)], [
          (120, 130),
          (130, 140),
          (140, 150),
        ]);
        expect([for (final row in rows) (row.cell as GuideNumber).value], [54, 58, 62]);
      });

      test('open-ended edge rows', () {
        final rows = rowsOf('''
      - { target: pressure, unit: psi, input: rider_weight, input_unit: kg, rows: { 60-70: 60, <60: 55, 70+: 66 } }''');

        expect([for (final row in rows) ((row.key as GuideBracket).from, (row.key as GuideBracket).to)], [
          (null, 60),
          (60, 70),
          (70, null),
        ]);
      });

      test('band cells', () {
        final rows = rowsOf('''
      - { target: pressure, unit: psi, input: rider_weight, input_unit: kg, rows: { 60-70: [85, 95] } }''');

        expect(
          rows.single.cell,
          isA<GuideBand>()
              .having((band) => (band.min as GuideNumber).value, 'min', 85)
              .having((band) => (band.max as GuideNumber).value, 'max', 95),
        );
      });

      test('range references, alone and as band ends', () {
        final rows = rowsOf('''
      - target: lsr
        input: pressure
        input_unit: psi
        rows: { 60: max, 70: max-3, 80: [10, max], 90: min+2, 100: min, 110: mid, 120: mid-0.5 }''');
        (GuideAnchor, num) ref(GuideCell cell) => ((cell as GuideRangeRef).anchor, cell.offset);

        expect([for (final row in rows) if (row.cell is! GuideBand) ref(row.cell)], [
          (GuideAnchor.max, 0),
          (GuideAnchor.max, -3),
          (GuideAnchor.min, 2),
          (GuideAnchor.min, 0),
          (GuideAnchor.mid, 0),
          (GuideAnchor.mid, -0.5),
        ]);
        final band = rows[2].cell as GuideBand;
        expect((band.min as GuideNumber).value, 10);
        expect(ref(band.max), (GuideAnchor.max, 0));
      });

      test('range references on a numerical adjuster with a published range, offset in the rule unit', () {
        expect(ruleOf('      - { target: pressure, unit: bar, value: max-1 }').output, isA<ConstantOutput>());
        expect(ruleOf('      - { target: sag, value: [mid, max] }').output, isA<ConstantOutput>());
      });

      test('an option axis, a numeric spec or a rider input as input', () {
        final [byTravel, bySize] = rulesOf('''
      - { target: volume_spacers, input: travel_mm, rows: { 150: 3, 160: 2 } }
      - { target: volume_spacers, input: wheel_size, when: { trim: factory }, rows: { 29: 2 } }''');

        expect(byTravel.input, isA<PresetGuideInput>().having((input) => (input.id, input.numeric), 'input', ('travel_mm', true)));
        expect(bySize.input, isA<PresetGuideInput>().having((input) => (input.id, input.numeric), 'input', ('wheel_size', false)));
      });

      test('a range whose comfort end is declared', () {
        final [plain, sag] = rulesOf('''
      - { target: pressure, unit: psi, range: [60, 70] }
      - { target: sag, range: [15, 20], comfort_at: max }''');

        expect((plain.output as RangeOutput).comfortAt, isNull);
        expect((sag.output as RangeOutput).comfortAt, GuideAnchor.max);
      });

      test('options of a categorical and states of a boolean adjuster', () {
        final [mode, lockout] = rulesOf('''
      - { target: compression_mode, value: Open }
      - { target: lockout, value: false }''');

        expect((mode.output as ConstantOutput).value, isA<GuideOption>().having((cell) => cell.option, 'option', 'Open'));
        expect((lockout.output as ConstantOutput).value, isA<GuideBoolean>().having((cell) => cell.value, 'value', false));
      });

      test('any click count on an adjuster with an unknown max', () {
        expect((ruleOf('      - { target: lsc, value: 25 }').output as ConstantOutput).value, isA<GuideNumber>());
      });

      test('literal points of a numeric input, sorted ascending', () {
        final rows = rowsOf('''
      - { target: volume_spacers, input: travel_mm, rows: { 160: 2, 150: 3 } }''');

        expect([for (final row in rows) (row.key as GuidePoint).value], [150, 160]);
      });

      test('constants, ranges and notes', () {
        final [hsc, sag] = rulesOf('''
      - { target: hsc, value: 5, when: { damper: grip_x2 }, note: Base tune }
      - { target: sag, range: [15, 20], unit: "%" }''');

        expect((hsc.output as ConstantOutput).value, isA<GuideNumber>().having((cell) => cell.value, 'value', 5));
        expect(hsc.note, 'Base tune');
        expect(hsc.specificity, 1);
        expect(sag.output, isA<RangeOutput>().having((range) => (range.min, range.max), 'range', (15, 20)));
      });

      test('literal inputs keyed by value id', () {
        final [bySize, byStyle] = rulesOf('''
      - { target: volume_spacers, input: wheel_size, rows: { 29: 2, 27.5: 3 } }
      - { target: sag, input: riding_style, rows: { comfort: 20, race: 15 } }''');

        expect([for (final row in (bySize.output as LookupOutput).rows) (row.key as GuidePoint).value], ['29', '27.5']);
        expect([for (final row in (byStyle.output as LookupOutput).rows) (row.key as GuidePoint).value], [
          'comfort',
          'race',
        ]);
      });

      test('when values typed like the persisted preset entries', () {
        final rule = ruleOf('''
      - { target: pressure, unit: psi, value: 80, when: { trim: [factory, rhythm], travel_mm: 160, wheel_size: 29, riding_style: race } }''');

        expect(rule.when, {
          'trim': ['factory', 'rhythm'],
          'travel_mm': [160],
          'wheel_size': ['29'],
          'riding_style': ['race'],
        });
        expect(rule.specificity, 4);
      });

      test('an adjuster input, ordered after the rules that target it', () {
        final rules = rulesOf('''
      - { target: rebound, input: pressure, input_unit: psi, when: { damper: grip }, rows: { 60-80: 10, 80-100: 8 } }
$pressureRule''');

        expect(rules.map((rule) => rule.target), ['pressure', 'rebound']);
        expect(rules.last.input, isA<AdjusterGuideInput>().having((input) => input.adjusterId, 'id', 'pressure'));
      });

      test('a SAG rule authored as a length', () {
        expect(ruleOf('      - { target: sag, unit: mm, range: [24, 32] }').unit, AdjustmentUnit.fromLegacy('mm'));
      });

      test('a more specific rule next to a general one for the same target', () {
        expect(
          rulesOf('''
      - { target: sag, range: [15, 20] }
      - { target: sag, value: 15, when: { riding_style: race } }'''),
          hasLength(2),
        );
      });
    });

    group('rejects', () {
      void rejects(String rules, String fragment) =>
          expect(() => parseCatalogFile(guideFork(rules)), _throwsFormat(fragment));

      test('a reference to an undefined guide, or a guide no product uses', () {
        expect(
          () => parseCatalogFile(guideFork(pressureRule).replaceFirst('guide: fox_36', 'guide: fox_38')),
          _throwsFormat('"36" references undefined guide "fox_38"'),
        );
        expect(
          () => parseCatalogFile(guideFork(pressureRule).replaceFirst('guide: fox_36', 'guide: ~')),
          _throwsFormat('Guide "fox_36" is not referenced by any product'),
        );
      });

      test('unknown keys, a missing label or source, and empty rules', () {
        expect(
          () => parseCatalogFile(guideFork(pressureRule, guideHeader: '    year: 2027\n')),
          _throwsFormat('Unknown key(s) year in guide "fox_36"'),
        );
        rejects('      - { target: pressure, unit: psi, value: 80, unti: psi }', 'Unknown key(s) unti in rule 1');
        expect(
          () => parseCatalogFile(guideFork(pressureRule).replaceFirst(RegExp(r'    label: .*\n'), '')),
          _throwsFormat('Guide "fox_36" needs a "label"'),
        );
        expect(
          () => parseCatalogFile(guideFork(pressureRule).replaceFirst(RegExp(r'    source: .*\n'), '')),
          _throwsFormat('Guide "fox_36" needs a "source"'),
        );
        rejects('        []', '"rules" of guide "fox_36" is not a non-empty list');
      });

      test('a gap or an overlap between brackets', () {
        rejects(
          '      - { target: pressure, unit: psi, input: rider_weight, input_unit: lb, rows: { 120-130: 54, 140-150: 62 } }',
          'have a gap between 130 and 140',
        );
        rejects(
          '      - { target: pressure, unit: psi, input: rider_weight, input_unit: lb, rows: { 120-135: 54, 130-150: 62 } }',
          'overlap below 135',
        );
      });

      test('brackets mixed with points, a bracket that does not ascend, or a key that is neither', () {
        rejects(
          '      - { target: pressure, unit: psi, input: rider_weight, input_unit: lb, rows: { 120-130: 54, 140: 62 } }',
          'mix brackets and points',
        );
        rejects(
          '      - { target: pressure, unit: psi, input: rider_weight, input_unit: lb, rows: { 130-120: 54 } }',
          'Bracket "130-120"',
        );
        rejects(
          '      - { target: pressure, unit: psi, input: rider_weight, input_unit: lb, rows: { light: 54 } }',
          '"light" in "rows"',
        );
      });

      test('an open-ended row in the middle, or two at one edge', () {
        rejects(
          '      - { target: pressure, unit: psi, input: rider_weight, input_unit: lb, rows: { "<130": 50, 120-130: 54, 130-140: 58 } }',
          'Open-ended row "<130"',
        );
        rejects(
          '      - { target: pressure, unit: psi, input: rider_weight, input_unit: lb, rows: { 120-130: 54, 120+: 58 } }',
          'Open-ended row "120+"',
        );
        rejects(
          '      - { target: pressure, unit: psi, input: rider_weight, input_unit: lb, rows: { "<120": 50, "< 110": 48, 120-130: 54 } }',
          'two open-ended rows',
        );
      });

      test('a target no product of the guide has', () {
        rejects('      - { target: hsr, value: 5 }', 'targets an adjuster that no product it applies to has');
        rejects('      - { target: rebound, value: 5, when: { damper: grip_x2 } }', 'targets an adjuster');
      });

      test('a rule that matches no product the guide is attached to', () {
        rejects('      - { target: pressure, unit: psi, value: 80, when: { trim: performance } }', 'matches no product');
      });

      test('an unknown input, or one of another component type', () {
        rejects(
          '      - { target: pressure, unit: psi, input: rider_wieght, rows: { 60-70: 60 } }',
          'reads adjuster "rider_wieght", which "36/factory" does not have',
        );
        rejects('      - { target: pressure, unit: psi, input: stroke_mm, rows: { 50: 60 } }', 'does not apply to a fork');
        rejects('      - { target: pressure, unit: psi, input: stanchion, rows: { 50: 60 } }', 'is a text spec');
        rejects('      - { target: pressure, unit: psi, input: Weight, rows: { 50: 60 } }', 'neither a known input');
      });

      test('an adjuster input that an applicable product lacks', () {
        rejects(
          '      - { target: pressure, unit: psi, input: lsr, rows: { 5: 60, 10: 70 } }',
          'reads adjuster "lsr", which "36/rhythm" does not have',
        );
      });

      test('an unknown when key or value', () {
        rejects('      - { target: pressure, unit: psi, value: 80, when: { chassis: ebike } }', 'Unknown "when" key "chassis"');
        rejects('      - { target: pressure, unit: psi, value: 80, when: { damper: grip_x3 } }', 'names unknown "grip_x3"');
        rejects('      - { target: pressure, unit: psi, value: 80, when: { travel_mm: 170 } }', 'names unknown "170"');
        rejects('      - { target: pressure, unit: psi, value: 80, when: { riding_style: xc } }', 'names unknown "xc"');
        rejects('      - { target: pressure, unit: psi, value: 80, when: { damper: [] } }', 'not a value or a non-empty list');
      });

      test('literal row keys that are no value of their input', () {
        rejects('      - { target: sag, input: riding_style, rows: { trail: 18 } }', '"trail" in "rows"');
        rejects('      - { target: volume_spacers, input: wheel_size, rows: { 26: 2 } }', 'Row "26"');
      });

      test('a unit of another quantity than the adjuster, or a missing one', () {
        rejects('      - { target: pressure, unit: kg, value: 80 }', 'needs a unit of pressure');
        rejects('      - { target: pressure, value: 80 }', 'needs a unit of pressure');
        rejects('      - { target: hsc, unit: psi, value: 5 }', 'has no convertible unit');
        rejects('      - { target: sag, unit: psi, value: 20 }', 'neither % nor a length');
        rejects('      - { target: hsc, unit: furlongs, value: 5 }', 'Unknown unit "furlongs"');
      });

      test('an input unit that is missing, of another quantity, or not expected', () {
        rejects('      - { target: pressure, unit: psi, input: rider_weight, rows: { 60-70: 60 } }', 'needs an "input_unit" of mass');
        rejects(
          '      - { target: pressure, unit: psi, input: rider_weight, input_unit: psi, rows: { 60-70: 60 } }',
          'needs an "input_unit" of mass',
        );
        rejects('      - { target: volume_spacers, input: travel_mm, input_unit: mm, rows: { 150: 3 } }', 'takes no "input_unit"');
        rejects('      - { target: hsc, input: pressure, rows: { 60-70: 5 } }', '"input_unit" of a "hsc" rule');
        rejects('      - { target: hsc, value: 5, input_unit: kg }', '"input_unit" of rule 1 of guide "fox_36" needs an "input"');
      });

      test('two rules for one target with equal specificity that can both match', () {
        rejects('''
      - { target: pressure, unit: psi, value: 80, when: { trim: factory } }
      - { target: pressure, unit: psi, value: 85, when: { damper: [grip_x2, grip] } }''', 'Rules 1 and 2 of guide "fox_36" can both recommend "pressure"');
        rejects('''
      - { target: sag, range: [15, 20] }
      - { target: sag, range: [20, 25] }''', 'Rules 1 and 2');
      });

      test('display_only, which no longer exists', () {
        rejects('      - { target: hsc, value: 5, display_only: true }', 'Unknown key(s) display_only');
      });

      test('a value outside the adjuster range, compared in its unit', () {
        rejects('      - { target: hsc, value: 9 }', 'recommends 9, above the adjuster maximum 8');
        rejects('      - { target: hsc, value: [6, 9] }', 'above the adjuster maximum 8');
        rejects('      - { target: pressure, unit: psi, value: -5 }', 'below the adjuster minimum 0');
        rejects('      - { target: pressure, unit: bar, value: 10.5 }', 'recommends 10.5, above the adjuster maximum 150');
        rejects('      - { target: sag, value: 120 }', 'above the adjuster maximum 100');
        expect(ruleOf('      - { target: pressure, unit: bar, value: 10 }').unit, AdjustmentUnit.fromLegacy('bar'));
        expect(ruleOf('      - { target: sag, unit: mm, value: 120 }').target, 'sag');
      });

      test('a value above the range of a damper the rule can apply to', () {
        // Factory now offers GRIP X (15 HSC clicks) next to GRIP X2 (8).
        String twoDampers(String rules) => guideFork(rules)
            .replaceFirst(
              '    grip:\n      name: GRIP\n',
              '    grip_x:\n      name: GRIP X\n      adjustments:\n        - { name: HSC, type: step, max: 15 }\n    grip:\n      name: GRIP\n',
            )
            .replaceFirst('damper: [grip_x2]', 'damper: [grip_x2, grip_x]');

        expect(
          () => parseCatalogFile(twoDampers('      - { target: hsc, value: 10, when: { damper: grip_x } }')),
          returnsNormally,
        );
        expect(
          () => parseCatalogFile(twoDampers('      - { target: hsc, value: 10, when: { damper: grip_x2 } }')),
          _throwsFormat('recommends 10, above the adjuster maximum 8'),
        );
        expect(
          () => parseCatalogFile(twoDampers('      - { target: hsc, value: 10 }')),
          _throwsFormat('recommends 10, above the adjuster maximum 8'),
        );
      });

      test('a cell the adjuster type cannot take', () {
        rejects('      - { target: hsc, value: Open }', 'recommends "Open", which a StepAdjustment "HSC" cannot take');
        rejects('      - { target: hsc, value: true }', 'recommends true');
        rejects('      - { target: compression_mode, value: max }', 'recommends max, which a CategoricalAdjustment');
        rejects('      - { target: lockout, value: [min, max] }', 'which a BooleanAdjustment');
        rejects('      - { target: compression_mode, value: 2 }', 'recommends 2, which a CategoricalAdjustment');
        rejects('      - { target: lockout, value: Open }', 'which a BooleanAdjustment');
      });

      test('a range reference outside the range or to an unpublished bound', () {
        rejects('      - { target: hsc, value: min-2 }', '"min-2" lies outside the adjuster range');
        rejects('      - { target: hsc, value: max+1 }', '"max+1" lies outside the adjuster range');
        rejects('      - { target: hsc, value: max-9 }', 'recommends max-9, below the adjuster minimum 0');
        rejects('      - { target: hsc, value: min+9 }', 'recommends min+9, above the adjuster maximum 8');
        rejects('      - { target: pressure, unit: bar, value: min+11 }', 'above the adjuster maximum 150');
        rejects('      - { target: preload, unit: mm, value: max }', '"Preload" publishes no maximum');
        rejects('      - { target: preload, unit: mm, value: mid }', '"Preload" publishes no range');
        expect(ruleOf('      - { target: lsc, value: [mid, max-2] }').target, 'lsc');
      });

      test('comfort_at that is not min or max, or not on a range', () {
        rejects('      - { target: sag, range: [15, 20], comfort_at: mid }', '"comfort_at" of rule 1 of guide "fox_36" is neither');
        rejects('      - { target: sag, value: 15, comfort_at: max }', 'only applies to a "range"');
      });

      test('an option the categorical adjuster does not offer', () {
        rejects('      - { target: compression_mode, value: Soft }', 'recommends "Soft", which is no option of "Compression Mode"');
      });

      test('a cycle between adjuster inputs', () {
        rejects('''
      - { target: pressure, unit: psi, input: volume_spacers, rows: { 1: 60, 2: 70 } }
      - { target: volume_spacers, input: pressure, input_unit: psi, rows: { 60: 1, 70: 2 } }''', 'form a cycle: volume_spacers → pressure, pressure → volume_spacers');
        rejects('      - { target: pressure, unit: psi, input: pressure, input_unit: psi, rows: { 60: 60 } }', 'form a cycle');
      });

      test('rows without an input, or an input without rows', () {
        rejects('      - { target: hsc, rows: { 1: 5 } }', '"rows" of rule 1 of guide "fox_36" need an "input"');
        rejects('      - { target: hsc, input: travel_mm, value: 5 }', '"input" of rule 1 of guide "fox_36" only applies to "rows"');
        rejects('      - { target: hsc }', 'needs exactly one of "value", "rows" or "range"');
        rejects('      - { target: hsc, value: 5, range: [1, 2] }', 'needs exactly one of');
      });

      test('a malformed range or cell', () {
        rejects('      - { target: sag, range: [20, 15] }', '"range" of rule 1');
        rejects('      - { target: hsc, value: [5, 3] }', '"value" of rule 1 of guide "fox_36" is not an ascending');
        rejects('      - { target: hsc, value: [max, 3] }', 'not an ascending');
        rejects('      - { target: hsc, value: [max, max-3] }', 'not an ascending');
        rejects('      - { target: hsc, value: [2, min] }', 'not an ascending');
        rejects('      - { target: hsc, value: [mid, mid] }', 'not an ascending');
        rejects('      - { target: hsc, value: [1, Open] }', 'not an ascending');
        rejects('      - { target: hsc, value: "" }', '"value" of rule 1');
      });
    });
  });

  group('moved', () {
    String fork(String moved) =>
        '''
brand: FOX
component_type: fork
$moved
nodes:
  - label: "36"
    level: model
    children:
      - label: "2025–2026"
        level: generation
        id: "2025"
        children:
          - { label: Factory, level: trim }
''';

    test('reads old node paths and where they live now', () {
      final catalog = parseCatalogFile(fork('moved:\n  36/factory: 36/2025/factory\n  38: 36'));

      expect(catalog.moved.map((entry) => '${entry.from.join('/')} -> ${entry.to.join('/')}'), [
        '36/factory -> 36/2025/factory',
        '38 -> 36',
      ]);
    });

    test('redirect rewrites the longest matching prefix and keeps the rest', () {
      final catalog = parseCatalogFile(fork('moved:\n  38: 36\n  38/old: 36/2025/factory'));

      expect(catalog.redirect(['38', 'factory']), ['36', 'factory']);
      expect(catalog.redirect(['38', 'old']), ['36', '2025', 'factory']);
      expect(catalog.redirect(['36', '2025']), isNull);
      expect(catalog.redirect(const []), isNull);
    });

    test('rejects an old path that still exists', () {
      expect(() => parseCatalogFile(fork('moved:\n  36/2025: 36')), _throwsFormat('still exists'));
    });

    test('rejects a target that does not exist', () {
      expect(() => parseCatalogFile(fork('moved:\n  36/factory: 36/2019/factory')), _throwsFormat('does not exist'));
    });

    test('rejects a malformed path or map', () {
      expect(() => parseCatalogFile(fork('moved:\n  36//factory: 36')), _throwsFormat('"/"-joined'));
      expect(() => parseCatalogFile(fork('moved:\n  38: [36]')), _throwsFormat('"/"-joined'));
      expect(() => parseCatalogFile(fork('moved: [a]')), _throwsFormat('"moved" is not a map'));
    });
  });
}
