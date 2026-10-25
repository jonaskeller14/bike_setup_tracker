import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component_stats.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter_test/flutter_test.dart';

/// Allow Drift streams to propagate through subscriptions.
Future<void> pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

/// A snapshot no refresh would compute: an entry still holding it was not refreshed.
const _marker = ComponentStats(
  distance: 999000.0,
  elevationGain: 0,
  movingTime: Duration.zero,
  elapsedTime: Duration.zero,
  activityCount: 99,
);

StravaActivity _ride(
  int id,
  DateTime startDate, {
  DateTime? lastModified,
  Duration elapsedTime = const Duration(hours: 1),
}) => StravaActivity(
  id: id,
  lastModified: lastModified ?? DateTime.utc(2024, 2, 1),
  name: 'Ride $id',
  athlete: 1,
  sportType: SportType.Ride,
  startDate: startDate,
  startDateLocal: startDate.copyWith(isUtc: false),
  gearId: 'g1',
  startLat: null,
  startLon: null,
  distance: 10000.0,
  totalElevationGain: 100.0,
  movingTime: const Duration(hours: 1),
  elapsedTime: elapsedTime,
);

void main() {
  group('setStravaActivities — refreshes only the snapshots a sync can change', () {
    late AppDatabase database;
    late AppRepository repository;
    late Bike bike;
    late TaskEntry earlier;
    late TaskEntry later;

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      bike = Bike(name: 'Test Bike', person: null, stravaGear: 'g1');
      await repository.addBikes([bike]);
      await pumpEventQueue();
    });

    tearDown(() async {
      await database.close();
    });

    // Written straight to the DAO so they keep the marker snapshot.
    Future<void> insertEntries() async {
      TaskEntry entry(DateTime date) => TaskEntry(
        name: 'Serviced',
        taskRule: 'rule',
        association: BikeTaskAssociation(bike.id),
        dateTimeUTC: date,
        dateTimeLocal: date,
        snapshot: _marker,
      );
      earlier = entry(DateTime.utc(2024, 1, 10));
      later = entry(DateTime.utc(2024, 1, 20));
      await database.taskDao.insertEntry(earlier.toCompanion());
      await database.taskDao.insertEntry(later.toCompanion());
    }

    Future<double?> distanceOf(TaskEntry entry) async {
      final rows = await database.taskDao.getAllEntriesBypass();
      return rows.firstWhere((row) => row.id == entry.id).toModel().snapshot?.distance;
    }

    test('an activity after every entry refreshes no snapshot', () async {
      await insertEntries();

      await repository.setStravaActivities([_ride(1, DateTime.utc(2024, 1, 25))]);

      expect(await distanceOf(earlier), _marker.distance);
      expect(await distanceOf(later), _marker.distance);
    });

    test('a back-dated activity refreshes only the entries after it', () async {
      await insertEntries();

      await repository.setStravaActivities([_ride(1, DateTime.utc(2024, 1, 15))]);

      expect(await distanceOf(earlier), _marker.distance);
      expect(await distanceOf(later), 10000.0);
    });

    test('an activity exactly at an entry date refreshes that entry', () async {
      await insertEntries();

      await repository.setStravaActivities([_ride(1, earlier.dateTimeUTC)]);

      expect(await distanceOf(earlier), 10000.0);
    });

    test('deleting an activity refreshes the entries after it', () async {
      await database.stravaDao.upsertActivities([_ride(1, DateTime.utc(2024, 1, 15)).toCompanion()]);
      await insertEntries();

      await repository.setStravaActivities([], toDelete: [1]);

      expect(await distanceOf(earlier), _marker.distance);
      expect(await distanceOf(later), 0.0);
    });

    test('moving an activity later refreshes from its old date', () async {
      await database.stravaDao.upsertActivities([_ride(1, DateTime.utc(2024, 1, 5)).toCompanion()]);
      await insertEntries();

      await repository.setStravaActivities([
        _ride(1, DateTime.utc(2024, 1, 25), lastModified: DateTime.utc(2024, 2, 2)),
      ]);

      expect(await distanceOf(earlier), 0.0);
      expect(await distanceOf(later), 0.0);
    });

    test('an unchanged re-delivery neither writes nor refreshes', () async {
      // Sub-second values, like a Firestore timestamp; drift stores whole seconds.
      final ride = _ride(
        1,
        DateTime.utc(2024, 1, 5),
        lastModified: DateTime.utc(2024, 2, 1, 8, 0, 0, 123),
        elapsedTime: const Duration(hours: 1, milliseconds: 400),
      );
      await repository.setStravaActivities([ride]);
      await insertEntries();
      await pumpEventQueue();

      var writes = 0;
      final subscription = database
          .tableUpdates(TableUpdateQuery.onTable(database.stravaActivities))
          .listen((_) => writes++);
      await repository.setStravaActivities([ride]);
      await pumpEventQueue();
      await subscription.cancel();

      expect(writes, 0);
      expect(await distanceOf(earlier), _marker.distance);
      expect(await distanceOf(later), _marker.distance);
    });
  });
}
