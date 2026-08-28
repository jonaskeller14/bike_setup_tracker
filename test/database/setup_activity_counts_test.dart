import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  final baseTime = DateTime.utc(2025, 1, 1, 12);

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertBike(String id, {String? gearId}) async {
    await db
        .into(db.bikes)
        .insert(
          BikesCompanion.insert(
            id: id,
            lastModified: baseTime,
            name: 'Bike $id',
            stravaGear: Value(gearId),
          ),
        );
  }

  Future<void> insertSetup(
    String id,
    String bikeId,
    DateTime datetime, {
    bool isDeleted = false,
  }) async {
    await db
        .into(db.setups)
        .insert(
          SetupsCompanion.insert(
            id: id,
            bikeId: bikeId,
            isDeleted: Value(isDeleted),
            lastModified: baseTime,
            datetime: datetime,
            datetimeLocal: datetime,
            tags: const {},
          ),
        );
  }

  Future<void> insertActivity(
    int id, {
    String? gearId,
    required DateTime start,
    required Duration elapsed,
  }) async {
    await db
        .into(db.stravaActivities)
        .insert(
          StravaActivitiesCompanion.insert(
            id: Value(id),
            lastModified: baseTime,
            name: 'Activity $id',
            athlete: 1,
            sportType: SportType.Ride,
            startDate: start,
            startDateLocal: start,
            gearId: Value(gearId),
            movingTime: elapsed.inSeconds,
            elapsedTime: elapsed.inSeconds,
          ),
        );
  }

  group('getSetupActivityCounts', () {
    test('attributes an activity to the setup active before its start', () async {
      await insertBike('bike', gearId: 'gear');
      await insertSetup('setup', 'bike', baseTime);
      await insertActivity(
        1,
        gearId: 'gear',
        start: baseTime.add(const Duration(hours: 1)),
        elapsed: const Duration(minutes: 30),
      );

      expect(await db.stravaDao.getSetupActivityCounts(), {'setup': 1});
    });

    test('attributes one activity to every setup changed during it', () async {
      await insertBike('bike', gearId: 'gear');
      await insertSetup('before', 'bike', baseTime);
      await insertSetup('during-1', 'bike', baseTime.add(const Duration(minutes: 15)));
      await insertSetup('during-2', 'bike', baseTime.add(const Duration(minutes: 45)));
      await insertSetup('after', 'bike', baseTime.add(const Duration(hours: 2)));
      await insertActivity(
        1,
        gearId: 'gear',
        start: baseTime.add(const Duration(minutes: 5)),
        elapsed: const Duration(hours: 1),
      );

      expect(await db.stravaDao.getSetupActivityCounts(), {
        'before': 1,
        'during-1': 1,
        'during-2': 1,
        'after': 0,
      });
    });

    test('uses exact start inclusively and exact end exclusively', () async {
      await insertBike('bike', gearId: 'gear');
      await insertSetup('at-start', 'bike', baseTime);
      await insertSetup('at-end', 'bike', baseTime.add(const Duration(hours: 1)));
      await insertActivity(
        1,
        gearId: 'gear',
        start: baseTime,
        elapsed: const Duration(hours: 1),
      );

      expect(await db.stravaDao.getSetupActivityCounts(), {
        'at-start': 1,
        'at-end': 0,
      });
    });

    test('handles sequential activities and the newest open interval', () async {
      await insertBike('bike', gearId: 'gear');
      await insertSetup('old', 'bike', baseTime);
      await insertSetup('newest', 'bike', baseTime.add(const Duration(days: 1)));
      await insertActivity(
        1,
        gearId: 'gear',
        start: baseTime.add(const Duration(hours: 1)),
        elapsed: const Duration(minutes: 20),
      );
      await insertActivity(
        2,
        gearId: 'gear',
        start: baseTime.add(const Duration(days: 1, hours: 1)),
        elapsed: const Duration(minutes: 20),
      );
      await insertActivity(
        3,
        gearId: 'gear',
        start: baseTime.add(const Duration(days: 2)),
        elapsed: const Duration(minutes: 20),
      );

      expect(await db.stravaDao.getSetupActivityCounts(), {
        'old': 1,
        'newest': 2,
      });
    });

    test('keeps bikes and gears isolated', () async {
      await insertBike('bike-a', gearId: 'gear-a');
      await insertBike('bike-b', gearId: 'gear-b');
      await insertBike('bike-unlinked');
      await insertSetup('setup-a', 'bike-a', baseTime);
      await insertSetup('setup-b', 'bike-b', baseTime);
      await insertSetup('setup-unlinked', 'bike-unlinked', baseTime);
      await insertActivity(
        1,
        gearId: 'gear-a',
        start: baseTime.add(const Duration(hours: 1)),
        elapsed: const Duration(minutes: 20),
      );
      await insertActivity(
        2,
        gearId: 'unknown-gear',
        start: baseTime.add(const Duration(hours: 1)),
        elapsed: const Duration(minutes: 20),
      );

      expect(await db.stravaDao.getSetupActivityCounts(), {
        'setup-a': 1,
        'setup-b': 0,
        'setup-unlinked': 0,
      });
    });

    test('excludes deleted setups without shortening active intervals', () async {
      await insertBike('bike', gearId: 'gear');
      await insertSetup('active', 'bike', baseTime);
      await insertSetup(
        'deleted',
        'bike',
        baseTime.add(const Duration(hours: 1)),
        isDeleted: true,
      );
      await insertActivity(
        1,
        gearId: 'gear',
        start: baseTime.add(const Duration(hours: 2)),
        elapsed: const Duration(minutes: 20),
      );

      expect(await db.stravaDao.getSetupActivityCounts(), {'active': 1});
    });

    test('returns explicit zero counts when there are no activities', () async {
      await insertBike('bike', gearId: 'gear');
      await insertSetup('setup', 'bike', baseTime);

      expect(await db.stravaDao.getSetupActivityCounts(), {'setup': 0});
    });

    test('counts complete history beyond the repository page size', () async {
      await insertBike('bike', gearId: 'gear');
      await insertSetup('setup', 'bike', baseTime);

      for (var id = 1; id <= 75; id++) {
        await insertActivity(
          id,
          gearId: 'gear',
          start: baseTime.add(Duration(minutes: id)),
          elapsed: const Duration(seconds: 30),
        );
      }

      expect(await db.stravaDao.getSetupActivityCounts(), {'setup': 75});
    });
  });

  group('activity existence', () {
    test('does not require a gear assignment and reacts to changes', () async {
      expect(await db.stravaDao.hasAnyActivity(), isFalse);

      final values = <bool>[];
      final subscription = db.stravaDao.watchHasAnyActivity().listen(values.add);
      await Future<void>.delayed(Duration.zero);

      await insertActivity(
        1,
        start: baseTime,
        elapsed: const Duration(minutes: 10),
      );
      await Future<void>.delayed(Duration.zero);

      expect(await db.stravaDao.hasAnyActivity(), isTrue);
      expect(values, [false, true]);
      await subscription.cancel();
    });
  });
}
