import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/setup_guide.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/utils/component_catalog_application.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:bike_setup_tracker/utils/setup_guide_actions.dart';
import 'package:bike_setup_tracker/widgets/sheets/person_add_adjustment.dart';
import 'package:flutter_test/flutter_test.dart';

const _catalog = '''
brand: Acme
component_type: fork
guides:
  acme:
    label: Acme owner's manual (2027)
    source: https://example.com/acme
    rules:
      - target: pressure
        unit: psi
        input: rider_weight
        input_unit: kg
        rows: { 70-80: 70, 80-90: 80, 90-100: 90 }
      - target: rebound
        input: pressure
        input_unit: psi
        rows: { 60-75: 10, 75-85: 8, 85-95: 6 }
      - { target: lsc, value: 4 }
nodes:
  - label: Guided
    level: model
    guide: acme
    adjustments:
      - { name: Pressure, type: numerical, unit: psi, min: 0, max: 120 }
      - { name: Rebound, type: step, max: 16 }
      - { name: LSC, type: step, max: 10 }
  - label: Plain
    level: model
    adjustments:
      - { name: Pressure, type: numerical, unit: psi, min: 0, max: 120 }
''';

void main() {
  final products = catalogProducts(parseCatalogFile(_catalog)).toList();

  Component component(String model) {
    final application = buildCatalogApplication(products.firstWhere((p) => p.node.id == model));
    return Component(
      name: application.name,
      componentType: application.componentType,
      installations: const [],
      adjustments: application.adjustments,
      preset: application.preset,
    );
  }

  ResolvedPreset? resolve(Component component) => resolvePreset([products.first.catalog], component.preset!);

  Adjustment adjustment(Component component, String name) => component.adjustments.firstWhere((a) => a.name == name);

  group('guidedComponentsWithoutValues', () {
    test('keeps linked components with a guide and no recorded value', () {
      final guided = component('guided');
      final plain = component('plain');
      final handBuilt = Component(name: 'Hand-built', componentType: ComponentType.fork, installations: const []);

      final result = guidedComponentsWithoutValues([guided, plain, handBuilt], resolve: resolve, previousValues: {});

      expect(result.map((g) => g.component), [guided]);
      expect(result.single.guide.id, 'acme');
    });

    test('drops a component once any of its adjusters has a recorded value', () {
      final guided = component('guided');

      final result = guidedComponentsWithoutValues(
        [guided],
        resolve: resolve,
        previousValues: {adjustment(guided, 'LSC').id: const StepValue(3)},
      );

      expect(result, isEmpty);
    });

    test('waits for the catalog to load', () {
      expect(guidedComponentsWithoutValues([component('guided')], resolve: (_) => null, previousValues: {}), isEmpty);
    });
  });

  group('guideInputsFor', () {
    final weight = ridingWeightPreset;
    final style = CategoricalAdjustment(
      name: 'Riding style',
      unit: null,
      options: const {'Comfort', 'Balanced', 'Race'},
      notes: null,
      presetKey: 'person:riding_style',
    );
    final person = Person(name: 'Rider', adjustments: [weight, style]);

    test('prefers the value entered on this setup', () {
      final inputs = guideInputsFor(
        person,
        values: {weight.id: const NumericalValue(82)},
        previousValues: {weight.id: const NumericalValue(75)},
      );
      expect(inputs.riderWeight, 82);
      expect(inputs.riderWeightUnit.label, 'kg');
    });

    test('falls back to the last recorded weight and style', () {
      final inputs = guideInputsFor(
        person,
        values: {},
        previousValues: {
          weight.id: const NumericalValue(75),
          style.id: CategoricalValue(const ['Race']),
        },
      );
      expect(inputs.riderWeight, 75);
      expect(inputs.ridingStyle, GuideRidingStyle.race);
    });

    test('uses the card weight, in kg, only while no weight is entered or recorded', () {
      final fallback = guideInputsFor(null, values: {}, previousValues: {}, fallbackWeight: 90);
      expect(fallback.riderWeight, 90);
      expect(fallback.riderWeightUnit.label, 'kg');

      final recorded = guideInputsFor(
        person,
        values: {},
        previousValues: {weight.id: const NumericalValue(75)},
        fallbackWeight: 90,
      );
      expect(recorded.riderWeight, 75);
    });

    test('has no weight without a person, a value or a mass unit', () {
      expect(guideInputsFor(null, values: {}, previousValues: {}).riderWeight, isNull);
      expect(guideInputsFor(person, values: {}, previousValues: {}).riderWeight, isNull);

      final unitless = NumericalAdjustment(name: 'Riding weight', unit: null, notes: null, min: 0);
      expect(
        guideInputsFor(
          Person(name: 'Rider', adjustments: [unitless]),
          values: {unitless.id: const NumericalValue(82)},
          previousValues: {},
        ).riderWeight,
        isNull,
      );
    });
  });

  group('guideValuesToApply', () {
    test('reads dependent rules off the pressure being applied, not the entered one', () {
      final guided = GuidedComponent(component('guided'), resolve(component('guided'))!);
      final pressure = adjustment(guided.component, 'Pressure');
      const inputs = GuideInputs(riderWeight: 72);

      // With 92 psi entered, rebound alone would be looked up for 92 psi.
      final current = {pressure.id: const NumericalValue(92)};
      final shown = guided.evaluate(inputs, current).firstWhere((r) => r.adjustment.name == 'Rebound');
      expect(shown.value, const StepValue(6));

      final applied = guideValuesToApply(guided, inputs, current);
      final byName = {for (final entry in applied.entries) entry.key.name: entry.value};
      expect(byName, {
        'Pressure': const NumericalValue(70),
        'Rebound': const StepValue(10),
        'LSC': const StepValue(4),
      });
    });

    test('leaves out values that cannot be applied', () {
      final guided = GuidedComponent(component('guided'), resolve(component('guided'))!);

      final applied = guideValuesToApply(guided, const GuideInputs(), {});

      expect(applied.keys.map((a) => a.name), ['LSC']);
    });
  });

  group('notes line', () {
    final guide = resolve(component('guided'))!.node.guide!;

    test('names the guides once and the weight used', () {
      expect(
        guideNotesLine([guide, guide], const GuideInputs(riderWeight: 82.04)),
        "Started from recommended values (Acme owner's manual (2027)) · 82 kg",
      );
      expect(
        guideNotesLine([guide], const GuideInputs()),
        "Started from recommended values (Acme owner's manual (2027))",
      );
    });

    test('is appended on its own line, once', () {
      expect(appendNotesLine('', 'line'), 'line');
      expect(appendNotesLine('Dry and dusty\n', 'line'), 'Dry and dusty\nline');
      expect(appendNotesLine('Dry and dusty\nline', 'line'), 'Dry and dusty\nline');
    });
  });

  test('a guided component without the catalog adjusters yields nothing to apply', () {
    final handBuilt = component('guided').copyWith(adjustments: <Adjustment>[]);
    final guided = GuidedComponent(handBuilt, resolve(handBuilt)!);
    expect(guideValuesToApply(guided, const GuideInputs(riderWeight: 82), {}), isEmpty);
    expect(guided.evaluate(const GuideInputs(riderWeight: 82), {}), isEmpty);
  });
}
