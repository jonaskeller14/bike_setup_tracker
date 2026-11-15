import 'dart:io';
import 'dart:ui';

import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/utils/adjustment_presets.dart';
import 'package:bike_setup_tracker/utils/adjustment_role.dart';
import 'package:bike_setup_tracker/utils/catalog_translations.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Catalog text in other languages (`<field>_<lang>` siblings): complete for
/// every shipped language, consistent, and parseable. The same field
/// definition drives `tool/catalog_l10n.dart`.

/// What is wrong with the translations to [language] in [strings]; empty when
/// every text has a sibling of the same shape.
List<String> coverageProblems(List<CatalogString> strings, String language) {
  final problems = <String>[];
  for (final string in strings) {
    final where = 'line ${string.line}, ${string.field} (${string.path})';
    final translation = string.translations[language];
    if (translation == null) {
      problems.add('$where: no ${string.field}_$language');
    } else if (string.english is List<String>) {
      final english = string.english as List<String>;
      if (translation is! List<String> || translation.length != english.length) {
        problems.add('$where: ${string.field}_$language needs ${english.length} items');
      } else if (translation.toSet().length != translation.length) {
        problems.add('$where: ${string.field}_$language repeats an item');
      }
    } else if (translation is! String || translation.trim().isEmpty) {
      problems.add('$where: ${string.field}_$language is empty');
    }
  }
  return problems;
}

/// The same English text written two ways in [language], per field.
List<String> inconsistencies(List<CatalogString> strings, String language) {
  final seen = <String, String>{};
  final problems = <String>{};
  for (final string in strings) {
    final translation = string.translations[language];
    if (translation == null) continue;
    final pairs = switch ((string.english, translation)) {
      (final String english, final String translated) => [(english, translated)],
      (final List<String> english, final List<String> translated) when english.length == translated.length => [
        for (final (index, item) in english.indexed) (item, translated[index]),
      ],
      _ => const <(String, String)>[],
    };
    for (final (english, translated) in pairs) {
      final key = '${string.field}: ${english.trim()}';
      final earlier = seen.putIfAbsent(key, () => translated.trim());
      if (earlier != translated.trim()) problems.add('$key -> "$earlier" and "${translated.trim()}"');
    }
  }
  return problems.toList();
}

List<CatalogString> _strings(String yaml) => catalogStrings(loadYaml(yaml) as YamlMap);

void main() {
  final catalogDir = Directory(p.join('data', 'component_presets'));
  final files = catalogDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.yaml'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  group('the coverage check', () {
    const yaml = '''
brand: FOX
component_type: fork
option_values:
  damper:
    d:
      name: D
      description: Four-way adjustable.
      description_de: Vierfach einstellbar.
      missing_adjustments: [Lever, Switch]
      missing_adjustments_de: [Hebel]
      adjustments:
        - { name: Mode, name_de: Modus, type: categorical, options: [Open, Firm], options_de: [Offen, Offen], notes: Lever }
nodes:
  - label: "36"
    level: model
    category: Trail
    category_de: " "
    note: Stiff
''';

    test('lists every text without a sibling, of the wrong shape or empty', () {
      final problems = coverageProblems(_strings(yaml), 'de');

      expect(problems, hasLength(5));
      expect(problems, contains(contains('missing_adjustments_de needs 2 items')));
      expect(problems, contains(contains('options_de repeats an item')));
      expect(problems, contains(contains('no notes_de')));
      expect(problems, contains(contains('category_de is empty')));
      expect(problems, contains(contains('no note_de')));
    });

    test('is empty for a complete file', () {
      expect(
        coverageProblems(_strings('''
brand: FOX
component_type: fork
nodes:
  - label: "36"
    level: model
    note: Stiff
    note_de: Steif
'''), 'de'),
        isEmpty,
      );
    });

    test('finds one English text translated two ways', () {
      final problems = inconsistencies(_strings('''
brand: FOX
component_type: fork
option_values:
  damper:
    d:
      name: D
      adjustments:
        - { name: Rebound, name_de: Zugstufe, type: step, max: 5 }
        - { name: Rebound, name_de: Rebound, type: step, max: 5 }
        - { name: HSC, name_de: HSC, type: step, max: 5 }
nodes:
  - label: "36"
    level: model
'''), 'de');

      expect(problems, ['name: Rebound -> "Zugstufe" and "Rebound"']);
    });

    test('counts an anchored map once', () {
      final strings = _strings('''
brand: FOX
component_type: fork
nodes:
  - label: A
    level: model
    specs: &air { spring: Air }
  - label: B
    level: model
    specs: *air
''');

      expect(strings.where((string) => string.field == 'spring'), hasLength(1));
    });
  });

  test('every shipped language is one the app supports', () {
    final supported = AppLocalizations.supportedLocales.map((locale) => locale.languageCode);
    expect(supported, containsAll(shippedCatalogLanguages));
  });

  for (final file in files) {
    final relative = p.relative(file.path, from: catalogDir.path);

    group(relative, () {
      late String source;
      late List<CatalogString> strings;

      setUpAll(() {
        source = file.readAsStringSync();
        strings = _strings(source);
      });

      for (final language in shippedCatalogLanguages) {
        test('has every text in $language', () {
          expect(coverageProblems(strings, language), isEmpty);
        });
      }

      test('parses in every supported language', () {
        for (final locale in AppLocalizations.supportedLocales) {
          expect(() => parseCatalogFile(source, languageCode: locale.languageCode), returnsNormally);
        }
      });

      for (final MapEntry(key: language, value: researchNote) in _researchNotes.entries) {
        test('rider-facing $language text carries no research notes', () {
          for (final string in strings.where((string) => const {'description', 'note', 'notes'}.contains(string.field))) {
            final translated = string.translations[language];
            if (translated is! String) continue;
            final match = researchNote.firstMatch(translated);
            expect(match, isNull, reason: 'line ${string.line}: "${match?[0]}" in "$translated"');
          }
        });
      }

      for (final language in shippedCatalogLanguages) {
        test('adjusters with a generic template are named like it in $language', () {
          final templates = _templateNames(language);
          final type = p.split(relative).first;
          final unmatched = <String>[];
          void visit(Object? node) {
            switch (node) {
              case YamlMap():
                if (node['adjustments'] case final YamlList adjustments) {
                  for (final adjuster in adjustments.whereType<YamlMap>()) {
                    final name = adjuster['name']?.toString();
                    if (name == null || adjuster['name_$language'] == null) continue;
                    final id = adjuster['id']?.toString() ?? adjustmentNameSlug(name);
                    final template = templates['${_camelToSnake(type)}:$id'];
                    if (template != null && template != adjuster['name_$language'].toString()) {
                      unmatched.add('$name: "${adjuster['name_$language']}" but the template says "$template"');
                    }
                  }
                }
                node.values.forEach(visit);
              case YamlList():
                node.forEach(visit);
            }
          }

          visit(loadYaml(source));
          expect(unmatched, isEmpty);
        });
      }
    });
  }

  for (final language in shippedCatalogLanguages) {
    test('one English text has one $language text everywhere', () {
      final all = [
        for (final file in files) ..._strings(file.readAsStringSync()),
      ];
      expect(inconsistencies(all, language), isEmpty);
    });
  }
}

String _camelToSnake(String name) => name.replaceAllMapped(RegExp('[A-Z]'), (match) => '_${match[0]!.toLowerCase()}');

/// The name of every generic adjustment template in [language], by preset key.
Map<String, String> _templateNames(String language) {
  final l10n = lookupAppLocalizations(Locale(language));
  return {
    for (final preset in [
      ...componentAdjustmentPresetsFor(l10n).values.expand((presets) => presets),
      ...personAdjustmentPresetsFor(l10n),
    ])
      if (preset.presetKey != null) preset.presetKey!: preset.name,
  };
}

/// `_researchNote` of `component_catalog_test.dart` per language.
final Map<String, RegExp> _researchNotes = {
  'de': RegExp(
    r'https?://|\bquelle[nd]?\b|\bgeprüft|\bbestätigt|\bverifizier|follow-?up|nicht (noch )?(veröffentlicht|publiziert)|'
    r'\blaut (handbuch|test|artikel|produktseite)|siehe dämpfer|produktseite|unvollständig|selbst (hinzufügen|ergänzen)',
    caseSensitive: false,
  ),
  'fr': RegExp(
    r'https?://|sources?|vérifié|confirm|follow-?up|non publi|page produit|incomplet|vous-même',
    caseSensitive: false,
  ),
  'it': RegExp(
    r'https?://|\bfont[ei]\b|\bverific|\bconferm|follow-?up|non pubblicat|pagina del prodotto|incomplet|da solo',
    caseSensitive: false,
  ),
  'es': RegExp(
    r'https?://|\bfuentes?\b|\bverific|\bconfirm|follow-?up|no publicad|página del producto|incomplet|tú mismo',
    caseSensitive: false,
  ),
  'pt': RegExp(
    r'https?://|\bfontes?\b|\bverific|\bconfirm|follow-?up|não publicad|página do produto|incomplet|você mesmo',
    caseSensitive: false,
  ),
};
