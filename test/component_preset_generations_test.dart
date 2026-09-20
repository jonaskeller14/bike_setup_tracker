import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/component_preset.dart';
import 'package:bike_setup_tracker/utils/component_preset_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_search.dart';
import 'package:bike_setup_tracker/widgets/sheets/component_preset_picker.dart';
import 'package:flutter_test/flutter_test.dart';

/// Generations of one model are authored as separate blocks sharing a `model:`
/// name and told apart by `year_range` — the picker merges them into a single
/// model row whose trims carry the years (`FOX › 36 › Factory (2021-2024)`).

const _yaml = '''
brand: FOX
component_type: fork
dampers:
  grip_x2:
    name: GRIP X2
    adjustments:
      - { name: Low-Speed Compression, type: step, max: 18 }
  grip2_2021:
    name: GRIP2 VVC
    adjustments:
      - { name: Low-Speed Compression, type: step, max: 16 }
forks:
  - model: "36"
    category: All-Mountain
    year_range: "2025-2026"
    url: https://ridefox.com/36
    trims:
      - trim: Factory
        key: fork-fox-36-factory-2025
        dampers: [grip_x2]
      - trim: Performance
        key: fork-fox-36-performance-2025
        dampers: [grip_x2]
  - model: "36"
    category: All-Mountain
    year_range: "2021-2024"
    url: https://ridefox.com/36-2021
    trims:
      - trim: Factory
        key: fork-fox-36-factory-2021
        dampers: [grip2_2021]
      - trim: Rhythm
        key: fork-fox-36-rhythm-2022
        dampers: [grip2_2021]
        year_range: "2022-2024"
''';

void main() {
  late List<ComponentPresetVariant> variants;

  setUpAll(() => variants = parseBrandFile(_yaml));

  group('parsing', () {
    test('same-named blocks flatten into one model', () {
      expect(variants.map((v) => v.model).toSet(), {'36'});
      expect(variants, hasLength(4));
    });

    test('each trim carries its generation years', () {
      expect(
        {for (final v in variants) '${v.trim} ${v.yearRange}'},
        {'Factory 2025-2026', 'Performance 2025-2026', 'Factory 2021-2024', 'Rhythm 2022-2024'},
      );
    });

    test('a trim-level year_range overrides the model', () {
      final rhythm = variants.firstWhere((v) => v.trim == 'Rhythm');
      expect(rhythm.yearRange, '2022-2024');
    });

    test('generation-level url still rides down onto each trim', () {
      final rhythm = variants.firstWhere((v) => v.trim == 'Rhythm');
      expect(rhythm.url, 'https://ridefox.com/36-2021');
    });
  });

  group('key', () {
    test('separates two generations of the same trim', () {
      final factories = variants.where((v) => v.trim == 'Factory').toList();
      expect(factories, hasLength(2));
      expect(factories.map((v) => v.key).toSet(), hasLength(2));
      expect(factories.first.key, 'fork-fox-36-factory-2025');
    });

    test('a trim without one is a data error, not a silent null', () {
      const yaml = '''
brand: FOX
component_type: fork
forks:
  - model: "36"
    trims:
      - trim: Factory
''';
      expect(
        () => parseBrandFile(yaml),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          allOf(contains('36 Factory'), contains('key')),
        )),
      );
    });
  });

  group('search', () {
    test('a year reaches the generation that ran it', () {
      final results = filterPresetVariants(variants, '2021');
      expect(results.map((v) => v.trim), ['Factory']);
    });

    test('year narrows an otherwise ambiguous model query', () {
      expect(filterPresetVariants(variants, 'fox 36'), hasLength(4));
      expect(filterPresetVariants(variants, 'fox 36 2025'), hasLength(2));
    });
  });

  group('presetYearSpan', () {
    test('spans the merged generations', () {
      expect(presetYearSpan(variants), '2021–2026');
    });

    test('keeps the authored string when the trims agree', () {
      expect(
        presetYearSpan(variants.where((v) => v.yearRange == '2025-2026').toList()),
        '2025-2026',
      );
    });

    test('is null when no trim declares years', () {
      const undated = ComponentPresetVariant(
        key: 'shock-cane-creek-dbcoil-il',
        brand: 'Cane Creek',
        model: 'DBcoil',
        trim: 'IL',
        componentType: ComponentType.shock,
      );
      expect(presetYearSpan(const [undated]), isNull);
    });
  });
}
