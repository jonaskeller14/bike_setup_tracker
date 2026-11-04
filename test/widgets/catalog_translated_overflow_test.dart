import 'package:bike_setup_tracker/l10n/l10n.dart';
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

/// Catalog text in French, Italian, Spanish and Portuguese is longer than the
/// English and German text, so the picker and the setup guide card are laid out
/// in each of them on a small phone and a tablet with the largest system text
/// size, in light and dark.

typedef _Texts = ({
  String guideLabel,
  String ruleNote,
  String damper,
  String category,
  String pressure,
  List<String> modes,
});

const _texts = <String, _Texts>{
  'fr': (
    guideLabel: 'Manuel d’utilisation FOX 36 pour fourches à cartouche d’amortissement (2027)',
    ruleNote: 'Valeur de départ pour pilotes équipés de protections, à vérifier après la première sortie',
    damper: 'Amortisseur réglable sur quatre voies avec compression haute et basse vitesse séparées',
    category: 'Fourches all-mountain et enduro pour le bike park',
    pressure: 'Réglage de la pression d’air',
    modes: ['Ouvert', 'Ferme'],
  ),
  'it': (
    guideLabel: 'Manuale d’uso FOX 36 per forcelle con cartuccia di smorzamento (2027)',
    ruleNote: 'Valore di partenza per rider con protezioni, da controllare dopo la prima uscita',
    damper: 'Ammortizzatore regolabile in quattro vie con compressione ad alta e bassa velocità separate',
    category: 'Forcelle all-mountain ed enduro per il bike park',
    pressure: 'Regolazione della pressione dell’aria',
    modes: ['Aperto', 'Rigido'],
  ),
  'es': (
    guideLabel: 'Manual del usuario FOX 36 para horquillas con cartucho de amortiguación (2027)',
    ruleNote: 'Valor de partida para riders con protecciones, que conviene revisar tras la primera salida',
    damper: 'Amortiguador ajustable en cuatro vías con compresión de alta y baja velocidad por separado',
    category: 'Horquillas all-mountain y enduro para el bike park',
    pressure: 'Ajuste de la presión de aire',
    modes: ['Abierto', 'Firme'],
  ),
  'pt': (
    guideLabel: 'Manual do usuário FOX 36 para garfos com cartucho de amortecimento (2027)',
    ruleNote: 'Valor de partida para riders com proteções, a conferir depois da primeira saída',
    damper: 'Amortecedor ajustável em quatro vias com compressão de alta e baixa velocidade separadas',
    category: 'Garfos all-mountain e enduro para o bike park',
    pressure: 'Ajuste da pressão do ar',
    modes: ['Aberto', 'Firme'],
  ),
};

String _catalog(String language, _Texts t) =>
    '''
brand: FOX
component_type: fork
guides:
  fox_36:
    label: FOX 36 owner's manual (2027)
    label_$language: ${t.guideLabel}
    source: https://example.com/fox
    rules:
      - target: pressure
        unit: psi
        input: rider_weight
        input_unit: kg
        rows: { 70-80: 70, 80-90: 80, 90-100: 90 }
        note: Starting point
        note_$language: ${t.ruleNote}
      - { target: compression_mode, value: Firm }
option_values:
  damper:
    grip_x2:
      name: GRIP X2
      description: Four-way adjustable damper
      description_$language: ${t.damper}
      adjustments:
        - { name: Compression Mode, name_$language: Mode, type: categorical, options: [Open, Firm], options_$language: [${t.modes.join(', ')}] }
    grip_x:
      name: GRIP X
      description: Three-way adjustable damper
      description_$language: ${t.damper}
      adjustments:
        - { name: Compression Mode, name_$language: Mode, type: categorical, options: [Open, Firm], options_$language: [${t.modes.join(', ')}] }
nodes:
  - label: "36"
    level: model
    category: All-Mountain
    category_$language: ${t.category}
    guide: fox_36
    adjustments:
      - { name: Pressure, name_$language: ${t.pressure}, type: numerical, unit: psi, min: 0, max: 120 }
    children:
      - label: Factory
        level: trim
        options:
          damper: [grip_x2, grip_x]
          travel_mm: [150, 160]
''';

void main() {
  const sizes = {'small phone': Size(320, 640), 'tablet': Size(1024, 768)};

  Widget app(Locale locale, Widget home, Brightness brightness) {
    return MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
      child: localizedTestApp(
        locale: locale,
        theme: brightness == Brightness.dark ? materialAppDarkTheme : materialAppTheme,
        home: home,
      ),
    );
  }

  for (final MapEntry(key: language, value: texts) in _texts.entries) {
    final locale = Locale(language);
    final l10n = lookupAppLocalizations(locale);
    final catalog = parseCatalogFile(_catalog(language, texts), languageCode: language);

    for (final MapEntry(key: name, value: viewport) in sizes.entries) {
      for (final brightness in Brightness.values) {
        final label = '$language, $name, ${brightness.name}';

        testWidgets('the catalog picker fits: $label', (tester) async {
          tester.view
            ..physicalSize = viewport
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(
            Provider<ComponentCatalogRepository>.value(
              value: ComponentCatalogRepository.withCatalogs([catalog]),
              child: app(
                locale,
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
          expect(find.textContaining(texts.damper), findsWidgets);
        });

        testWidgets('the setup guide card fits: $label', (tester) async {
          tester.view
            ..physicalSize = viewport
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          var preset = catalogProducts(catalog).single;
          final damper = preset.axes.firstWhere((axis) => axis.id == 'damper');
          preset = preset.select(damper, damper.values.first);
          final application = buildCatalogApplication(preset, l10n);
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
              locale,
              Scaffold(
                body: SingleChildScrollView(
                  child: SetupGuideCard(
                    sections: [SetupGuideSection(guided, guided.evaluate(inputs, const {}, l10n))],
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
          expect(find.textContaining(texts.guideLabel), findsOneWidget);
          expect(find.text(texts.modes.last), findsOneWidget);
        });
      }
    }
  }
}
