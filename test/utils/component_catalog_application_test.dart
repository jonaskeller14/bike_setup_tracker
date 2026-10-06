import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/component_preset.dart';
import 'package:bike_setup_tracker/utils/component_catalog_application.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

/// [buildCatalogApplication] turns a resolved catalog selection into form-fill
/// data. Fixtures are small inline YAML files run through the real
/// [parseCatalogFile], so the parser, the resolver and the builder are
/// exercised together with values controlled here.

const _foxYaml = '''
brand: FOX
component_type: fork
option_values:
  damper:
    grip_x2:
      name: GRIP X2
      description: 4-way adjustable damper
      adjustments:
        - { name: HSC, type: step, max: 8 }
        - { name: LSC, type: step, max: ~, notes: Low-Speed Compression }
    grip_x:
      name: GRIP X
      adjustments:
        - { name: Rebound, type: step, max: 17 }
      missing_adjustments: [LSC]
nodes:
  - label: "36"
    level: model
    category: Trail
    specs: { spring: Air }
    children:
      - label: "2025–2026"
        level: generation
        id: "2025"
        years: "2025-2026"
        url: https://www.foxfactory.com/36
        setup_guide: https://tech.ridefox.com/36
        children:
          - label: Factory
            level: trim
            specs: { stanchion: Kashima }
            note: Trim note
            adjustments:
              - { name: Pressure, type: numerical, unit: psi }
              - { name: Volume Spacers, type: step, max: 6, visualization: stepper }
            options:
              damper: [grip_x2, grip_x]
              travel_mm: [150, 160]
              wheel_size: [29, 27.5]
          - label: Performance
            level: trim
            adjustments:
              - { name: Pressure, type: numerical, unit: psi }
            options:
              damper: [grip_x]
              travel_mm: [160]
''';

const _ohlinsYaml = '''
brand: Öhlins
component_type: shock
option_values:
  damper:
    ttx22_m2:
      name: TTX22 m.2
      adjustments:
        - { name: Compression Mode, type: categorical, options: [Open, Medium, Firm] }
nodes:
  - label: TTX22
    level: model
    specs: { spring: Coil }
    children:
      - label: m.2
        level: version
        id: m2
        adjustments:
          - { name: Spring Rate, type: numerical, unit: lbs/in }
        options:
          damper: [ttx22_m2]
          size:
            - "210x50/55"
            - { size: "185x55", mount: Trunnion }
''';

/// The product at [index] of [yaml], with [choices] (axis id → value id) set.
ResolvedPreset _preset(String yaml, {int index = 0, Map<String, Object> choices = const {}}) {
  var preset = catalogProducts(parseCatalogFile(yaml)).elementAt(index);
  for (final MapEntry(key: axisId, value: valueId) in choices.entries) {
    final axis = preset.product!.options[axisId]!;
    preset = preset.select(axis, axis.values.firstWhere((value) => value.id == valueId));
  }
  return preset;
}

List<String> _names(List<Adjustment> adjustments) => adjustments.map((a) => a.name).toList();

SagAdjustment _sag(List<Adjustment> adjustments) => adjustments.whereType<SagAdjustment>().single;

void main() {
  group('fork with a chosen damper and travel', () {
    final resolved = _preset(_foxYaml, choices: {'damper': 'grip_x2', 'travel_mm': 160});

    test('name, type and preset map', () {
      final app = buildCatalogApplication(resolved);

      expect(app.name, 'FOX 36 Factory GRIP X2');
      expect(app.componentType, ComponentType.fork);
      expect(app.preset.toJson(), {
        'brand': 'fox',
        'component_type': 'fork',
        'model': '36',
        'generation': '2025',
        'trim': 'factory',
        'damper': 'grip_x2',
        'travel_mm': 160,
      });
    });

    test('adjustments combine product → SAG → option values, with declared ranges', () {
      final app = buildCatalogApplication(resolved);

      expect(_names(app.adjustments), ['Pressure', 'Volume Spacers', 'SAG', 'HSC', 'LSC']);
      final hsc = app.adjustments.firstWhere((a) => a.name == 'HSC') as StepAdjustment;
      expect(hsc.max, 8);
    });

    test('the placeholder max and its warning reach the built adjustment', () {
      final app = buildCatalogApplication(resolved);

      final lsc = app.adjustments.firstWhere((a) => a.name == 'LSC') as StepAdjustment;
      expect(lsc.max, StepAdjustment.unknownMaxPlaceholder);
      expect(lsc.notes, 'Low-Speed Compression; ${StepAdjustment.unknownMaxWarning}');
    });

    test('the chosen travel becomes the SAG reference travel', () {
      final sag = _sag(buildCatalogApplication(resolved).adjustments);

      expect(sag.referenceTravelMm, 160);
      expect(sag.notes, kForkSagNotes);
    });

    test('notes are a dash list of the chosen values and specs, then the setup guide', () {
      final app = buildCatalogApplication(resolved);

      // The damper description, the skipped wheel size and the product page are left out.
      expect(app.notes.split('\n'), [
        '- Damper: GRIP X2',
        '- Travel: 160 mm',
        '- Stanchion: Kashima · Spring: Air',
        '- Model years: 2025-2026',
        '- Trim note',
        '',
        'Setup guide: https://tech.ridefox.com/36',
      ]);
    });

    test('fresh UUIDs on every adjustment', () {
      final first = buildCatalogApplication(resolved).adjustments;
      final second = buildCatalogApplication(resolved).adjustments;

      final ids = {...first.map((a) => a.id), ...second.map((a) => a.id)};
      expect(ids, hasLength(first.length + second.length));
    });
  });

  group('open and skipped axes', () {
    final resolved = _preset(_foxYaml);

    test('an open required axis contributes no adjustments and no name', () {
      final app = buildCatalogApplication(resolved);

      expect(app.name, 'FOX 36 Factory');
      expect(_names(app.adjustments), ['Pressure', 'Volume Spacers', 'SAG']);
      expect(app.preset['damper'], isNull);
    });

    test('a skipped travel leaves the SAG reference travel unset', () {
      expect(_sag(buildCatalogApplication(resolved).adjustments).referenceTravelMm, isNull);
    });

    test('notes leave out the options that are still open', () {
      final notes = buildCatalogApplication(resolved).notes;

      expect(notes, isNot(contains('Damper')));
      expect(notes, isNot(contains('Travel')));
    });
  });

  group('single-value axes', () {
    final app = buildCatalogApplication(_preset(_foxYaml, index: 1));

    test('are applied without a choice and stay out of the name', () {
      expect(app.name, 'FOX 36 Performance');
      expect(_names(app.adjustments), ['Pressure', 'SAG', 'Rebound']);
      expect(_sag(app.adjustments).referenceTravelMm, 160);
    });

    test('are persisted', () {
      expect(app.preset['damper'], 'grip_x');
      expect(app.preset['travel_mm'], 160);
    });

    test('the damper is named, and its missing adjusters are listed', () {
      final lines = app.notes.split('\n');

      expect(lines, contains('- Damper: GRIP X'));
      expect(lines, contains('- Travel: 160 mm'));
      expect(lines, contains('- Not in the catalog yet, add by hand: LSC'));
    });
  });

  group('shock', () {
    test('the stroke of the chosen size becomes the SAG reference travel', () {
      final app = buildCatalogApplication(_preset(_ohlinsYaml, choices: {'size': '210x55'}));

      expect(_names(app.adjustments), ['Spring Rate', 'SAG', 'Compression Mode']);
      final sag = _sag(app.adjustments);
      expect(sag.referenceTravelMm, 55);
      expect(sag.notes, kShockSagNotes);
      expect(app.preset['size'], '210x55');
    });

    test('a skipped size leaves the SAG reference travel unset', () {
      final app = buildCatalogApplication(_preset(_ohlinsYaml));

      expect(_sag(app.adjustments).referenceTravelMm, isNull);
      expect(app.preset['size'], isNull);
      expect(app.notes, isNot(contains('Size')));
    });

    test('notes name the chosen size once, with its mount', () {
      final app = buildCatalogApplication(_preset(_ohlinsYaml, choices: {'size': '185x55'}));

      expect(app.name, 'Öhlins TTX22 m.2');
      expect(app.notes.split('\n'), [
        '- Damper: TTX22 m.2',
        '- Size: 185x55 mm',
        '- Spring: Coil · Mount: Trunnion',
      ]);
    });
  });

  test('a path that stops at a group is named by its deepest node', () {
    final resolved = resolvePreset(
      [parseCatalogFile(_foxYaml)],
      ComponentPreset(const {'brand': 'fox', 'component_type': 'fork', 'model': '36', 'generation': '2025', 'trim': 'retired'}),
    )!;

    // The generation's label is its year span, which is not part of the name.
    expect(presetDisplayName(resolved), 'FOX 36');
  });
}
