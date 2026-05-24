import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/models/strava/strava_gear.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

StravaGear _gear(String id, {String name = 'Gear'}) => StravaGear(id: id, name: name);

StravaActivity _activity(int id, {String? gearId}) => StravaActivity(
      id: id,
      name: 'Ride $id',
      athlete: 1,
      sportType: SportType.Ride,
      startDate: DateTime(2024, 1, id).toUtc(),
      startDateLocal: DateTime(2024, 1, id).toLocal(),
      gearId: gearId,
      startLat: null,
      startLon: null,
      distance: null,
      totalElevationGain: null,
      movingTime: Duration.zero,
      elapsedTime: Duration.zero,
    );

void main() {
  group('setStravaGears — sync-and-prune', () {
    late AppDatabase database;
    late AppRepository repository;

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      await pumpEventQueue();
    });

    tearDown(() async {
      await database.close();
    });

    test('inserts new gears', () async {
      await repository.setStravaGears([_gear('g1'), _gear('g2')]);
      final rows = await database.stravaDao.getAllGearsBypass();
      expect(rows.map((r) => r.id), containsAll(['g1', 'g2']));
    });

    test('updates an existing gear without removing others', () async {
      await repository.setStravaGears([_gear('g1', name: 'Old'), _gear('g2')]);
      await repository.setStravaGears([_gear('g1', name: 'New'), _gear('g2')]);
      final rows = await database.stravaDao.getAllGearsBypass();
      expect(rows, hasLength(2));
      expect(rows.firstWhere((r) => r.id == 'g1').name, 'New');
    });

    test('deletes gear removed on Strava side', () async {
      await repository.setStravaGears([_gear('g1'), _gear('g2'), _gear('g3')]);
      // g2 is removed in Strava — next sync no longer includes it
      await repository.setStravaGears([_gear('g1'), _gear('g3')]);
      final rows = await database.stravaDao.getAllGearsBypass();
      expect(rows.map((r) => r.id), containsAll(['g1', 'g3']));
      expect(rows.any((r) => r.id == 'g2'), isFalse);
    });

    test('clears all gears when empty list received', () async {
      await repository.setStravaGears([_gear('g1'), _gear('g2')]);
      await repository.setStravaGears([]);
      final rows = await database.stravaDao.getAllGearsBypass();
      expect(rows, isEmpty);
    });
  });

  group('setStravaActivities — upsert + delete', () {
    late AppDatabase database;
    late AppRepository repository;

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      await pumpEventQueue();
    });

    tearDown(() async {
      await database.close();
    });

    test('inserts new activities', () async {
      await repository.setStravaActivities([_activity(1), _activity(2)]);
      final rows = await database.stravaDao.getAllActivitiesBypass();
      expect(rows.map((r) => r.id), containsAll([1, 2]));
    });

    test('updates an existing activity', () async {
      await repository.setStravaActivities([_activity(1, gearId: 'g1')]);
      await repository.setStravaActivities([_activity(1, gearId: 'g2')]);
      final rows = await database.stravaDao.getAllActivitiesBypass();
      expect(rows, hasLength(1));
      expect(rows.first.gearId, 'g2');
    });

    test('deletes activities in toDelete list', () async {
      await repository.setStravaActivities([_activity(1), _activity(2), _activity(3)]);
      await repository.setStravaActivities([], toDelete: [2]);
      final rows = await database.stravaDao.getAllActivitiesBypass();
      expect(rows.map((r) => r.id), containsAll([1, 3]));
      expect(rows.any((r) => r.id == 2), isFalse);
    });

    test('upsert and delete can happen in the same call', () async {
      await repository.setStravaActivities([_activity(1), _activity(2)]);
      await repository.setStravaActivities([_activity(3)], toDelete: [1]);
      final rows = await database.stravaDao.getAllActivitiesBypass();
      expect(rows.map((r) => r.id), containsAll([2, 3]));
      expect(rows.any((r) => r.id == 1), isFalse);
    });

    test('no-op when both lists are empty', () async {
      await repository.setStravaActivities([_activity(1)]);
      await repository.setStravaActivities([]);
      final rows = await database.stravaDao.getAllActivitiesBypass();
      expect(rows, hasLength(1));
    });
  });
}
