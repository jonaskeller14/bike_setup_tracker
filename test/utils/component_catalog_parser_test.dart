import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/component_catalog.dart';
import 'package:bike_setup_tracker/models/component/preset_spec_keys.dart';
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
      expect(factory.years, '2025-2026');
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
}
