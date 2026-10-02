/// Converts the flat brand files of `data/component_presets/` into the
/// node/option schema of `data/component_catalog/` (#25).
///
/// A one-off for the schema switch: it goes away together with the old catalog.
/// `test/component_catalog_equivalence_test.dart` checks the output against the
/// source files.
///
///     dart run tool/convert_preset_catalog.dart            # skip files that exist
///     dart run tool/convert_preset_catalog.dart --force    # overwrite them
///
/// Works on source lines instead of re-serializing the YAML, so `#` comments,
/// anchors/aliases and the Follow-ups footers survive. Comments are carried
/// over as written, so the ones describing the old shape need a hand pass.
library;

// A maintenance CLI: stdout is its output channel.
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:yaml/yaml.dart';

const String _sourceDir = 'data/component_presets';
const String _targetDir = 'data/component_catalog';
const List<String> _componentTypes = <String>['fork'];

const String _leafLevel = 'trim';

/// Brands whose model names carry a level of their own.
final Map<String, _ModelSplit> _modelSplits = <String, _ModelSplit>{
  // "RXF36 m.3" is the m.3 version of the RXF36.
  'Öhlins': _ModelSplit(RegExp(r'^(.+) (m\.\d+)$'), level: 'version', id: (label) => label.replaceAll('.', '')),
};

void main(List<String> args) {
  final bool force = args.contains('--force');

  if (!Directory(_sourceDir).existsSync()) {
    stderr.writeln('Run this from the repository root — "$_sourceDir" not found.');
    exitCode = 1;
    return;
  }

  for (final type in _componentTypes) {
    final List<File> files =
        Directory('$_sourceDir/$type').listSync().whereType<File>().where((f) => f.path.endsWith('.yaml')).toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final String name = '$type/${file.uri.pathSegments.last}';
      final File target = File('$_targetDir/$name');
      if (target.existsSync() && !force) {
        print('$name: skipped, already converted');
        continue;
      }

      final String source = file.readAsStringSync();
      final String eol = source.contains('\r\n') ? '\r\n' : '\n';
      final String converted = _convert(source.split(eol)).join(eol);
      loadYaml(converted);

      target.createSync(recursive: true);
      target.writeAsStringSync(converted);
      print('$name: converted');
    }
  }
}

List<String> _convert(List<String> lines) {
  final int dampersAt = lines.indexOf('dampers:');
  final int modelsAt = lines.indexWhere(RegExp(r'^(forks|shocks):\s*$').hasMatch);
  if (dampersAt < 0 || modelsAt < dampersAt) {
    throw const FormatException('Expected "dampers:" followed by "forks:" or "shocks:"');
  }
  final String brand = lines.map(RegExp(r'^brand:\s*(.+)$').firstMatch).nonNulls.first.group(1)!.trim();

  // The banner right above the models key introduces the models, not the last damper.
  var dampersEnd = modelsAt;
  while (dampersEnd > dampersAt + 1 && (lines[dampersEnd - 1].isEmpty || lines[dampersEnd - 1].startsWith('#'))) {
    dampersEnd--;
  }

  final List<String> converted = <String>[
    ...lines.sublist(0, dampersAt),
    'option_values:',
    '  damper:',
    for (final line in lines.sublist(dampersAt + 1, dampersEnd)) line.startsWith(' ') ? '  $line' : line,
    ...lines.sublist(dampersEnd, modelsAt),
    'nodes:',
    ..._convertModels(lines.sublist(modelsAt + 1), _modelSplits[brand]),
  ];
  return <String>[
    for (final line in _hoistAnchors(converted))
      _isComment(line) ? line.replaceAll('`complete: false`', '`draft: true`') : line,
  ];
}

/// Merging same-named blocks moves them, which can put an alias above its
/// anchor. The definition then moves to that first use.
List<String> _hoistAnchors(List<String> source) {
  final List<String> lines = List<String>.of(source);
  final Set<String> seen = <String>{};

  for (var at = 0; at < lines.length; at++) {
    final String? name = _isComment(lines[at]) ? null : RegExp(r'\*([a-z0-9_]+)\s*$').firstMatch(lines[at])?.group(1);
    if (name == null || !seen.add(name)) continue;

    final int definedAt = lines.indexWhere((line) => !_isComment(line) && RegExp('&$name\\b').hasMatch(line), at);
    if (definedAt < 0) continue;

    final String definition = lines[definedAt];
    final RegExpMatch? inline = RegExp('&$name \\{.*\\}').firstMatch(definition);
    if (inline != null) {
      // `- &name { … }`
      lines[definedAt] = definition.replaceFirst(inline.group(0)!, '*$name');
      lines[at] = lines[at].replaceFirst('*$name', inline.group(0)!);
      continue;
    }

    // `key: &name` with the list hanging below it.
    var end = definedAt + 1;
    while (end < lines.length && lines[end].trim().isNotEmpty && _indentOf(lines[end]) > _indentOf(definition)) {
      end++;
    }
    final List<String> body = lines.sublist(definedAt + 1, end);
    lines
      ..[definedAt] = definition.replaceFirst('&$name', '*$name')
      ..removeRange(definedAt + 1, end)
      ..insertAll(at + 1, _reindent(body, _indentOf(definition), _indentOf(lines[at])));
    lines[at] = lines[at].replaceFirst('*$name', '&$name');
  }
  return lines;
}

List<String> _convertModels(List<String> lines, _ModelSplit? split) {
  final (:items, :trailing) = _splitItems(lines, 2, 'model');

  // Same-named blocks become one model node, at the position of the first.
  final Map<String, List<_Block>> groups = <String, List<_Block>>{};
  for (final item in items) {
    final _Block block = _Block(item, split);
    groups.putIfAbsent(block.model, () => <_Block>[]).add(block);
  }

  return <String>[
    for (final blocks in groups.values) ..._emitModel(blocks),
    // What follows the last model is the Follow-ups footer.
    ...trailing,
  ];
}

List<String> _emitModel(List<_Block> blocks) {
  final _Block first = blocks.first;

  if (blocks.length == 1 && first.splitLabel == null) {
    return _emitBlock(
      first,
      column: 4,
      leading: first.item.leading,
      label: first.item.label,
      level: 'model',
      withCategory: true,
    );
  }

  final bool sharedCategory = blocks.map((block) => block.item['category']?.value).toSet().length == 1;
  final _Entry? category = sharedCategory ? first.item['category'] : null;
  final List<String> model = <String>[
    ...first.item.leading,
    '  - label: ${first.splitLabel == null ? first.item.label : _quoteIfNeeded(first.model)}',
    '    level: model',
    if (category != null) ..._emit(category, 4),
    '    children:',
  ];

  if (first.splitLabel != null) {
    return <String>[
      ...model,
      for (final block in blocks)
        ..._emitBlock(
          block,
          column: 8,
          leading: block == first ? const <String>[] : _comments(block.item.leading, 6),
          label: _quoteIfNeeded(block.splitLabel!),
          level: block.split!.level,
          id: block.split!.id(block.splitLabel!),
          withCategory: !sharedCategory,
        ),
    ];
  }

  // A trim name that comes back in another block is what makes the blocks
  // generations. Otherwise the model was only split to give each trim its own
  // years, and the trims can sit side by side.
  final List<String> trimNames = <String>[
    for (final block in blocks)
      for (final trim in block.trims) trim.label,
  ];
  if (trimNames.toSet().length == trimNames.length) {
    return <String>[
      ...model,
      for (final block in blocks)
        for (final trim in block.trims)
          ..._emitTrim(
            trim,
            block,
            column: 8,
            leading: <String>[
              if (trim == block.trims.first && block != first) ..._comments(block.item.leading, 6),
              ..._comments(trim.leading, 6),
            ],
            inheritBlock: true,
          ),
    ];
  }

  if (!sharedCategory) {
    throw FormatException('Generations of "${first.model}" disagree on category');
  }
  return <String>[
    ...model,
    for (final block in blocks)
      ..._emitBlock(
        block,
        column: 8,
        leading: block == first ? const <String>[] : _comments(block.item.leading, 6),
        label: '"${block.years.replaceAll('-', '–')}"',
        level: 'generation',
        id: block.firstYear,
      ),
  ];
}

/// A node that carries the fields of one old model block, with its trims as
/// children. [column] is where its keys start.
List<String> _emitBlock(
  _Block block, {
  required int column,
  required List<String> leading,
  required String label,
  required String level,
  String? id,
  bool withCategory = false,
}) {
  final _Item item = block.item;
  final String pad = ' ' * column;
  return <String>[
    ...leading,
    '${' ' * (column - 2)}- label: $label',
    '${pad}level: $level',
    if (id != null && id != label.replaceAll('"', '')) '${pad}id: ${_quoteIfNeeded(id)}',
    if (block.draft) ...<String>[..._comments(item['complete']!.leading, column), '${pad}draft: true'],
    if (withCategory) ..._emitIfPresent(item['category'], column),
    ..._emitIfPresent(item['year_range'], column, as: 'years'),
    ..._emitIfPresent(item['url'], column),
    for (final entry in item.entries)
      if (!_blockKeys.contains(entry.key)) ..._emit(entry, column),
    ..._emitIfPresent(item['note'], column),
    // Its value moves into every trim's options; what was written above it stays.
    ..._comments(item['wheel_size']?.leading ?? const <String>[], column),
    '${pad}children:',
    for (final trim in block.trims)
      ..._emitTrim(trim, block, column: column + 4, leading: _comments(trim.leading, column + 2)),
    ..._comments(block.trailing, column + 2),
  ];
}

/// A leaf node. With [inheritBlock] it also takes over the block-level fields,
/// because no node is left between it and the model.
List<String> _emitTrim(
  _Item trim,
  _Block block, {
  required int column,
  required List<String> leading,
  bool inheritBlock = false,
}) {
  final String pad = ' ' * column;
  final _Item item = block.item;

  final List<_Entry> specs = trim.entries.where((entry) => _specKeys.contains(entry.key)).toList();
  final Map<String, _Entry> axes = <String, _Entry>{
    for (final MapEntry(key: axis, value: entry) in <String, _Entry?>{
      'damper': trim['dampers'],
      'travel_mm': trim['travel_mm'],
      'wheel_size': item['wheel_size'],
    }.entries)
      if (entry != null && _splitComment(entry.value).value != '[]') axis: entry,
  };

  return <String>[
    ...leading,
    '${' ' * (column - 2)}- label: ${trim.label}',
    '${pad}level: $_leafLevel',
    if (inheritBlock && block.draft) '${pad}draft: true',
    ..._emitIfPresent(trim['year_range'] ?? (inheritBlock ? item['year_range'] : null), column, as: 'years'),
    ..._emitIfPresent(trim['url'] ?? (inheritBlock ? item['url'] : null), column),
    if (specs.isNotEmpty) ..._emitSpecs(specs, column),
    for (final entry in <_Entry>[
      if (inheritBlock) ...item.entries.where((e) => !_blockKeys.contains(e.key)),
      ...trim.entries.where((e) => !_trimKeys.contains(e.key)),
    ])
      ..._emit(entry, column),
    ..._emitIfPresent(trim['adjustments'], column),
    if (axes.isNotEmpty) '${pad}options:',
    for (final MapEntry(key: axis, value: entry) in axes.entries) ...<String>[
      // A block-level entry is shared by every trim; its comments stay on the block.
      if (trim.entries.contains(entry)) ..._comments(entry.leading, column + 2),
      '$pad  $axis: ${entry.value}',
      ..._reindent(entry.continuation, entry.column, column + 2),
    ],
    ..._emitIfPresent(trim['note'] ?? (inheritBlock ? item['note'] : null), column),
  ];
}

List<String> _emitSpecs(List<_Entry> specs, int column) {
  final List<String> comments = <String>[];
  final List<String> pairs = <String>[];
  for (final spec in specs) {
    if (spec.continuation.isNotEmpty) {
      throw FormatException('Spec "${spec.key}" spans several lines: ${spec.value}');
    }
    final (:value, :comment) = _splitComment(spec.value);
    pairs.add('${spec.key}: ${_flowScalar(value)}');
    if (comment.isNotEmpty) comments.add(comment.substring(1).trim());
  }
  return <String>[
    for (final spec in specs) ..._comments(spec.leading, column),
    '${' ' * column}specs: { ${pairs.join(', ')} }${comments.isEmpty ? '' : '   # ${comments.join('; ')}'}',
  ];
}

List<String> _emitIfPresent(_Entry? entry, int column, {String? as}) =>
    entry == null ? const <String>[] : _emit(entry, column, as: as);

List<String> _emit(_Entry entry, int column, {String? as}) => <String>[
  ..._comments(entry.leading, column),
  '${' ' * column}${as ?? entry.key}:${entry.value.isEmpty ? '' : ' ${entry.value}'}',
  ..._reindent(entry.continuation, entry.column, column),
];

/// The comment lines of [lines], moved to [column]. Blank lines only separated
/// the old blocks.
List<String> _comments(List<String> lines, int column) => <String>[
  for (final line in lines)
    if (line.trim().isNotEmpty) '${' ' * column}${line.trimLeft()}',
];

/// Shifts lines that hung below a key at column [from] to hang below [to].
List<String> _reindent(List<String> lines, int from, int to) => <String>[
  for (final line in lines)
    if (line.trim().isEmpty) '' else '${' ' * (_indentOf(line) - from + to)}${line.trimLeft()}',
];

/// Splits a list whose items start with `- <firstKey>:` at [indent]. Comments
/// between two items belong to the one that follows.
({List<_Item> items, List<String> trailing}) _splitItems(List<String> lines, int indent, String firstKey) {
  final String start = '${' ' * indent}- $firstKey:';
  final List<_Item> items = <_Item>[];
  var leading = <String>[];
  List<String>? current;

  void close() {
    if (current == null) return;
    final (:entries, :trailing) = _parseEntries(current, indent + 2);
    items.add(_Item(leading, entries));
    leading = trailing;
  }

  for (final line in lines) {
    if (line.startsWith(start)) {
      close();
      current = <String>['${' ' * (indent + 2)}${line.substring(indent + 2)}'];
    } else if (current != null) {
      current.add(line);
    } else if (_isTrivia(line)) {
      leading.add(line);
    } else {
      throw FormatException('Unexpected line before the first "$firstKey": $line');
    }
  }
  close();
  return (items: items, trailing: leading);
}

/// Reads the `key: value` entries at [column]. Deeper lines hang below the
/// entry above them; comments at or left of [column] lead the next entry.
({List<_Entry> entries, List<String> trailing}) _parseEntries(List<String> lines, int column) {
  final RegExp keyPattern = RegExp('^ {$column}([a-z_]+):(.*)\$');
  final List<_Entry> entries = <_Entry>[];
  var pending = <String>[];

  for (final line in lines) {
    final RegExpMatch? match = keyPattern.firstMatch(line);
    if (match != null) {
      entries.add(_Entry(match.group(1)!, match.group(2)!.trim(), column, pending));
      pending = <String>[];
    } else if (line.trim().isEmpty || (_isComment(line) && _indentOf(line) <= column)) {
      pending.add(line);
    } else if (_indentOf(line) <= column || entries.isEmpty) {
      throw FormatException('Cannot place this line: $line');
    } else {
      entries.last.continuation
        ..addAll(pending)
        ..add(line);
      pending = <String>[];
    }
  }
  return (entries: entries, trailing: pending);
}

/// Splits `[150, 160]   # note` into the value and its trailing comment.
({String value, String comment}) _splitComment(String text) {
  String? quote;
  for (var i = 0; i < text.length; i++) {
    final String char = text[i];
    if (quote != null) {
      if (char == quote) quote = null;
    } else if (char == '"' || char == "'") {
      quote = char;
    } else if (char == '#' && (i == 0 || text[i - 1] == ' ')) {
      return (value: text.substring(0, i).trimRight(), comment: text.substring(i));
    }
  }
  return (value: text, comment: '');
}

/// A block-style scalar as it has to be written inside `{ … }`.
String _flowScalar(String value) {
  if (value.startsWith('"') || value.startsWith("'")) return value;
  if (!RegExp(r'[,\[\]{}]|: | #').hasMatch(value)) return value;
  return '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
}

String _unquote(String value) {
  final bool quoted = value.length >= 2 && (value.startsWith('"') || value.startsWith("'")) && value.endsWith(value[0]);
  return quoted ? value.substring(1, value.length - 1) : value;
}

/// Keeps `36` and `2025` strings, the way the old files quoted them.
String _quoteIfNeeded(String value) => num.tryParse(value) == null ? value : '"$value"';

bool _isComment(String line) => line.trimLeft().startsWith('#');

bool _isTrivia(String line) => line.trim().isEmpty || _isComment(line);

int _indentOf(String line) => line.length - line.trimLeft().length;

/// Block-level keys that are placed by name. Anything else is freeform and
/// carried over as written.
const Set<String> _blockKeys = <String>{
  'model',
  'complete',
  'category',
  'year_range',
  'url',
  'wheel_size',
  'trims',
  'note',
};

const Set<String> _trimKeys = <String>{
  'trim',
  'key',
  'year_range',
  'url',
  'travel_mm',
  'dampers',
  'adjustments',
  'note',
  ..._specKeys,
};

const Set<String> _specKeys = <String>{'stanchion', 'spring'};

class _ModelSplit {
  final RegExp pattern;
  final String level;
  final String Function(String label) id;

  const _ModelSplit(this.pattern, {required this.level, required this.id});
}

class _Entry {
  final String key;

  /// Everything after `key:` on its line, a trailing comment included.
  final String value;
  final int column;
  final List<String> leading;
  final List<String> continuation = <String>[];

  _Entry(this.key, this.value, this.column, this.leading);
}

class _Item {
  final List<String> leading;
  final List<_Entry> entries;

  const _Item(this.leading, this.entries);

  _Entry? operator [](String key) {
    for (final entry in entries) {
      if (entry.key == key) return entry;
    }
    return null;
  }

  /// The value of the item's first key, as written.
  String get label => entries.first.value;
}

/// One `- model:` block of an old file.
class _Block {
  final _Item item;
  final _ModelSplit? split;
  final List<_Item> trims;

  /// Comments after the last trim.
  final List<String> trailing;

  /// The name same-named blocks are merged under.
  final String model;

  /// The part of the old model name that becomes a level of its own.
  final String? splitLabel;

  _Block._(this.item, this.split, this.trims, this.trailing, this.model, this.splitLabel);

  factory _Block(_Item item, _ModelSplit? split) {
    final _Entry? trims = item['trims'];
    if (trims == null) throw FormatException('Model ${item.label} has no trims');
    final (:items, :trailing) = _splitItems(trims.continuation, trims.column + 2, 'trim');

    final String name = _unquote(_splitComment(item.label).value);
    final RegExpMatch? match = split?.pattern.firstMatch(name);
    return _Block._(item, match == null ? null : split, items, trailing, match?.group(1) ?? name, match?.group(2));
  }

  bool get draft => _splitComment(item['complete']?.value ?? 'true').value == 'false';

  String get years {
    final _Entry? entry = item['year_range'];
    if (entry == null) throw FormatException('A generation of "$model" has no year_range');
    return _unquote(_splitComment(entry.value).value);
  }

  String get firstYear => RegExp(r'^\d{4}').firstMatch(years)!.group(0)!;
}
