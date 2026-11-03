import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component_catalog.dart';
import 'package:bike_setup_tracker/models/component/setup_guide.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Catalog text with `<field>_<lang>` siblings: the parser reads English plus
/// the active language, and ids never change with the language.

const _fork = '''
brand: FOX
component_type: fork
revision: 2
option_values:
  damper:
    grip_x2:
      name: GRIP X2
      description: Four-way adjustable.
      description_de: Vierfach einstellbar.
      missing_adjustments: [Compression lever]
      missing_adjustments_de: [Druckstufenhebel]
      adjustments:
        - { name: Compression Mode, name_de: Druckstufenmodus, type: categorical, options: [Open, Firm], options_de: [Offen, Fest], notes: Mode lever, notes_de: Moduswahlhebel }
        - { name: Rebound, type: step, max: 16, notes: Slow, notes_de: Langsam }
        - { name: HSC, name_de: HSC, type: step, max: 8 }
guides:
  fox_2027:
    label: FOX owner's manual (2027)
    label_de: FOX Bedienungsanleitung (2027)
    source: https://example.com/manual
    rules:
      - target: compression_mode
        value: Firm
        note: Race tune
        note_de: Race-Abstimmung
      - target: rebound
        value: 5
changes:
  - revision: 2
    fix: { adjuster: compression_mode, field: notes, from: Lever, from_de: Hebel, to: Mode lever, to_de: Moduswahlhebel }
  - revision: 2
    review: Rebound range was corrected.
    review_de: Der Zugstufenbereich wurde korrigiert.
nodes:
  - label: "36"
    level: model
    category: Trail
    category_de: Trail-Gabeln
    note: Stiff chassis
    note_de: Steifes Fahrwerk
    specs: { spring: Air, spring_de: Luft, stanchion: 36mm, stanchion_de: 36 mm }
    guide: fox_2027
    tasks:
      fork:full_service: { interval: { moving_time_h: 125 }, source: FOX manual, source_de: FOX-Handbuch }
      fork:lower_leg_oil: { name: Lower leg oil, name_de: Gabelbeinöl, interval: { moving_time_h: 50 }, source: FOX manual }
    options:
      damper: [grip_x2]
''';

CatalogProduct _product(BrandCatalog catalog) => catalog.nodes.single as CatalogProduct;

String _fixed(String from, String to) => _fork.replaceFirst(from, to);

void main() {
  group('the active language', () {
    final de = parseCatalogFile(_fork, languageCode: 'de');
    final en = parseCatalogFile(_fork);

    test('replaces text with its sibling', () {
      final product = _product(de);
      final damper = product.options['damper']!.values.single;
      expect(product.category, 'Trail-Gabeln');
      expect(product.note, 'Steifes Fahrwerk');
      expect(product.specs.keys, containsAll(['spring', 'stanchion']));
      expect(damper.description, 'Vierfach einstellbar.');
      expect(damper.missingAdjustments, ['Druckstufenhebel']);
      expect(damper.adjustments.map((spec) => spec.build().name), ['Druckstufenmodus', 'Rebound', 'HSC']);
      expect(damper.adjustments.first.build().notes, 'Moduswahlhebel');
      expect((damper.adjustments.first.build() as CategoricalAdjustment).options, {'Offen', 'Fest'});
      expect(product.tasks['fork:full_service']!.source, 'FOX-Handbuch');
      expect(product.tasks['fork:lower_leg_oil']!.name, 'Gabelbeinöl');
    });

    test('keeps English where a sibling is missing', () {
      final damper = _product(de).options['damper']!.values.single;
      expect(damper.adjustments[1].build().name, 'Rebound');
      expect(damper.adjustments[1].build().notes, 'Langsam');
      expect(_product(de).tasks['fork:lower_leg_oil']!.source, 'FOX manual');
    });

    test('is English without a language, and for a language the app does not have', () {
      for (final catalog in [en, parseCatalogFile(_fork, languageCode: 'fr')]) {
        final product = _product(catalog);
        expect(product.category, 'Trail');
        expect(product.note, 'Stiff chassis');
        expect(product.options['damper']!.values.single.description, 'Four-way adjustable.');
        expect(product.options['damper']!.values.single.adjustments.first.build().name, 'Compression Mode');
      }
    });

    test('leaves no `_de` key in the adjustment data', () {
      for (final catalog in [en, de]) {
        for (final spec in _product(catalog).options['damper']!.values.single.adjustments) {
          expect(spec.raw.keys.where((key) => key.endsWith('_de')), isEmpty);
        }
      }
    });

    test('translates the setup guide and keeps the English label', () {
      final guide = _product(de).guide!;
      expect(guide.label, 'FOX Bedienungsanleitung (2027)');
      expect(guide.sourceLabel, "FOX owner's manual (2027)");
      expect(guide.rules.first.note, 'Race-Abstimmung');
      expect(_product(en).guide!.label, guide.sourceLabel);
      expect(_product(en).guide!.sourceLabel, guide.sourceLabel);
    });

    test('translates the revision summaries and the text of a fix', () {
      expect(de.changes.whereType<CatalogReview>().single.summary, 'Der Zugstufenbereich wurde korrigiert.');
      expect(en.changes.whereType<CatalogReview>().single.summary, 'Rebound range was corrected.');
      final fix = de.changes.whereType<CatalogFieldFix>().single;
      expect((fix.from, fix.to), ('Hebel', 'Moduswahlhebel'));
      final englishFix = en.changes.whereType<CatalogFieldFix>().single;
      expect((englishFix.from, englishFix.to), ('Lever', 'Mode lever'));
    });
  });

  group('ids and matching', () {
    test('ids, preset keys and levels are the same in every language', () {
      final de = _product(parseCatalogFile(_fork, languageCode: 'de'));
      final en = _product(parseCatalogFile(_fork));
      expect(de.id, en.id);
      expect(de.level, en.level);
      expect(de.label, en.label);
      expect(
        de.options['damper']!.values.single.adjustments.map((spec) => spec.presetKey),
        en.options['damper']!.values.single.adjustments.map((spec) => spec.presetKey),
      );
      expect(de.options['damper']!.values.single.adjustments.first.presetKey, 'fork:compression_mode');
    });

    test('a guide cell names the English option, and the index finds it in German', () {
      final catalog = parseCatalogFile(_fork, languageCode: 'de');
      final spec = _product(catalog).options['damper']!.values.single.adjustments.first;
      final cell = (_product(catalog).guide!.rules.first.output as ConstantOutput).value as GuideOption;

      expect(cell.option, 'Firm');
      expect(spec.sourceOptions, ['Open', 'Firm']);
      expect((spec.build() as CategoricalAdjustment).options.toList()[spec.sourceOptions.indexOf(cell.option)], 'Fest');
    });

    test('a guide cell that is no English option fails in German too', () {
      expect(
        () => parseCatalogFile(_fixed('value: Firm', 'value: Fest'), languageCode: 'de'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('"Fest", which is no option'))),
      );
    });
  });

  group('mistakes fail', () {
    void expectRejected(String yaml, Pattern message, {String language = 'de'}) {
      expect(
        () => parseCatalogFile(yaml, languageCode: language),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains(message))),
      );
    }

    test('an unknown language suffix', () {
      expectRejected(_fixed('category: Trail\n', 'category: Trail\n    category_xx: Trail\n'), 'unknown language "xx"');
    });

    test('English is no suffix', () {
      expectRejected(_fixed('category: Trail\n', 'category: Trail\n    category_en: Trail\n'), 'unknown language "en"');
    });

    test('a field that is not translated', () {
      expectRejected(_fixed('- label: "36"', '- label: "36"\n    label_de: "36 "'), '"label" of "36" is not translated');
      expectRejected(_fixed('      name: GRIP X2\n', '      name: GRIP X2\n      name_de: GRIP X2\n'), '"name" of option value');
      expectRejected(
        _fixed('specs: { spring: Air', 'specs: { wheel_size: 29, wheel_size_de: x, spring: Air'),
        'Unknown spec key "wheel_size_de"',
      );
    });

    test('a sibling without its English field', () {
      expectRejected(_fixed('    note: Stiff chassis\n', ''), '"note_de" of "36" has no English "note"');
    });

    test('a list with another length', () {
      expectRejected(_fixed('options_de: [Offen, Fest]', 'options_de: [Offen]'), 'as many items as "options"');
      expectRejected(_fixed('missing_adjustments_de: [Druckstufenhebel]', 'missing_adjustments_de: []'), 'as many items');
    });

    test('a list where a text is expected', () {
      expectRejected(_fixed('category_de: Trail-Gabeln', 'category_de: [Trail]'), 'is not a text');
    });

    test('a translated name for a generic task', () {
      expectRejected(
        _fixed('source: FOX manual, source_de: FOX-Handbuch }', 'source: FOX manual, name_de: Service }'),
        '"name" of task "fork:full_service"',
      );
    });

    test('a translated fix of a number field', () {
      final yaml = _fork
          .replaceFirst(
            "fix: { adjuster: compression_mode, field: notes, from: Lever, from_de: Hebel, to: Mode lever, to_de: Moduswahlhebel }",
            'fix: { adjuster: rebound, field: max, from: 12, from_de: 12, to: 16 }',
          );
      expectRejected(yaml, '"from" of "fix" of change 1 is not translated');
    });
  });
}
