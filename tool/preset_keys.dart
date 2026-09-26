/// Derives and inserts the permanent `key:` of every trim in the component
/// preset catalog (`data/component_presets/`).
///
/// A trim's key is **authored once and then frozen**: it is persisted on user
/// components (`Component.presetKey`), so it has to outlive `model:` / `trim:`
/// renames and `year_range` extensions. This tool therefore only ever *adds* a
/// key that is missing — it never rewrites one that already exists, and the
/// derivation below is a convenience for authoring, not a rule the catalog has
/// to keep satisfying. `test/component_presets_test.dart` is what enforces the
/// shape and the global uniqueness.
///
///     dart run tool/preset_keys.dart            # report trims without a key
///     dart run tool/preset_keys.dart --write    # insert the missing keys
///
/// Edits insert a single line under `- trim:` instead of re-serializing the
/// YAML, so comments and anchors/aliases survive untouched.
library;

// A maintenance CLI: stdout is its output channel.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:yaml/yaml.dart';

const String _catalogDir = 'data/component_presets';

void main(List<String> args) {
  final bool write = args.contains('--write');

  final Directory dir = Directory(_catalogDir);
  if (!dir.existsSync()) {
    stderr.writeln('Run this from the repository root — "$_catalogDir" not found.');
    exitCode = 1;
    return;
  }

  final List<File> files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.yaml')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final Map<String, String> seen = <String, String>{}; // key -> where it was first seen
  var missing = 0;
  var duplicates = 0;

  for (final file in files) {
    final String source = file.readAsStringSync();
    final String eol = source.contains('\r\n') ? '\r\n' : '\n';
    final List<String> lines = source.split(eol);
    final List<_Insertion> pending = <_Insertion>[];

    for (final trim in _trims(loadYaml(source))) {
      final String key = trim.existingKey ?? trim.derivedKey;
      final String where = '${_display(file.path)}: "${trim.model} ${trim.trim}"';

      final String? clash = seen[key];
      if (clash == null) {
        seen[key] = where;
      } else {
        print('DUPLICATE "$key" — $where collides with $clash');
        duplicates++;
      }

      if (trim.existingKey != null) continue;
      missing++;
      if (write) {
        pending.add(_Insertion(trim.line, '${' ' * trim.column}key: $key'));
      } else {
        print('missing — $where -> $key');
      }
    }

    if (pending.isEmpty) continue;
    // Bottom-up, so the earlier line numbers stay valid as we insert.
    pending.sort((a, b) => b.line.compareTo(a.line));
    for (final insertion in pending) {
      lines.insert(insertion.line + 1, insertion.text);
    }
    file.writeAsStringSync(lines.join(eol));
    print('${_display(file.path)}: +${pending.length}');
  }

  print('');
  print('${files.length} files · ${seen.length} keys · $missing missing · $duplicates duplicate');
  if (duplicates > 0) {
    exitCode = 1;
  } else if (missing > 0 && !write) {
    print('Re-run with --write to insert them.');
    exitCode = 1;
  }
}

/// Walks the file's models/trims in source order, pairing each trim with the
/// position of its `trim:` line so a key can be inserted directly underneath.
Iterable<_Trim> _trims(dynamic doc) sync* {
  if (doc is! YamlMap) return;
  final String brand = doc['brand'].toString();
  final String type = doc['component_type'].toString();

  final dynamic models = doc['${type}s'];
  if (models is! YamlList) return;

  for (final model in models.whereType<YamlMap>()) {
    final String modelName = model['model'].toString();
    final String? modelYears = model['year_range']?.toString();

    final dynamic trims = model['trims'];
    if (trims is! YamlList) continue;

    for (final trim in trims.whereType<YamlMap>()) {
      YamlScalar? anchor;
      for (final node in trim.nodes.keys) {
        if (node is YamlScalar && node.value == 'trim') anchor = node;
      }
      if (anchor == null) continue;

      final String trimName = trim['trim'].toString();
      yield _Trim(
        model: modelName,
        trim: trimName,
        existingKey: trim['key']?.toString(),
        derivedKey: deriveKey(
          componentType: type,
          brand: brand,
          model: modelName,
          trim: trimName,
          yearRange: trim['year_range']?.toString() ?? modelYears,
        ),
        line: anchor.span.start.line,
        column: anchor.span.start.column,
      );
    }
  }
}

/// `fork-fox-36-factory-2025` — type, brand, model, trim and the generation's
/// *first* year, so extending `year_range` to a later year leaves it unchanged.
String deriveKey({
  required String componentType,
  required String brand,
  required String model,
  required String trim,
  String? yearRange,
}) {
  final String? year = yearRange == null ? null : RegExp(r'^\d{4}').firstMatch(yearRange)?.group(0);
  return <String>[
    componentType,
    brand,
    model,
    trim,
    ?year,
  ].map(_slug).where((part) => part.isNotEmpty).join('-');
}

/// Accented characters are spelled out rather than stripped — "Öhlins" has to
/// slug to `ohlins`, not `hlins`. Anything unlisted throws (see [_slug]) so a
/// new brand cannot silently lose a character from a key that is then frozen.
const Map<String, String> _transliterations = <String, String>{
  'ö': 'o', 'ø': 'o', 'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o',
  'ä': 'a', 'å': 'a', 'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a',
  'ü': 'u', 'ú': 'u', 'ù': 'u', 'û': 'u',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ñ': 'n', 'ç': 'c', 'ý': 'y',
  'æ': 'ae', 'œ': 'oe', 'ß': 'ss',
};

String _slug(String input) {
  var value = input.toLowerCase().replaceAll('+', ' plus ').replaceAll('&', ' and ');
  for (final MapEntry(key: from, value: to) in _transliterations.entries) {
    value = value.replaceAll(from, to);
  }
  for (final int rune in value.runes) {
    if (rune > 0x7F) {
      throw FormatException(
        'No transliteration for "${String.fromCharCode(rune)}" in "$input" — add one to '
        '_transliterations, because stripping it would silently corrupt a key that is then frozen.',
      );
    }
  }
  return value.replaceAll(RegExp('[^a-z0-9]+'), '-').replaceAll(RegExp('^-+|-+\$'), '');
}

String _display(String path) => path.replaceAll(r'\', '/');

class _Trim {
  final String model;
  final String trim;
  final String? existingKey;
  final String derivedKey;

  /// 0-based position of the `trim:` key in the source file.
  final int line;
  final int column;

  const _Trim({
    required this.model,
    required this.trim,
    required this.existingKey,
    required this.derivedKey,
    required this.line,
    required this.column,
  });
}

class _Insertion {
  final int line;
  final String text;

  const _Insertion(this.line, this.text);
}
