import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_hint.dart';
import '../models/selected_data.dart';
import '../models/strava/strava_activity.dart';
import '../models/strava/strava_athlete.dart';
import '../models/strava/strava_gear.dart';
import '../repositories/app_repository.dart';
import '../services/app_hint_service.dart';
import '../utils/file_import.dart';
import 'sample_date_shift.dart';

/// Deterministic app state for store screenshots: the curated sample data,
/// moved to the current date, plus preferences that skip first-run UI.
class ScreenshotSeed {
  static const sampleDataAsset = 'assets/data/20260925_sample_simple.json';
  static const stravaDataAsset = 'assets/data/20260925_sample_simple_strava.json';

  /// Written under AppSettings' `app_settings.` key prefix.
  static const Map<String, Object> settings = {
    'showOnboarding': false,
    'themeMode': 'ThemeMode.light',
    'enableSetupTags': true,
    'enableTask': true,
    'enableTaskTags': true,
    'enableCalendar': true,
  };

  /// Merges the sample export and its Strava companion (their keys are
  /// disjoint) and shifts both by the same number of days, so activities stay
  /// aligned with the setups recorded on the same rides.
  static Map<String, dynamic> buildSeedJson({
    required String sampleJson,
    required String stravaJson,
    required DateTime today,
  }) {
    final merged = <String, dynamic>{
      ...jsonDecode(sampleJson) as Map<String, dynamic>,
      ...jsonDecode(stravaJson) as Map<String, dynamic>,
    };
    final days = sampleShiftDays(merged, today: today);
    return shiftSampleDates(merged, days) as Map<String, dynamic>;
  }

  /// Replaces all preferences with a fresh install that has finished
  /// onboarding and dismissed every hint.
  static Future<void> resetPreferences(AppHintService appHintService) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    for (final MapEntry(:key, :value) in settings.entries) {
      final prefKey = 'app_settings.$key';
      switch (value) {
        case bool():
          await preferences.setBool(prefKey, value);
        case String():
          await preferences.setString(prefKey, value);
      }
    }
    for (final hint in AppHint.values) {
      await appHintService.dismiss(hint);
    }
  }

  /// Wipes all user and Strava data and imports the shifted sample.
  static Future<void> seedDatabase(AppRepository appRepository, {required DateTime today}) async {
    final json = buildSeedJson(
      sampleJson: await rootBundle.loadString(sampleDataAsset),
      stravaJson: await rootBundle.loadString(stravaDataAsset),
      today: today,
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
