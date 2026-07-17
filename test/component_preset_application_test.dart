import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/component_preset.dart';
import 'package:bike_setup_tracker/utils/component_preset_application.dart';
import 'package:bike_setup_tracker/utils/component_preset_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 2 prefill engine (C6): [buildApplication] turns a selected variant +
/// chosen damper into form-fill data. Fixtures are small inline YAML files run
/// through the real [parseBrandFile] so the parser and builder are exercised
/// together, but with values controlled here (the real catalog files are
/// covered separately by `component_presets_test.dart`).

ComponentPresetVariant _variant(String yaml, {int index = 0}) =>
    parseBrandFile(yaml).elementAt(index);

List<String> _names(List<Adjustment> adjustments) =>
    adjustments.map((a) => a.name).toList();

void main() {
  group('air fork with damper', () {
    const yaml = '''
brand: FOX
component_type: fork
dampers:
  grip_x2:
    name: GRIP X2
    description: 4-way adjustable damper
    adjustments:
      - { name: High-Speed Compression, type: step, max: 8 }
      - { name: Low-Speed Compression, type: step, max: 18 }
      - { name: High-Speed Rebound, type: step, max: 8 }
      - { name: Low-Speed Rebound, type: step, max: 16 }
forks:
  - model: "36"
    category: Trail
    year_range: 2025-26
    url: https://www.foxfactory.com/36
    trims:
      - trim: Factory
        travel_mm: [160]
        stanchion: 36 mm
        dampers: [grip_x2]
        spring: Air
        adjustments:
          - { name: Pressure, type: numerical, unit: psi }
          - { name: Volume Spacers, type: step, max: 6, visualization: stepper }
''';

    test('name, type and single-damper resolution', () {
      final app = buildApplication(_variant(yaml));
      expect(app.name, 'FOX 36 Factory'); // single damper → not appended
      expect(app.componentType, ComponentType.fork);
    });

    test('adjustments combine trim → SAG → damper, with declared ranges', () {
      final app = buildApplication(_variant(yaml));
      expect(
        _names(app.adjustments),
        ['Pressure', 'Volume Spacers', 'SAG', 'High-Speed Compression',
         'Low-Speed Compression', 'High-Speed Rebound', 'Low-Speed Rebound'],
      );

      final hsc = app.adjustments.firstWhere((a) => a.name == 'High-Speed Compression');
      expect(hsc, isA<StepAdjustment>());
      expect((hsc as StepAdjustment).max, 8);
      final lsc = app.adjustments.firstWhere((a) => a.name == 'Low-Speed Compression') as StepAdjustment;
      expect(lsc.max, 18);
    });

    test('single travel prefills SAG reference travel', () {
      final app = buildApplication(_variant(yaml));
      final sag = app.adjustments.firstWhere((a) => a.name == 'SAG') as SagAdjustment;
      expect(sag.referenceTravelMm, 160);
      expect(sag.notes, kForkSagNotes);
    });

    test('notes carry the compact spec block with url last', () {
      final app = buildApplication(_variant(yaml));
      final lines = app.notes.split('\n');
      expect(lines, contains('Damper: GRIP X2 — 4-way adjustable damper'));
      expect(lines, contains('Spring: Air'));
      expect(lines, contains('Travel: 160 mm'));
      expect(lines, contains('Stanchion: 36 mm'));
      expect(lines, contains('Year: 2025-26'));
      expect(lines.last, 'https://www.foxfactory.com/36');
    });

    test('fresh UUIDs and valid values on every adjustment', () {
      final app = buildApplication(_variant(yaml));
      final ids = app.adjustments.map((a) => a.id).toSet();
      expect(ids.length, app.adjustments.length); // all unique
      for (final a in app.adjustments) {
        expect(a.id, isNotEmpty);
      }
    });
  });

  test('Charger 3.1 from-middle ranges preserved end-to-end', () {
    const yaml = '''
brand: RockShox
component_type: fork
dampers:
  charger_3_1:
    name: Charger 3.1
    adjustments:
      - { name: High-Speed Compression, type: step, min: -2, max: 2, visualization: dial_cw }
      - { name: Low-Speed Compression, type: step, min: -7, max: 7, visualization: dial_cw }
      - { name: Rebound, type: step, max: 18 }
forks:
  - model: Lyrik
    trims:
      - trim: Ultimate
        travel_mm: [150]
        dampers: [charger_3_1]
        spring: Air
        adjustments:
          - { name: Pressure, type: numerical, unit: psi }
''';
    final app = buildApplication(_variant(yaml));
    final hsc = app.adjustments.firstWhere((a) => a.name == 'High-Speed Compression') as StepAdjustment;
    expect(hsc.min, -2);
    expect(hsc.max, 2);
    expect(hsc.visualization, StepAdjustmentVisualization.sliderWithClockwiseDial);
    final lsc = app.adjustments.firstWhere((a) => a.name == 'Low-Speed Compression') as StepAdjustment;
    expect(lsc.min, -7);
    expect(lsc.max, 7);
  });

  test('dual-chamber spring → two pressure adjustments', () {
    const yaml = '''
brand: RockShox
component_type: fork
forks:
  - model: Vivid Air
    trims:
      - trim: Ultimate
        travel_mm: [160]
        spring: Air
        adjustments:
          - { name: Positive Pressure, type: numerical, unit: psi }
          - { name: Negative Pressure, type: numerical, unit: psi }
''';
    final app = buildApplication(_variant(yaml));
    expect(_names(app.adjustments), ['Positive Pressure', 'Negative Pressure', 'SAG']);
  });

  test('air fork without declared spacers generates none', () {
    const yaml = '''
brand: FOX
component_type: fork
forks:
  - model: "34"
    trims:
      - trim: Performance
        travel_mm: [140]
        spring: Air
        adjustments:
          - { name: Pressure, type: numerical, unit: psi }
''';
    final app = buildApplication(_variant(yaml));
    expect(_names(app.adjustments), ['Pressure', 'SAG']);
    expect(app.adjustments.whereType<StepAdjustment>(), isEmpty);
  });

  test('coil variant → Spring Rate, no Pressure/Spacers', () {
    const yaml = '''
brand: FOX
component_type: fork
forks:
  - model: "38"
    trims:
      - trim: Factory Coil
        travel_mm: [170]
        spring: Coil
        adjustments:
          - { name: Spring Rate, type: numerical, unit: lbs/in }
''';
    final app = buildApplication(_variant(yaml));
    expect(_names(app.adjustments), ['Spring Rate', 'SAG']);
    expect(app.notes, contains('Spring: Coil'));
  });

  test('compression-mode categorical adjustment', () {
    const yaml = '''
brand: FOX
component_type: shock
dampers:
  dps:
    name: DPS
    adjustments:
      - { name: Compression Mode, type: categorical, options: [Open, Medium, Firm] }
shocks:
  - model: Float
    trims:
      - trim: Factory
        stroke_mm: ["55"]
        dampers: [dps]
        spring: Air
        adjustments:
          - { name: Pressure, type: numerical, unit: psi }
''';
    final app = buildApplication(_variant(yaml));
    final mode = app.adjustments.firstWhere((a) => a.name == 'Compression Mode');
    expect(mode, isA<CategoricalAdjustment>());
    expect((mode as CategoricalAdjustment).options, {'Open', 'Medium', 'Firm'});
    // shock SAG notes + single stroke prefills reference travel
    final sag = app.adjustments.firstWhere((a) => a.name == 'SAG') as SagAdjustment;
    expect(sag.notes, kShockSagNotes);
    expect(sag.referenceTravelMm, 55);
  });

  group('multi-damper naming', () {
    const yaml = '''
brand: FOX
component_type: fork
dampers:
  grip_x2:
    name: GRIP X2
    adjustments:
      - { name: Rebound, type: step, max: 16 }
  grip_x:
    name: GRIP X
    adjustments:
      - { name: Rebound, type: step, max: 10 }
forks:
  - model: "36"
    trims:
      - trim: Factory
        travel_mm: [150, 160]
        dampers: [grip_x2, grip_x]
        spring: Air
        adjustments:
          - { name: Pressure, type: numerical, unit: psi }
''';

    test('damper name appended when trim offers >1 damper', () {
      final variant = _variant(yaml);
      final app = buildApplication(variant, variant.dampers.first);
      expect(app.name, 'FOX 36 Factory GRIP X2');
      expect(_names(app.adjustments), ['Pressure', 'SAG', 'Rebound']);
    });

    test('no damper passed for a multi-damper trim → no clicks, no append', () {
      final app = buildApplication(_variant(yaml));
      expect(app.name, 'FOX 36 Factory'); // no disambiguation without a choice
      expect(_names(app.adjustments), ['Pressure', 'SAG']);
    });
  });

  test('multiple travel options leave SAG reference unset', () {
    const yaml = '''
brand: FOX
component_type: fork
forks:
  - model: "36"
    trims:
      - trim: Factory
        travel_mm: [150, 160, 170]
        spring: Air
        adjustments:
          - { name: Pressure, type: numerical, unit: psi }
''';
    final app = buildApplication(_variant(yaml));
    final sag = app.adjustments.firstWhere((a) => a.name == 'SAG') as SagAdjustment;
    expect(sag.referenceTravelMm, isNull);
  });
}
