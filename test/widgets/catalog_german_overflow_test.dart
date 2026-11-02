import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/setup_guide.dart';
import 'package:bike_setup_tracker/repositories/component_catalog_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/component_catalog_application.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:bike_setup_tracker/utils/setup_guide_actions.dart';
import 'package:bike_setup_tracker/widgets/setup_guide_card.dart';
import 'package:bike_setup_tracker/widgets/sheets/component_catalog_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../goldens/support/localized_test_app.dart';
import '../support/german_l10n.dart';

/// Catalog text in German is the longest text the picker and the setup guide
/// card show, so both are laid out on a small phone with the largest system
/// text size, in light and dark.

const _catalog = '''
brand: FOX
component_type: fork
guides:
  fox_36:
    label: FOX 36 owner's manual (2027)
    label_de: FOX 36 Bedienungsanleitung für Gabeln mit Kartuschendämpfer (2027)
    source: https://example.com/fox
    rules:
      - target: pressure
        unit: psi
        input: rider_weight
        input_unit: kg
        rows: { 70-80: 70, 80-90: 80, 90-100: 90 }
        note: Starting point
        note_de: Ausgangswert für Fahrerinnen und Fahrer mit Schutzausrüstung, bitte nach der ersten Ausfahrt prüfen
      - { target: compression_mode, value: Firm }
option_values:
  damper:
    grip_x2:
      name: GRIP X2
      description: Four-way adjustable damper
      description_de: Vierfach einstellbarer Dämpfer mit getrennter Hoch- und Niedergeschwindigkeits-Druckstufe
      adjustments:
        - { name: Compression Mode, name_de: Druckstufenmodus, type: categorical, options: [Open, Firm], options_de: [Offen, Fest] }
    grip_x:
      name: GRIP X
      description: Three-way adjustable damper
      description_de: Dreifach einstellbarer Dämpfer
      adjustments:
        - { name: Compression Mode, name_de: Druckstufenmodus, type: categorical, options: [Open, Firm], options_de: [Offen, Fest] }
nodes:
  - label: "36"
    level: model
    category: All-Mountain
    category_de: Allmountain- und Enduro-Gabeln für den Bikepark
    guide: fox_36
    adjustments:
      - { name: Pressure, name_de: Luftdruckeinstellung, type: numerical, unit: psi, min: 0, max: 120 }
    children:
      - label: Factory
        level: trim
        options:
          damper: [grip_x2, grip_x]
          travel_mm: [150, 160]
''';

void main() {
  const de = Locale('de');
  const sizes = {'small phone': Size(320, 640), 'tablet': Size(1024, 768)};

  Widget app(Widget home, Brightness brightness) {
    return MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
      child: localizedTestApp(
        locale: de,
        theme: brightness == Brightness.dark ? materialAppDarkTheme : materialAppTheme,
        home: home,
      ),
    );
  }

  for (final MapEntry(key: name, value: viewport) in sizes.entries) {
    for (final brightness in Brightness.values) {
      final label = '$name, ${brightness.name}';

      testWidgets('the catalog picker fits in German on a $label', (tester) async {
        tester.view
          ..physicalSize = viewport
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final repository = ComponentCatalogRepository.withCatalogs([parseCatalogFile(_catalog, languageCode: 'de')]);

        await tester.pumpWidget(
          Provider<ComponentCatalogRepository>.value(
            value: repository,
            child: app(
              Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showComponentCatalogPicker(context: context, componentType: ComponentType.fork),
                    child: const Text('open'),
                  ),
                ),
              ),
              brightness,
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // A brand with one model goes straight to its trims.
        for (final step in ['FOX', 'Factory']) {
          await tester.tap(find.text(step));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'after $step');
        }
        expect(find.textContaining('Vierfach einstellbarer'), findsOneWidget);
      });

      testWidgets('the setup guide card fits in German on a $label', (tester) async {
        tester.view
          ..physicalSize = viewport
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var preset = catalogProducts(parseCatalogFile(_catalog, languageCode: 'de')).single;
        final damper = preset.axes.firstWhere((axis) => axis.id == 'damper');
        preset = preset.select(damper, damper.values.first);
        final application = buildCatalogApplication(preset, germanL10n);
        final component = Component(
          name: application.name,
          componentType: application.componentType,
          installations: const [],
          adjustments: application.adjustments,
          preset: application.preset,
        );
        final guided = GuidedComponent(component, preset);
        const inputs = GuideInputs(riderWeight: 82);

        await tester.pumpWidget(
          app(
            Scaffold(
              body: SingleChildScrollView(
                child: SetupGuideCard(
                  sections: [SetupGuideSection(guided, guided.evaluate(inputs, const {}, germanL10n))],
                  inputs: inputs,
                  onApply: (_) {},
                  onApplyAll: () {},
                ),
              ),
            ),
            brightness,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Bedienungsanleitung'), findsOneWidget);
        expect(find.text('Fest'), findsOneWidget);
      });
    }
  }
}
