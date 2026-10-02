import 'package:bike_setup_tracker/utils/component_catalog_application.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_catalog_search.dart';
import 'package:bike_setup_tracker/utils/component_preset_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

/// Name-field autocomplete and picker search on the generic catalog:
/// [suggestPresets] ranks the products and expands them into flat suggestion
/// rows. Fixtures are small inline YAML files run through the real
/// [parseCatalogFile].

List<ResolvedPreset> _products(String yaml) => catalogProducts(parseCatalogFile(yaml)).toList();

// A FOX file: one multi-damper trim (36 Factory) and one single-damper trim
// (38 Factory), plus a RockShox file for cross-brand ranking.
const _foxYaml = '''
brand: FOX
component_type: fork
option_values:
  damper:
    grip_x2:
      name: GRIP X2
      adjustments:
        - { name: LSC, type: step, max: 18 }
    grip:
      name: GRIP
      adjustments:
        - { name: Compression, type: step, max: 3 }
nodes:
  - label: "36"
    level: model
    children:
      - label: "2025–2026"
        level: generation
        id: "2025"
        years: "2025-2026"
        children:
          - label: Factory
            level: trim
            options:
              damper: [grip_x2, grip]
              travel_mm: [150, 160]
  - label: "38"
    level: model
    years: "2022-2024"
    children:
      - label: Factory
        level: trim
        options:
          damper: [grip_x2]
          travel_mm: [170, 180]
''';

const _rockShoxYaml = '''
brand: RockShox
component_type: fork
option_values:
  damper:
    charger:
      name: Charger 3
      adjustments:
        - { name: LSC, type: step, max: 15 }
nodes:
  - label: Lyrik
    level: model
    children:
      - label: Ultimate
        level: trim
        options:
          damper: [charger]
          travel_mm: [150, 160]
''';

const _ohlinsYaml = '''
brand: Öhlins
component_type: fork
nodes:
  - label: RXF36
    level: model
''';

const _ohlLabelYaml = '''
brand: FOX
component_type: fork
nodes:
  - label: Ohlala
    level: model
''';

void main() {
  final fox = _products(_foxYaml);
  final all = [...fox, ..._products(_rockShoxYaml)];

  group('suggestPresets', () {
    test('returns nothing below the 3-character threshold', () {
      expect(suggestPresets(fox, 'fo'), isEmpty);
      expect(suggestPresets(fox, ''), isEmpty);
    });

    test('a product with a choice of dampers yields one suggestion per damper', () {
      final results = suggestPresets(fox, 'fox 36');

      expect(results.map(presetDisplayName), ['FOX 36 Factory GRIP X2', 'FOX 36 Factory GRIP']);
      expect(results.map((s) => s.selections['damper']!.id), ['grip_x2', 'grip']);
      expect(results.every((s) => s.openRequiredAxes.isEmpty), isTrue);
    });

    test('optional axes stay unset', () {
      final results = suggestPresets(fox, 'fox');

      expect(results, isNotEmpty);
      expect(results.every((s) => !s.selections.containsKey('travel_mm')), isTrue);
    });

    test('a single-damper product yields one suggestion, damper resolved', () {
      final results = suggestPresets(fox, 'fox 38');

      expect(results, hasLength(1));
      expect(presetDisplayName(results.single), 'FOX 38 Factory'); // damper not appended
      expect(results.single.selections['damper']!.label, 'GRIP X2');
    });

    test('matches on damper name and on years', () {
      expect(suggestPresets(all, 'charger').map(presetDisplayName), ['RockShox Lyrik Ultimate']);
      expect(suggestPresets(all, 'fox 2022').map(presetDisplayName), ['FOX 38 Factory']);
    });

    test('brand-prefix matches rank above generic token matches', () {
      // "grip" only appears as a FOX damper; "rock" prefixes the brand.
      final results = suggestPresets(all, 'rock');
      expect(results.first.catalog.brand, 'RockShox');
    });

    test('finds an accented brand by its plain spelling, and ranks it as a brand match', () {
      // "ohl" also sits in the FOX model name, which comes first in the catalog.
      final catalog = [..._products(_ohlLabelYaml), ..._products(_ohlinsYaml)];

      expect(suggestPresets(catalog, 'ohlins').map(presetDisplayName), ['Öhlins RXF36']);
      expect(suggestPresets(catalog, 'öhlins').map(presetDisplayName), ['Öhlins RXF36']);
      expect(suggestPresets(catalog, 'ohl').map(presetDisplayName), ['Öhlins RXF36', 'FOX Ohlala']);
    });

    test('respects the suggestion limit', () {
      expect(suggestPresets(fox, 'fox', limit: 2), hasLength(2));
      expect(suggestPresets(fox, 'fox'), hasLength(3));
    });
  });

  group('filterPresets', () {
    test('keeps matching products in catalog order, one row per product', () {
      final results = filterPresets(all, 'factory');

      expect(results.map(presetDisplayName), ['FOX 36 Factory', 'FOX 38 Factory']);
    });

    test('every token has to match', () {
      expect(filterPresets(all, 'factory lyrik'), isEmpty);
      expect(filterPresets(all, 'ULTIMATE lyrik'), hasLength(1));
    });
  });
}
