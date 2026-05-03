import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/models/task_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateTime Consistency Tests', () {
    test('Setup constructor enforces UTC', () {
      final localTime = DateTime.now();
      expect(localTime.isUtc, isFalse);

      final setup = Setup(
        name: 'Test Setup',
        datetime: localTime,
        datetimeLocal: localTime,
        tags: {},
        bike: 'bike1',
        person: null,
        bikeAdjustmentValues: {},
        personAdjustmentValues: {},
        ratingAdjustmentValues: {},
      );

      expect(setup.datetime.isUtc, isTrue);
      expect(setup.datetime.hour, equals(localTime.toUtc().hour));
    });

    test('StravaActivity constructor enforces UTC', () {
      final localTime = DateTime.now();
      final activity = StravaActivity(
        id: 1,
        name: 'Test Activity',
        athlete: 1,
        sportType: SportType.Ride,
        startDate: localTime,
        startDateLocal: localTime,
        gearId: 'gear1',
        startLat: 0,
        startLon: 0,
        distance: 0,
        totalElevationGain: 0,
        movingTime: const Duration(seconds: 100),
        elapsedTime: const Duration(seconds: 120),
      );

      expect(activity.startDate.isUtc, isTrue);
      expect(activity.startDate.hour, equals(localTime.toUtc().hour));
    });

    test('SetupDbMapper toModel enforces UTC', () {
      final localTime = DateTime.now();
      final setupDb = SetupDb(
        id: '1',
        bikeId: 'bike1',
        isDeleted: false,
        lastModified: localTime.toUtc(), // Simulate UtcDateTimeConverter
        name: 'Test Setup',
        datetime: localTime.toUtc(), // Simulate UtcDateTimeConverter
        datetimeLocal: localTime,
        tags: {},
      );

      final model = setupDb.toModel();
      expect(model.datetime.isUtc, isTrue);
      expect(model.lastModified.isUtc, isTrue);
      // Verify no warning printed (this is harder to check in code, but we see test output)
    });

    test('InstallationDbMapper toModel enforces UTC', () {
      final installationDb = InstallationDb(
        id: '1',
        componentId: 'comp1',
        dateTimeUTC: DateTime.now().toUtc(), // Simulate UtcDateTimeConverter
        dateTimeLocal: DateTime.now(),
      );

      final model = installationDb.toModel();
      expect(model.dateTimeUTC.isUtc, isTrue);
    });

    test('TaskEntryDbMapper toModel enforces UTC', () {
      final taskEntryDb = TaskEntryDb(
        id: '1',
        isDeleted: false,
        lastModified: DateTime.now().toUtc(), // Simulate UtcDateTimeConverter
        name: 'Test',
        dateTimeUTC: DateTime.now().toUtc(), // Simulate UtcDateTimeConverter
        dateTimeLocal: DateTime.now(),
        taskRule: 'rule1',
      );

      final model = taskEntryDb.toModel();
      expect(model.dateTimeUTC.isUtc, isTrue);
      expect(model.lastModified.isUtc, isTrue);
    });

    test('TaskEntry constructor enforces UTC', () {
      final localTime = DateTime.now();
      final taskEntry = TaskEntry(
        name: 'Test',
        dateTimeUTC: localTime,
        dateTimeLocal: localTime,
        taskRule: 'rule1',
        componentId: 'comp1',
      );

      expect(taskEntry.dateTimeUTC.isUtc, isTrue);
      expect(taskEntry.lastModified.isUtc, isTrue);
    });

    test('Installation constructor enforces UTC', () {
      final localTime = DateTime.now();
      final installation = Installation(
        parent: 'parent1',
        dateTimeUTC: localTime,
        dateTimeLocal: localTime,
      );

      expect(installation.dateTimeUTC.isUtc, isTrue);
    });
  });
}
