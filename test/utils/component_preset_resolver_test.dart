import 'dart:convert';

import 'package:bike_setup_tracker/models/component/component_catalog.dart';
import 'package:bike_setup_tracker/models/component/component_preset.dart';
import 'package:bike_setup_tracker/models/component/preset_spec_keys.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

/// [resolvePreset] reads a persisted [ComponentPreset] back against the
/// catalog, [toComponentPreset] writes one. Fixtures are small inline YAML files run
/// through the real [parseCatalogFile].

const _foxYaml = '''
brand: FOX
component_type: fork
option_values:
  damper:
    grip_x2:
      name: GRIP X2
      adjustments:
        - { name: HSC, type: step, max: 8 }
    grip_x:
      name: GRIP X
      adjustments:
        - { name: Rebound, type: step, max: 17 }
nodes:
  - label: "36"
    level: model
    specs: { spring: Air }
    children:
      - label: "2025–2026"
        level: generation
        id: "2025"
        children:
          - label: Factory
            level: trim
            specs: { stanchion: Kashima }
            options:
              damper: [grip_x2, grip_x]
              travel_mm: [150, 160]
              wheel_size: [29]
          - label: Performance
            level: trim
            options:
              damper: [grip_x]
              travel_mm: [150, 160]
      - label: "2021–2024"
        level: generation
        id: "2021"
        draft: true
        children:
          - label: Factory
            level: trim
            options:
              damper: [grip_x2]
''';

const _ohlinsYaml = '''
brand: Öhlins
component_type: shock
nodes:
  - label: TTX22
    level: model
    children:
      - label: m.2
        level: version
        id: m2
        options:
          size: ["210x50/52.5/55", { size: "185x55", mount: Trunnion }]
''';

final _catalogs = [parseCatalogFile(_foxYaml), parseCatalogFile(_ohlinsYaml)];

const Map<String, Object> _factory = {
  'brand': 'fox',
  'component_type': 'fork',
  'model': '36',
  'generation': '2025',
  'trim': 'factory',
  'damper': 'grip_x2',
  'travel_mm': 160,
  'wheel_size': '29',
};

/// [_factory] without [removed], plus [changed].
ComponentPreset _factoryWith({List<String> removed = const [], Map<String, Object> changed = const {}}) => ComponentPreset({
  for (final entry in _factory.entries)
    if (!removed.contains(entry.key)) entry.key: entry.value,
  ...changed,
});

List<String> _labels(ResolvedPreset resolved) => resolved.path.map((node) => node.label).toList();

void main() {
  group('resolvePreset', () {
    test('walks the tree to the product and reads its selections', () {
      final resolved = resolvePreset(_catalogs, ComponentPreset(_factory))!;

      expect(resolved.catalog.brand, 'FOX');
      expect(_labels(resolved), ['36', '2025–2026', 'Factory']);
      expect(resolved.product, same(resolved.node));
      expect(resolved.selections.keys, ['damper', 'travel_mm', 'wheel_size']);
      expect(resolved.selections['damper']!.label, 'GRIP X2');
      expect(resolved.selections['travel_mm']!.id, 160);
      expect(resolved.openRequiredAxes, isEmpty);
    });

    test('a map that stops early resolves to the group it reached', () {
      final resolved = resolvePreset(_catalogs, ComponentPreset(const {'brand': 'fox', 'component_type': 'fork', 'model': '36'}))!;

      expect(_labels(resolved), ['36']);
      expect(resolved.product, isNull);
      expect(resolved.selections, isEmpty);
      expect(resolved.axes, isEmpty);
    });

    test('a stale deeper entry resolves to the deepest node that still matches', () {
      final resolved = resolvePreset(_catalogs, _factoryWith(changed: {'trim': 'retired'}))!;

      expect(_labels(resolved), ['36', '2025–2026']);
      expect(resolved.product, isNull);
      // Options belong to a product, so they go with it.
      expect(resolved.selections, isEmpty);
    });

    test('a stale option value leaves its axis open', () {
      final resolved = resolvePreset(_catalogs, _factoryWith(changed: {'damper': 'retired'}))!;

      expect(resolved.product!.label, 'Factory');
      expect(resolved.selections.keys, ['travel_mm', 'wheel_size']);
      expect(resolved.openRequiredAxes.map((axis) => axis.id), ['damper']);
    });

    test('ignores entries the catalog does not know', () {
      final resolved = resolvePreset(_catalogs, _factoryWith(changed: {'colour': 'orange', 'size': '210x55'}))!;

      expect(toComponentPreset(resolved), ComponentPreset(_factory));
    });

    test('still resolves a draft node', () {
      final resolved = resolvePreset(_catalogs, ComponentPreset(const {
        'brand': 'fox',
        'component_type': 'fork',
        'model': '36',
        'generation': '2021',
        'trim': 'factory',
      }))!;

      expect(resolved.node.draft, isTrue);
      expect(resolved.product!.label, 'Factory');
    });

    test('a skipped optional axis stays unset', () {
      final resolved = resolvePreset(_catalogs, _factoryWith(removed: ['travel_mm']))!;

      expect(resolved.selections.containsKey('travel_mm'), isFalse);
      expect(resolved.optionalAxes.map((axis) => axis.id), ['travel_mm']);
      expect(resolved.effectiveSpecs.get(PresetSpecKeys.travelMm), isNull);
      expect(toComponentPreset(resolved)['travel_mm'], isNull);
    });

    test('an axis with a single value is resolved without being asked for', () {
      final resolved = resolvePreset(_catalogs, _factoryWith(removed: ['wheel_size']))!;

      expect(resolved.selections['wheel_size']!.id, '29');
      // Nothing to choose, so it is not offered either.
      expect(resolved.optionalAxes.map((axis) => axis.id), ['travel_mm']);
      expect(toComponentPreset(resolved)['wheel_size'], '29');
    });

    test('resolves a shock size by its id', () {
      final resolved = resolvePreset(_catalogs, ComponentPreset(const {
        'brand': 'ohlins',
        'component_type': 'shock',
        'model': 'ttx22',
        'version': 'm2',
        'size': '210x52.5',
      }))!;

      expect(_labels(resolved), ['TTX22', 'm.2']);
      expect(resolved.effectiveSpecs.get(PresetSpecKeys.strokeMm), 52.5);
      expect(resolved.effectiveSpecs.get(PresetSpecKeys.eyeToEyeMm), 210);
    });

    test('is null when the brand, the type or the first level does not match', () {
      expect(resolvePreset(_catalogs, _factoryWith(changed: {'brand': 'rockshox'})), isNull);
      expect(resolvePreset(_catalogs, _factoryWith(changed: {'component_type': 'shock'})), isNull);
      expect(resolvePreset(_catalogs, _factoryWith(changed: {'model': '99'})), isNull);
      expect(resolvePreset(_catalogs, ComponentPreset(const {})), isNull);
    });
  });

  group('toComponentPreset', () {
    test('round-trips a resolved preset', () {
      expect(toComponentPreset(resolvePreset(_catalogs, ComponentPreset(_factory))!), ComponentPreset(_factory));
    });

    test('survives the JSON column', () {
      final stored = jsonEncode(toComponentPreset(resolvePreset(_catalogs, ComponentPreset(_factory))!).toJson());
      final restored = ComponentPreset.tryFromJson(jsonDecode(stored))!;

      expect(toComponentPreset(resolvePreset(_catalogs, restored)!), ComponentPreset(_factory));
    });

    test('stops where the path stops', () {
      final resolved = resolvePreset(_catalogs, _factoryWith(changed: {'trim': 'retired'}))!;

      expect(
        toComponentPreset(resolved),
        ComponentPreset(const {'brand': 'fox', 'component_type': 'fork', 'model': '36', 'generation': '2025'}),
      );
    });
  });

  group('ResolvedPreset', () {
    late ResolvedPreset factory;

    setUp(() {
      factory = catalogProducts(_catalogs.first).first;
    });

    test('a product starts with only its single-value axes resolved', () {
      expect(factory.selections.keys, ['wheel_size']);
      expect(factory.openRequiredAxes.map((axis) => axis.id), ['damper']);
      expect(factory.optionalAxes.map((axis) => axis.id), ['travel_mm']);
    });

    test('select sets a value and keeps the axis order', () {
      final axes = factory.product!.options;
      final selected = factory
          .select(axes['travel_mm']!, axes['travel_mm']!.values.first)
          .select(axes['damper']!, axes['damper']!.values.last);

      expect(selected.selections.keys, ['damper', 'travel_mm', 'wheel_size']);
      expect(selected.selections['damper']!.id, 'grip_x');
      expect(selected.openRequiredAxes, isEmpty);
      // The original is untouched.
      expect(factory.selections.keys, ['wheel_size']);
    });

    test('select with null clears a value', () {
      final travel = factory.product!.options['travel_mm']!;
      final cleared = factory.select(travel, travel.values.first).select(travel, null);

      expect(cleared.selections.keys, ['wheel_size']);
    });

    test('effective specs merge the path with the chosen values', () {
      final travel = factory.product!.options['travel_mm']!;
      final specs = factory.select(travel, travel.values.last).effectiveSpecs;

      expect(specs.get(PresetSpecKeys.spring), 'Air'); // model
      expect(specs.get(PresetSpecKeys.stanchion), 'Kashima'); // trim
      expect(specs.get(PresetSpecKeys.travelMm), 160); // chosen
      expect(specs.get(PresetSpecKeys.wheelSize), '29'); // single value
    });
  });

  test('catalogProducts lists every product in authored order, drafts included', () {
    final products = catalogProducts(_catalogs.first).toList();

    expect(products.map(_labels), [
      ['36', '2025–2026', 'Factory'],
      ['36', '2025–2026', 'Performance'],
      ['36', '2021–2024', 'Factory'],
    ]);
    expect(products.map((product) => product.node.draft), [false, false, true]);
    expect(products.every((product) => product.product is CatalogProduct), isTrue);
  });
}
