import 'package:bike_setup_tracker/models/component_preset.dart';
import 'package:bike_setup_tracker/utils/component_preset_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_search.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 4 name-field autocomplete (C2): [suggestPresets] ranks and expands the
/// catalog index into flat suggestion rows. Fixtures are small inline YAML files
/// run through the real [parseBrandFile] so parsing and suggesting are exercised
/// together.

List<ComponentPresetVariant> _variants(String yaml) => parseBrandFile(yaml);

// A FOX file: one multi-damper trim (36 Factory) and one single-damper trim
// (38 Factory), plus a RockShox file for cross-brand ranking.
const _foxYaml = '''
brand: FOX
component_type: fork
dampers:
  grip_x2:
    name: GRIP X2
    adjustments:
      - { name: Low-Speed Compression, type: step, max: 18 }
  grip:
    name: GRIP
    adjustments:
      - { name: Compression, type: step, max: 3 }
forks:
  - model: "36"
    category: Trail
    year_range: 2025-26
    trims:
      - trim: Factory
        travel_mm: [150, 160]
        dampers: [grip_x2, grip]
        spring: Air
        adjustments:
          - { name: Pressure, type: numerical, unit: psi }
  - model: "38"
    category: Enduro
    year_range: 2025-26
    trims:
      - trim: Factory
        travel_mm: [170]
        dampers: [grip_x2]
        spring: Air
        adjustments:
          - { name: Pressure, type: numerical, unit: psi }
''';

const _rockShoxYaml = '''
brand: RockShox
component_type: fork
dampers:
  charger:
    name: Charger 3
    adjustments:
      - { name: Low-Speed Compression, type: step, max: 15 }
forks:
  - model: "Lyrik"
    category: Enduro
    year_range: 2025-26
    trims:
      - trim: Ultimate
        travel_mm: [150, 160]
        dampers: [charger]
        spring: Air
        adjustments:
          - { name: Pressure, type: numerical, unit: psi }
''';

void main() {
  final fox = _variants(_foxYaml);
  final all = [..._variants(_foxYaml), ..._variants(_rockShoxYaml)];

  group('suggestPresets', () {
    test('returns nothing below the 3-character threshold', () {
      expect(suggestPresets(fox, 'fo'), isEmpty);
      expect(suggestPresets(fox, ''), isEmpty);
    });

    test('multi-damper trim yields one suggestion per damper, disambiguated', () {
      final results = suggestPresets(fox, 'fox 36');
      expect(results.map((s) => s.displayName), [
        'FOX 36 Factory GRIP X2',
        'FOX 36 Factory GRIP',
      ]);
      // Each row carries its own damper.
      expect(results.map((s) => s.damper?.name), ['GRIP X2', 'GRIP']);
    });

    test('single-damper trim yields one suggestion, damper resolved, no append', () {
      final results = suggestPresets(fox, 'fox 38');
      expect(results, hasLength(1));
      expect(results.single.displayName, 'FOX 38 Factory'); // damper not appended
      expect(results.single.damper?.name, 'GRIP X2');
    });

    test('matches on damper name too', () {
      final results = suggestPresets(fox, 'grip x2');
      expect(results, isNotEmpty);
      expect(results.every((s) => s.displayName.contains('Factory')), isTrue);
    });

    test('brand-prefix matches rank above generic token matches', () {
      // "charger" only appears as a RockShox damper; "rock" prefixes the brand.
      final results = suggestPresets(all, 'rock');
      expect(results.first.variant.brand, 'RockShox');
    });

    test('respects the suggestion limit', () {
      final results = suggestPresets(fox, 'fox', limit: 2);
      expect(results, hasLength(2));
    });
  });

  group('presetSuggestionSubtitle', () {
    test('joins damper and travel', () {
      final suggestion = suggestPresets(fox, 'fox 38').single;
      expect(presetSuggestionSubtitle(suggestion), 'GRIP X2 · 170 mm');
    });

    test('shows a travel range for multi-travel trims', () {
      final suggestion = suggestPresets(fox, 'fox 36').first;
      expect(presetSuggestionSubtitle(suggestion), 'GRIP X2 · 150–160 mm');
    });
  });
}
