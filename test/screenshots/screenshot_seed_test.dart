import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_hint.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/screenshots/screenshot_seed.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime(2026, 9, 26);

  group('buildSeedJson', () {
    late Map<String, dynamic> json;

    setUp(() {
      json = ScreenshotSeed.buildSeedJson(
        sampleJson: File(ScreenshotSeed.sampleDataAsset).readAsStringSync(),
        stravaJson: File(ScreenshotSeed.stravaDataAsset).readAsStringSync(),
        today: today,
      );
    });

    test('contains the sample and its Strava companion', () {
      expect(json['bikes'], hasLength(5));
      expect(json['setups'], hasLength(25));
      expect(json['stravaAthletes'], hasLength(1));
      expect(json['stravaGears'], hasLength(5));
      expect(json['stravaActivities'], hasLength(16));
    });

    test('every Strava gear belongs to a sample bike', () {
      final bikeGears = (json['bikes'] as List).map((b) => (b as Map)['stravaGear']).toSet();
      final gears = (json['stravaGears'] as List).map((g) => (g as Map)['id']).toSet();
      final activityGears = (json['stravaActivities'] as List).map((a) => (a as Map)['gearId']).toSet();

      expect(gears, bikeGears);
      expect(gears, containsAll(activityGears));
    });

    test('shifts activities together with the setups of the same ride', () {
      final setup = (json['setups'] as List).cast<Map<String, dynamic>>().firstWhere(
        (s) => s['name'] == 'Hometrails - Season Opener',
      );
      final activity = (json['stravaActivities'] as List).cast<Map<String, dynamic>>().firstWhere(
        (a) => a['name'] == 'Hometrails - Season Opener',
      );

      final setupTime = DateTime.parse(setup['datetime'] as String);
      final activityTime = DateTime.parse(activity['startDate'] as String);
      expect(activityTime.difference(setupTime), const Duration(minutes: 10));
    });
  });

  group('seedDatabase', () {
    late AppDatabase database;
    late AppRepository repository;

    setUp(() {
      database = AppDatabase.memory();
      repository = AppRepository(database);
    });

    tearDown(() async {
      await repository.disposeAndAwaitCancellation();
      await database.close();
    });

    test('imports the shifted sample and Strava data', () async {
      await ScreenshotSeed.seedDatabase(repository, today: today);
      await repository.initialDataLoaded;

      expect(await database.bikesDao.getAllBikesBypass(), hasLength(5));
      expect(await database.stravaDao.getAllActivitiesBypass(), hasLength(16));

      final newest = repository.setups.values.map((s) => s.datetime).reduce((a, b) => a.isAfter(b) ? a : b);
      expect(newest.isBefore(today), isTrue);
      expect(today.difference(newest).inDays, lessThan(30));
    });

    test('has a due distance-based task for screen 06', () async {
      await ScreenshotSeed.seedDatabase(repository, today: today);
      await repository.initialDataLoaded;

      final boltCheck = repository.actionableTaskRules.singleWhere((t) => t.rule.name == 'Bolt torque check');
      expect(boltCheck.rule.interval, isA<DistanceThreshold>());
      expect(boltCheck.status.type, TaskStatusType.due);
    });

    test('replaces data from a previous run', () async {
      await ScreenshotSeed.seedDatabase(repository, today: today);
      await ScreenshotSeed.seedDatabase(repository, today: today.add(const Duration(days: 7)));

      expect(await database.bikesDao.getAllBikesBypass(), hasLength(5));
      expect(await database.stravaDao.getAllActivitiesBypass(), hasLength(16));
    });
  });

  group('resetPreferences', () {
    late AppDatabase database;
    late AppRepository repository;
    late AppSettings settings;
    late AppHintService hintService;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'app_settings.showOnboarding': true,
        'app_settings.distanceUnit': 'mi',
      });
      database = AppDatabase.memory();
      repository = AppRepository(database);
      settings = AppSettings();
      hintService = AppHintService(appRepository: repository, appSettings: settings);
    });

    tearDown(() async {
      hintService.dispose();
      settings.dispose();
      await repository.disposeAndAwaitCancellation();
      await database.close();
    });

    test('loads as a finished-onboarding install with the screenshot features', () async {
      await ScreenshotSeed.resetPreferences(hintService);

      final loaded = AppSettings();
      await loaded.loadAppSettings();

      expect(loaded.showOnboarding, isFalse);
      expect(loaded.themeMode, ThemeMode.light);
      expect(loaded.distanceUnit, 'km');
      expect(loaded.enablePerson, isFalse);
      expect(loaded.enableRating, isFalse);
      expect(loaded.enableTask, isTrue);
      expect(loaded.enableCalendar, isTrue);
      loaded.dispose();
    });

    test('dismisses every hint', () async {
      await ScreenshotSeed.resetPreferences(hintService);

      final reloaded = AppHintService(appRepository: repository, appSettings: settings);
      await reloaded.load();

      for (final hint in AppHint.values) {
        expect(reloaded.statusOf(hint), AppHintStatus.dismissed, reason: hint.name);
      }
      reloaded.dispose();
    });
  });
}
