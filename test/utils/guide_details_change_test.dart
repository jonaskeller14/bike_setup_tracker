import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/utils/component_catalog_application.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:bike_setup_tracker/utils/guide_details_change.dart';
import 'package:flutter_test/flutter_test.dart';

const _catalog = '''
brand: FOX
component_type: fork
option_values:
  damper:
    grip:
      name: GRIP
      adjustments:
        - { name: Rebound, type: step, max: 13 }
        - { name: LSC, type: step, max: 10 }
    grip2:
      name: GRIP2
      adjustments:
        - { name: HSR, type: step, max: 8 }
nodes:
  - label: "38"
    level: model
    adjustments:
      - { name: Pressure, type: numerical, unit: psi, min: 0, max: 100 }
      - { name: Volume Spacers, type: step, max: 6, visualization: stepper }
    options:
      damper: [grip]
      travel_mm: [160, 170]
  - label: "36"
    level: model
    adjustments:
      - { name: Pressure, type: numerical, unit: psi, min: 0, max: 100 }
    options:
      damper: [grip, grip2]
''';

void main() {
  late List<ResolvedPreset> products;

  setUpAll(() {
    products = catalogProducts(parseCatalogFile(_catalog)).toList();
  });

  ResolvedPreset product(String id) => products.firstWhere((p) => p.node.id == id);

  ResolvedPreset choose(ResolvedPreset preset, String axisId, Object valueId) {
    final axis = preset.axes.firstWhere((axis) => axis.id == axisId);
    return preset.select(axis, axis.values.firstWhere((value) => value.id == valueId));
  }

  Component componentFor(ResolvedPreset preset) {
    final app = buildCatalogApplication(preset, englishL10n);
    return Component(
      name: app.name,
      componentType: app.componentType,
      installations: const [],
      adjustments: app.adjustments,
      preset: app.preset,
    );
  }

  Component replacing(Component component, String name, Adjustment Function(Adjustment) change) => component.copyWith(
    adjustments: [for (final a in component.adjustments) a.name == name ? change(a) : a],
  );

  SagAdjustment sagOf(List<Adjustment> adjustments) => adjustments.whereType<SagAdjustment>().single;

  test('choosing travel changes only the preset map, and the SAG takes the travel', () {
    final current = product('38');
    final component = componentFor(current);
    expect(sagOf(component.adjustments).referenceTravelMm, isNull);

    final change = planGuideDetailsChange(component, current, choose(current, 'travel_mm', 170), englishL10n);

    expect(change.added, isEmpty);
    expect(change.preset['travel_mm'], 170);
    expect(change.adjustments.map((a) => a.id), component.adjustments.map((a) => a.id));
    expect(sagOf(change.adjustments).referenceTravelMm, 170);
    for (final (i, adjustment) in component.adjustments.indexed) {
      if (adjustment is! SagAdjustment) expect(change.adjustments[i], same(adjustment));
    }
  });

  test('a SAG with its own travel keeps it', () {
    final current = product('38');
    final sag = sagOf(componentFor(current).adjustments);
    final component = replacing(componentFor(current), sag.name, (_) => sag.copyWith(referenceTravelMm: 160.0));

    final change = planGuideDetailsChange(component, current, choose(current, 'travel_mm', 170), englishL10n);

    expect(sagOf(change.adjustments).referenceTravelMm, 160);
  });

  test("a range the rider changed stays the rider's", () {
    final current = product('38');
    final component = replacing(componentFor(current), 'Volume Spacers', (a) => (a as StepAdjustment).copyWith(max: 4));

    final change = planGuideDetailsChange(component, current, choose(current, 'travel_mm', 160), englishL10n);

    expect((change.adjustments.firstWhere((a) => a.name == 'Volume Spacers') as StepAdjustment).max, 4);
  });

  test('an open damper brings its adjusters as added', () {
    final current = product('36');
    final component = componentFor(current);
    expect(current.openRequiredAxes.single.id, 'damper');

    final change = planGuideDetailsChange(component, current, choose(current, 'damper', 'grip'), englishL10n);

    expect(change.added.map((a) => a.name), ['Rebound', 'LSC']);
    expect(change.adjustments, component.adjustments);
    expect(change.preset['damper'], 'grip');
  });

  test('a catalog adjuster the rider removed is not proposed again', () {
    final current = product('38');
    final full = componentFor(current);
    final component = full.copyWith(
      adjustments: [
        for (final a in full.adjustments)
          if (a.name != 'LSC') a,
      ],
    );

    final change = planGuideDetailsChange(component, current, choose(current, 'travel_mm', 160), englishL10n);

    expect(change.added, isEmpty);
  });
}
