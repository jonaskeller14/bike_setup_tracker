import 'dart:convert';
import 'dart:io';

typedef _Json = Map<String, dynamic>;

class SampleLocalization {
  /// [unchanged] is added to [translations] as text that maps to itself.
  SampleLocalization(Map<String, String> translations, {Iterable<String> unchanged = const []})
    : translations = {for (final text in unchanged) text: text, ...translations};

  factory SampleLocalization.parse(String translationsJson, String unchangedJson) => SampleLocalization(
    (jsonDecode(translationsJson) as Map<String, dynamic>).cast<String, String>(),
    unchanged: (jsonDecode(unchangedJson) as List<dynamic>).cast<String>(),
  );

  static const folder = 'sample_l10n';
  static const unchangedName = 'same';

  /// The file of the dictionary [name] (a language code or [unchangedName]) in the sample [directory].
  static String path(String directory, String name) => '$directory/$folder/$name.json';

  final Map<String, String> translations;

  /// The dictionary of [languageCode] from the sample [directory], or `null`
  /// for English. A language without a dictionary throws, so a typo can't
  /// record English by accident.
  static Future<SampleLocalization?> load(String? languageCode, {required String directory}) async {
    if (languageCode == null || languageCode == 'en') return null;
    return SampleLocalization.parse(
      await File(path(directory, languageCode)).readAsString(),
      await File(path(directory, unchangedName)).readAsString(),
    );
  }

  /// Returns a copy of [json] with the text translated.
  Map<String, dynamic> apply(Map<String, dynamic> json) => _translate(json, (text) => translations[text] ?? text);

  /// Every text of [json] that [apply] would look up.
  static Set<String> textsIn(Map<String, dynamic> json) {
    final texts = <String>{};
    _translate(json, (text) {
      if (text.isNotEmpty) texts.add(text);
      return text;
    });
    return texts;
  }

  static _Json _translate(_Json json, String Function(String text) t) {
    Object? text(Object? value) => value is String ? t(value) : value;

    _Json texts(_Json item, Set<String> keys) => {
      for (final MapEntry(:key, :value) in item.entries) key: keys.contains(key) ? text(value) : value,
    };

    List<Object?> strings(Object? list) => [for (final item in list as List<dynamic>) text(item)];

    _Json adjustment(_Json item) => {
      ...texts(item, const {'name', 'notes'}),
      if (item['options'] != null) 'options': strings(item['options']),
    };

    _Json owner(_Json item, Set<String> keys) => {
      ...texts(item, keys),
      if (item['adjustments'] case final List<dynamic> adjustments)
        'adjustments': [for (final a in adjustments.cast<_Json>()) adjustment(a)],
    };

    _Json values(Object? map) => (map as _Json).map((key, value) => MapEntry(key, text(value)));

    _Json setup(_Json item) => {
      ...texts(item, const {'name', 'notes'}),
      'tags': strings(item['tags']),
      'bikeAdjustmentValues': values(item['bikeAdjustmentValues']),
      'personAdjustmentValues': values(item['personAdjustmentValues']),
    };

    _Json rule(_Json item) => {
      ...texts(item, const {'name', 'notes'}),
      'tags': strings(item['tags']),
    };

    _Json section(String key, _Json Function(_Json item) translate) => {
      if (json[key] case final List<dynamic> items) key: [for (final item in items.cast<_Json>()) translate(item)],
    };

    return {
      ...json,
      ...section('bikes', (bike) => texts(bike, const {'notes'})),
      ...section('persons', (person) => owner(person, const {'notes'})),
      ...section('components', (component) => owner(component, const {'name', 'notes'})),
      ...section('setups', setup),
      ...section('taskRules', rule),
      ...section('taskEntries', (entry) => texts(entry, const {'name', 'notes'})),
      ...section('stravaActivities', (activity) => texts(activity, const {'name'})),
    };
  }
}
