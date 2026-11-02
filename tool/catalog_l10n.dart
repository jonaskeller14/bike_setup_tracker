// ignore_for_file: depend_on_referenced_packages
// Reports the translation state of the component catalog (data/component_presets/).
//
//   dart run tool/catalog_l10n.dart missing de   # file:line field "English", with a suggestion
//   dart run tool/catalog_l10n.dart stats        # strings and words per language
//
// Read-only on purpose: it never rewrites a YAML file, because anchors and
// comments would be lost. Which fields are translatable is defined once, in
// lib/utils/catalog_translations.dart, which the coverage test shares.
// `missing` exits with 1 while a text lacks its translation.
import 'dart:io';

import 'package:bike_setup_tracker/utils/catalog_translations.dart';
import 'package:yaml/yaml.dart';

const _catalogDir = 'data/component_presets';

void main(List<String> args) {
  final files = _catalogFiles();
  switch (args) {
    case ['missing', final language]:
      exitCode = _missing(files, language);
    case ['stats']:
      _stats(files);
    default:
      stderr.writeln('Usage: dart run tool/catalog_l10n.dart missing <lang> | stats');
      exitCode = 64;
  }
}

/// `(path, strings)` per brand file, sorted by path.
List<({String path, List<CatalogString> strings})> _catalogFiles() {
  final files = Directory(_catalogDir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.yaml'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  return [
    for (final file in files)
      (
        path: file.path.replaceAll('\\', '/'),
        strings: catalogStrings(loadYaml(file.readAsStringSync()) as YamlMap),
      ),
  ];
}

int _missing(List<({String path, List<CatalogString> strings})> files, String language) {
  // The same English text translated once is suggested for its other places.
  final known = <String, String>{};
  for (final (:strings, path: _) in files) {
    for (final string in strings) {
      switch ((string.english, string.translations[language])) {
        case (final String english, final String translation):
          known.putIfAbsent(english.trim(), () => translation.trim());
        case (final List<String> english, final List<String> translation):
          for (final (index, item) in english.indexed) {
            known.putIfAbsent(item, () => translation[index]);
          }
      }
    }
  }

  var missing = 0;
  for (final (:path, :strings) in files) {
    for (final string in strings) {
      if (string.translations.containsKey(language)) continue;
      missing++;
      final suggestion = switch (string.english) {
        final String english => known[english.trim()],
        final List<String> english when english.every(known.containsKey) => [for (final item in english) known[item]].toString(),
        _ => null,
      };
      final english = string.english is String ? (string.english as String).trim() : string.english.toString();
      stdout.writeln(
        '$path:${string.line} ${string.field} (${string.path}) ${_shorten(english)}'
        '${suggestion == null ? '' : '\n    suggestion: ${_shorten(suggestion)}'}',
      );
    }
  }
  stdout.writeln(missing == 0 ? 'Nothing is missing in "$language".' : '$missing text(s) missing in "$language".');
  return missing == 0 ? 0 : 1;
}

void _stats(List<({String path, List<CatalogString> strings})> files) {
  final all = [for (final file in files) ...file.strings];
  final languages = {for (final string in all) ...string.translations.keys}.toList()..sort();
  final fields = <String, int>{};
  for (final string in all) {
    fields.update(string.field, (count) => count + 1, ifAbsent: () => 1);
  }

  stdout.writeln('${all.length} texts, ${_words(all.expand((string) => string.englishTexts))} English words');
  for (final entry in fields.entries.toList()..sort((a, b) => b.value.compareTo(a.value))) {
    stdout.writeln('  ${entry.key.padRight(20)} ${entry.value}');
  }
  for (final language in languages) {
    final translated = all.where((string) => string.translations.containsKey(language)).toList();
    final words = _words(
      translated.expand((string) {
        final text = string.translations[language]!;
        return text is List<String> ? text : [text as String];
      }),
    );
    stdout.writeln('$language: ${translated.length}/${all.length} texts, $words words');
  }
}

int _words(Iterable<String> texts) => texts.fold(0, (sum, text) => sum + text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length);

String _shorten(String text) {
  final single = text.replaceAll(RegExp(r'\s+'), ' ');
  return single.length <= 90 ? single : '${single.substring(0, 87)}...';
}
