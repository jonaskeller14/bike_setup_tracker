// A test, but outside `test/`, so the analyzer does not treat it as one.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';
import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/task_forecast_service.dart';
import 'package:bike_setup_tracker/services/trash_cleanup_service.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'startup_dataset.dart';

/// Times app start against [StartupDataset] on a file database opened like
/// the app opens it. Lives outside `test/`, so CI and a plain `flutter test`
/// skip it; run it with `flutter test benchmark/startup_benchmark_test.dart`.
///
/// Covers the data layer up to the point the home page can render, not
/// widget build or plugin start-up, and runs on the host VM: compare runs on
/// the same machine, not against a phone.
const _runs = 5;

/// How long without a notification counts as settled.
const _quietPeriod = Duration(milliseconds: 300);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempDir;
  late File dbFile;
  late StartupDataset dataset;

  AppDatabase open() => AppDatabase.forTesting(NativeDatabase.createInBackground(dbFile));

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('startup_benchmark');
    dbFile = File(p.join(tempDir.path, 'bike_setup_tracker.sqlite'));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => tempDir.path,
    );

    // Each run opens and closes its own connection to the one file, in turn.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

    final stopwatch = Stopwatch()..start();
    dataset = StartupDataset.generate(today: DateTime.now());
    final database = open();
    final repository = AppRepository(database);
    await repository.initialDataLoaded;
    await dataset.seed(repository);
    await repository.disposeAndAwaitCancellation();
    await database.close();

    debugPrint('Dataset: ${dataset.counts.entries.map((e) => '${e.value} ${e.key}').join(', ')}');
    debugPrint(
      'Generated and seeded in ${_ms(stopwatch.elapsed)}, ${(dbFile.lengthSync() / 1e6).toStringAsFixed(1)} MB',
    );
  });

  tearDownAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      null,
    );
    await tempDir.delete(recursive: true);
  });

  test('app start', () async {
    final samples = [for (var i = 0; i < _runs; i++) await _measureStart(open())];

    debugPrint('\nApp start, median of $_runs (min-max), ms since the repository is created:');
    for (final phase in samples.first.keys) {
      final values = samples.map((s) => s[phase]!).toList()..sort();
      debugPrint(
        '  ${phase.padRight(28)} ${_fmt(values[values.length ~/ 2]).padLeft(7)}'
        '  (${_fmt(values.first)}-${_fmt(values.last)})',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('startup queries', () async {
    final probe = open();
    final entries = await probe.taskDao.getAllEntriesBypass();
    await probe.close();
    final snapshotEntry = entries.firstWhere((e) => e.componentId != null);

    final queries = <String, Future<Object?> Function(AppDatabase)>{
      'bikes': (db) => db.bikesDao.watchAllBikes().first,
      'components': (db) => db.componentsDao.watchAllComponentsWithData().first,
      'persons': (db) => db.personsDao.watchAllPersonsWithData().first,
      'taskRules': (db) => db.taskDao.watchAllRules().first,
      'taskEntries': (db) => db.taskDao.watchAllEntries().first,
      'setups': (db) => db.setupsDao.watchAllSetupsWithValues().first,
      'feedbacks': (db) => db.feedbackDao.watchAllFeedbacksWithChildren().first,
      'componentStats': (db) => db.stravaDao.watchComponentStats().first,
      'bikeStats': (db) => db.stravaDao.watchBikeStats().first,
      'activityBounds': (db) => db.stravaDao.watchActivityBounds().first,
      'bikeActivityRates': (db) => db.stravaDao
          .watchBikeActivityRates(
            sampleSize: TaskForecastService.sampleSize,
            maxLookback: TaskForecastService.maxLookback,
          )
          .first,
      'trash cleanup': TrashCleanupService.run,
      // A full snapshot refresh runs this once per task entry.
      'one task snapshot': (db) =>
          db.stravaDao.getComponentStatsAt(snapshotEntry.componentId!, snapshotEntry.dateTimeUTC),
    };

    debugPrint('\nStartup queries, each alone on a fresh connection, median of $_runs:');
    for (final MapEntry(key: name, value: query) in queries.entries) {
      final durations = <double>[];
      for (var i = 0; i < _runs; i++) {
        final database = open();
        // Drift reuses a live query's last result, and the first query pays
        // for opening the connection: both stay out of the number.
        await database.customSelect('SELECT 1').get();
        final stopwatch = Stopwatch()..start();
        await query(database);
        durations.add(stopwatch.elapsedMicroseconds / 1000);
        await database.close();
      }
      durations.sort();
      debugPrint('  ${name.padRight(28)} ${_fmt(durations[durations.length ~/ 2]).padLeft(7)}');
    }
    debugPrint('  (a full snapshot refresh recomputes ${entries.length} task snapshots)');
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('strava sync', () async {
    final newest = dataset.activities.last;
    final syncs = <String, List<StravaActivity>>{
      'one new activity': [
        StravaActivity(
          id: newest.id + 1,
          name: 'Ride ${newest.id + 1}',
          athlete: newest.athlete,
          sportType: newest.sportType,
          startDate: DateTime.now(),
          startDateLocal: DateTime.now(),
          gearId: newest.gearId,
          startLat: newest.startLat,
          startLon: newest.startLon,
          distance: newest.distance,
          totalElevationGain: newest.totalElevationGain,
          movingTime: newest.movingTime,
          elapsedTime: newest.elapsedTime,
        ),
      ],
      // What a relaunch delivers: every batch again, nothing changed.
      'unchanged re-delivery': dataset.activities,
    };

    final syncFile = File(p.join(tempDir.path, 'sync.sqlite'));
    debugPrint('\nStrava sync (setStravaActivities) on a settled app, median of $_runs:');
    for (final MapEntry(key: name, value: activities) in syncs.entries) {
      final durations = <double>[];
      for (var i = 0; i < _runs; i++) {
        // A copy, so every run starts from the seeded data.
        dbFile.copySync(syncFile.path);
        final database = AppDatabase.forTesting(NativeDatabase.createInBackground(syncFile));
        final repository = AppRepository(database);
        await repository.initialize();
        await repository.initialDataLoaded;
        await _settled(repository);
        final stopwatch = Stopwatch()..start();
        await repository.setStravaActivities(activities);
        durations.add(stopwatch.elapsedMicroseconds / 1000);
        await repository.disposeAndAwaitCancellation();
        await database.close();
      }
      durations.sort();
      debugPrint('  ${name.padRight(28)} ${_fmt(durations[durations.length ~/ 2]).padLeft(7)}');
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}

/// Mirrors `main()` and `LoadingGate`: the repository subscribes on
/// construction, then the gate awaits `initialize()` and the initial data.
Future<Map<String, double>> _measureStart(AppDatabase database) async {
  final stopwatch = Stopwatch()..start();
  double now() => stopwatch.elapsedMicroseconds / 1000;

  final repository = AppRepository(database);
  var notifications = 0;
  var lastNotification = 0.0;
  final statsLoaded = Completer<double>();
  void onNotify() {
    notifications++;
    lastNotification = now();
    if (!statsLoaded.isCompleted &&
        repository.componentStats.isNotEmpty &&
        repository.bikeStats.isNotEmpty &&
        repository.bikeActivityRates.isNotEmpty) {
      statsLoaded.complete(now());
    }
  }

  repository.addListener(onNotify);

  final sample = <String, double>{};
  await repository.initialize();
  sample['initialize (trash cleanup)'] = now();
  await repository.initialDataLoaded;
  sample['gate opens (UI mounts)'] = now();
  sample['stats loaded'] = await statsLoaded.future;

  final taskStatus = Stopwatch()..start();
  repository.actionableTaskRulesCount;
  repository.worstActionableTaskStatus;
  sample['task badge (computed once)'] = taskStatus.elapsedMicroseconds / 1000;

  while (now() - lastNotification < _quietPeriod.inMilliseconds) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  sample['settled (last notification)'] = lastNotification;
  sample['notifications'] = notifications.toDouble();

  repository.removeListener(onNotify);
  await repository.disposeAndAwaitCancellation();
  await database.close();
  return sample;
}

/// Completes once [repository] has gone [_quietPeriod] without a notification.
Future<void> _settled(AppRepository repository) async {
  final stopwatch = Stopwatch()..start();
  void onNotify() => stopwatch.reset();
  repository.addListener(onNotify);
  while (stopwatch.elapsed < _quietPeriod) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  repository.removeListener(onNotify);
}

String _ms(Duration duration) => '${duration.inMilliseconds} ms';

String _fmt(double value) => value.toStringAsFixed(value < 10 ? 1 : 0);
