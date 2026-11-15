import 'dart:convert';
import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/screenshots/demo_scenario.dart';
import 'package:bike_setup_tracker/screenshots/sample_localization.dart';
import 'package:bike_setup_tracker/screenshots/screenshot_seed.dart';
import 'package:flutter_test/flutter_test.dart';

/// The digits of [text] without their separators, so `1.55`, `1,55` and a
/// French `2 000` match their English `1.55` and `2,000`.
List<String> _numbers(String text) =>
    RegExp(r'\d+(?:[.,]\d+)*')
        .allMatches(text.replaceAllMapped(RegExp(r'(\d) (?=\d{3})'), (m) => m[1]!))
        .map((m) => m[0]!.replaceAll(RegExp(r'[.,]'), ''))
        .toList()
      ..sort();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime(2026, 9, 26);
  final sample = ScreenshotSeed.readSample();

  Map<String, dynamic> seedJson(DemoScenario scenario, {SampleLocalization? localization}) =>
      ScreenshotSeed.buildSeedJson(
        sampleJson: sample.sample,
        stravaJson: sample.strava,
        today: today,
        scenario: scenario,
        localization: localization,
      );

  String read(String name) => File(SampleLocalization.path(ScreenshotSeed.repoDirectory, name)).readAsStringSync();

  SampleLocalization dictionary(String language) =>
      SampleLocalization.parse(read(language), read(SampleLocalization.unchangedName));

  // The scenarios add text of their own, so every one of them counts.
  final texts = {for (final scenario in DemoScenario.values) ...SampleLocalization.textsIn(seedJson(scenario))};

  for (final language in const ['de', 'es', 'fr', 'it', 'pt']) {
    group(language, () {
      final localization = dictionary(language);
      final known = localization.translations.keys.toSet();

      test('translates every text of every scenario', () {
        expect(texts.difference(known), isEmpty);
      });

      test('has no entry that the sample no longer uses', () {
        expect(known.difference(texts), isEmpty);
      });

      test('keeps the numbers of every text', () {
        for (final MapEntry(:key, :value) in localization.translations.entries) {
          expect(_numbers(value), _numbers(key), reason: key);
        }
      });

      test('keeps the selected values among the options of their adjustment', () {
        final json = seedJson(DemoScenario.full, localization: localization);
        final options = {
          for (final component in (json['components'] as List).cast<Map<String, dynamic>>())
            for (final adjustment in (component['adjustments'] as List).cast<Map<String, dynamic>>())
              if (adjustment['options'] != null)
                adjustment['id'] as String: (adjustment['options'] as List).cast<String>(),
        };
        for (final setup in (json['setups'] as List).cast<Map<String, dynamic>>()) {
          for (final MapEntry(:key, :value) in (setup['bikeAdjustmentValues'] as Map<String, dynamic>).entries) {
            if (options[key] case final allowed?) expect(allowed, contains(value), reason: '${setup['name']}: $key');
          }
        }
      });
    });
  }

  test('translating leaves ids, numbers and dates as they are', () {
    final english = seedJson(DemoScenario.full);
    expect(jsonEncode(SampleLocalization({}).apply(english)), jsonEncode(english));

    final german = seedJson(DemoScenario.full, localization: dictionary('de'));
    expect(
      (german['setups'] as List).map((s) => (s as Map)['id']),
      (english['setups'] as List).map((s) => (s as Map)['id']),
    );
    expect(
      (german['stravaActivities'] as List).map((a) => (a as Map)['startDate']),
      (english['stravaActivities'] as List).map((a) => (a as Map)['startDate']),
    );
  });

  test('English and an unknown language fall back to the sample', () async {
    const directory = ScreenshotSeed.repoDirectory;
    expect(await SampleLocalization.load(null, directory: directory), isNull);
    expect(await SampleLocalization.load('en', directory: directory), isNull);
    await expectLater(SampleLocalization.load('xx', directory: directory), throwsA(anything));
    expect(await SampleLocalization.load('de', directory: directory), isNotNull);
  });

  test('seeds the database in the language of the dictionary', () async {
    final database = AppDatabase.memory();
    final repository = AppRepository(database);
    await ScreenshotSeed.seedDatabase(repository, today: today, localization: dictionary('de'));
    await repository.initialDataLoaded;

    expect(repository.setups.values.map((s) => s.name), contains('Saisonauftakt'));
    expect(repository.bikes.values.map((b) => b.name), contains('Santa Cruz Hightower'));
    expect(repository.taskRules.values.map((r) => r.name), contains('Kette wechseln'));

    await repository.disposeAndAwaitCancellation();
    await database.close();
  });
}
