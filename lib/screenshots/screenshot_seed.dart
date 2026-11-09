import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_hint.dart';
import '../models/selected_data.dart';
import '../models/strava/strava_activity.dart';
import '../models/strava/strava_athlete.dart';
import '../models/strava/strava_gear.dart';
import '../repositories/app_repository.dart';
import '../services/app_hint_service.dart';
import '../utils/file_import.dart';
import 'demo_scenario.dart';
import 'sample_date_shift.dart';
import 'sample_localization.dart';

/// Deterministic app state for store screenshots: the curated sample data,
/// moved to the current date, plus preferences that skip first-run UI.
class ScreenshotSeed {
  static const sampleFile = '20260925_sample_simple.json';
  static const stravaFile = '20260925_sample_simple_strava.json';

  /// Where the tests read the sample files. The app doesn't bundle them: the
  /// run scripts copy these files and `sample_l10n/` into [sampleFolder] of the
  /// app's documents folder, and `lib/main_screenshots.dart` reads them there.
  static const repoDirectory = 'assets/data';
  static const sampleFolder = 'screenshot_sample';

  /// Written by the run scripts into the app's documents folder: the language
  /// code of the store locale being recorded (`de` for de-DE).
  static const localeMarkerFile = 'screenshot_locale';

  /// Written under AppSettings' `app_settings.` key prefix. Tags are off:
  /// they add noise, so only [DemoScenario.tags] shows them.
  static const Map<String, Object> settings = {
    'showOnboarding': false,
    'themeMode': 'ThemeMode.light',
    'enableSetupTags': false,
    'enableTask': true,
    'enableTaskTags': false,
    'enableCalendar': true,
  };

  /// The sample export and its Strava companion in [directory].
  static ({String sample, String strava}) readSample({String directory = repoDirectory}) => (
    sample: File('$directory/$sampleFile').readAsStringSync(),
    strava: File('$directory/$stravaFile').readAsStringSync(),
  );

  /// Merges the sample export and its Strava companion (their keys are
  /// disjoint) and shifts both by the same number of days, so activities stay
  /// aligned with the setups recorded on the same rides. The shift is taken
  /// from the whole master, so every [scenario] shares one calendar. The text is
  /// translated last, so the scenarios can rely on the English names.
  static Map<String, dynamic> buildSeedJson({
    required String sampleJson,
    required String stravaJson,
    required DateTime today,
    DemoScenario scenario = DemoScenario.full,
    SampleLocalization? localization,
  }) {
    final merged = <String, dynamic>{
      ...jsonDecode(sampleJson) as Map<String, dynamic>,
      ...jsonDecode(stravaJson) as Map<String, dynamic>,
    };
    final days = sampleShiftDays(merged, today: today);
    final seed = scenario.apply(shiftSampleDates(merged, days) as Map<String, dynamic>);
    return localization?.apply(seed) ?? seed;
  }

  /// Replaces all preferences with a fresh install that has finished
  /// onboarding and dismissed every hint. [localeCode] pins the app language;
  /// without it the app follows the device.
  static Future<void> resetPreferences(
    AppHintService appHintService, {
    DemoScenario scenario = DemoScenario.full,
    String? localeCode,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    for (final MapEntry(:key, :value) in {...settings, ...scenario.settings}.entries) {
      final prefKey = 'app_settings.$key';
      switch (value) {
        case bool():
          await preferences.setBool(prefKey, value);
        case String():
          await preferences.setString(prefKey, value);
      }
    }
    if (localeCode != null) await preferences.setString('app_settings.localeCode', localeCode);
    for (final hint in AppHint.values) {
      await appHintService.dismiss(hint);
    }
  }

  /// Wipes all user and Strava data and imports the shifted sample from
  /// [sampleDirectory], in the language of [localization] (English without one).
  static Future<void> seedDatabase(
    AppRepository appRepository, {
    required DateTime today,
    DemoScenario scenario = DemoScenario.full,
    String sampleDirectory = repoDirectory,
    SampleLocalization? localization,
  }) async {
    final files = readSample(directory: sampleDirectory);
    final json = buildSeedJson(
      sampleJson: files.sample,
      stravaJson: files.strava,
      today: today,
      scenario: scenario,
      localization: localization,
    );

    await FileImport.replace(remoteData: SelectedData.fromJson(json), database: appRepository.database);

    await appRepository.clearStravaData();
    await appRepository.setStravaAthletes(_parse(json['stravaAthletes'], StravaAthlete.fromJson));
    await appRepository.setStravaGears(_parse(json['stravaGears'], StravaGear.fromJson));
    // Recomputes task-entry snapshots from the seeded activities, as a sync would.
    await appRepository.setStravaActivities(_parse(json['stravaActivities'], StravaActivity.fromJson));
  }

  static List<T> _parse<T>(Object? list, T Function(Map<String, dynamic>) fromJson) =>
      (list as List<dynamic>).map((e) => fromJson(e as Map<String, dynamic>)).toList();
}
