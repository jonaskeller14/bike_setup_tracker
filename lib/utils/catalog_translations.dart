import 'package:yaml/yaml.dart';

/// Which catalog fields carry translations, shared by the parser, the
/// coverage test and `tool/catalog_l10n.dart`. Pure Dart, so the tool can run
/// without Flutter.
///
/// A translatable field `x` gets a sibling `x_<lang>` in the brand YAML
/// (`name_de`, `options_de`); see SCHEMA.md "Translations".

/// Languages whose catalog text must be complete. Adding catalog content always
/// includes these; any other language falls back to English at runtime.
const List<String> shippedCatalogLanguages = [];

/// Every field name that can have a translated sibling. Whether a given map
/// translates it depends on where the map sits, see [catalogStrings].
const Set<String> catalogTextKeys = {
  'name',
  'notes',
  'options',
  'description',
  'note',
  'label',
  'category',
  'source',
  'review',
  'from',
  'to',
  'missing_adjustments',
  'stanchion',
  'spring',
};

/// `name_de` → (`name`, `de`); null for any other key.
final RegExp _languageKey = RegExp(r'^(.+)_([a-z]{2})$');

({String field, String language})? splitLanguageKey(String key) {
  final match = _languageKey.firstMatch(key);
  if (match == null || !catalogTextKeys.contains(match[1])) return null;
  return (field: match[1]!, language: match[2]!);
}

/// One translatable catalog text with the translations authored next to it.
class CatalogString {
  /// Where it sits, e.g. `FOX › 36 › adjuster "HSC" › notes`.
  final String path;
  final String field;

  /// 1-based line of the English value.
  final int line;

  /// A `String`, or a `List<String>` for `options` and `missing_adjustments`.
  final Object english;

  /// By language code; absent where the sibling is missing.
  final Map<String, Object> translations;

  const CatalogString({
    required this.path,
    required this.field,
    required this.line,
    required this.english,
    required this.translations,
  });

  bool get isList => english is List<String>;

  /// The words and characters the English text holds, for `stats`.
  Iterable<String> get englishTexts => english is List<String> ? english as List<String> : [english as String];
}

/// Every translatable text of one parsed brand file, in document order.
///
/// Translated: damper `description`, `missing_adjustments`, task `name` and
/// `source` of brand-only tasks, adjuster `name`/`notes`/`options`, spec values
/// `stanchion` and `spring`, node `note` and `category`, guide `label` and rule
/// `note`, change `review` and the `from`/`to` of a `name` or `notes` fix.
/// Not translated: node `label`, damper `name`, size labels and mounts, ids,
/// `target`/`when`/`input`, units, urls, a damper's hidden `note`/`source`,
/// guide option cells.
List<CatalogString> catalogStrings(YamlMap doc) {
  final collector = _Collector(doc['brand']?.toString() ?? '?');
  collector.document(doc);
  return collector.strings;
}

class _Collector {
  final String brand;
  final List<CatalogString> strings = [];

  /// An anchored map is visited once per alias; its text is still one text.
  final Set<int> _seen = {};

  _Collector(this.brand);

  void document(YamlMap doc) {
    _optionValues(doc['option_values']);
    _guides(doc['guides']);
    _nodes(doc['nodes'], [brand]);
    _changes(doc['changes']);
  }

  void _optionValues(Object? raw) {
    if (raw is! YamlMap) return;
    for (final axis in raw.entries) {
      final values = axis.value;
      if (values is! YamlMap) continue;
      for (final entry in values.entries) {
        final value = entry.value;
        if (value is! YamlMap) continue;
        final path = [brand, '${axis.key}.${entry.key}'];
        _text(value, 'description', path);
        _owner(value, path);
      }
    }
  }

  void _guides(Object? raw) {
    if (raw is! YamlMap) return;
    for (final entry in raw.entries) {
      final guide = entry.value;
      if (guide is! YamlMap) continue;
      final path = [brand, 'guide ${entry.key}'];
      _text(guide, 'label', path);
      final rules = guide['rules'];
      if (rules is! YamlList) continue;
      for (final rule in rules) {
        if (rule is YamlMap) _text(rule, 'note', [...path, 'rule ${rule['target']}']);
      }
    }
  }

  void _nodes(Object? raw, List<String> path) {
    if (raw is! YamlList) return;
    for (final node in raw) {
      if (node is! YamlMap) continue;
      final here = [...path, node['label'].toString()];
      _text(node, 'note', here);
      _text(node, 'category', here);
      _owner(node, here);
      _nodes(node['children'], here);
    }
  }

  /// What a node and an option value have in common.
  void _owner(YamlMap map, List<String> path) {
    _text(map, 'missing_adjustments', path);
    final specs = map['specs'];
    if (specs is YamlMap) {
      _text(specs, 'stanchion', path);
      _text(specs, 'spring', path);
    }
    final adjustments = map['adjustments'];
    if (adjustments is YamlList) {
      for (final adjuster in adjustments) {
        if (adjuster is! YamlMap) continue;
        final here = [...path, 'adjuster "${adjuster['name']}"'];
        _text(adjuster, 'name', here);
        _text(adjuster, 'notes', here);
        _text(adjuster, 'options', here);
      }
    }
    final tasks = map['tasks'];
    if (tasks is YamlMap) {
      for (final entry in tasks.entries) {
        final task = entry.value;
        if (task is! YamlMap) continue;
        final here = [...path, 'task ${entry.key}'];
        // A generic task keeps its template name.
        _text(task, 'name', here);
        _text(task, 'source', here);
      }
    }
  }

  void _changes(Object? raw) {
    if (raw is! YamlList) return;
    for (final (index, change) in raw.indexed) {
      if (change is! YamlMap) continue;
      final path = [brand, 'change ${index + 1}'];
      _text(change, 'review', path);
      final fix = change['fix'];
      if (fix is YamlMap && (fix['field'] == 'name' || fix['field'] == 'notes')) {
        _text(fix, 'from', path);
        _text(fix, 'to', path);
      }
    }
  }

  void _text(YamlMap map, String field, List<String> path) {
    final node = map.nodes[field];
    if (node == null || node.value == null) return;
    final english = _read(node.value);
    if (english == null || !_seen.add(node.span.start.offset)) return;
    final translations = <String, Object>{};
    for (final entry in map.entries) {
      final split = splitLanguageKey(entry.key.toString());
      if (split == null || split.field != field) continue;
      final value = _read(entry.value);
      if (value != null) translations[split.language] = value;
    }
    strings.add(
      CatalogString(
        path: path.join(' › '),
        field: field,
        line: node.span.start.line + 1,
        english: english,
        translations: translations,
      ),
    );
  }

  static Object? _read(Object? value) => switch (value) {
    YamlList() => [for (final item in value) item.toString()],
    null => null,
    _ => value.toString(),
  };
}
