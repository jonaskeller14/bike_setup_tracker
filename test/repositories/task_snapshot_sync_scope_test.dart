import 'dart:math';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
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

  // Guards the cutoff as a whole: whatever a sync adds, changes or deletes, no
  // stored snapshot may differ from a fresh per-entry computation afterwards.
  group('setStravaActivities — snapshots stay equal to a full recompute', () {
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

    test('over random syncs', () async {
      final bike = Bike(name: 'Test Bike', person: null, stravaGear: 'g1');
      await repository.addBikes([bike]);
      final component = Component(
        name: 'Chain',
        componentType: ComponentType.chain,
        installations: [Installation.sinceBeginning(parent: bike.id)],
      );
      await repository.addComponents([component]);
      for (var day = 5; day <= 25; day += 5) {
        for (final association in [ComponentTaskAssociation(component.id), BikeTaskAssociation(bike.id)]) {
          final date = DateTime.utc(2024, 1, day, 12);
          await database.taskDao.insertEntry(
            TaskEntry(
              name: 'Serviced',
              taskRule: 'rule',
              association: association,
              dateTimeUTC: date,
              dateTimeLocal: date,
            ).toCompanion(),
          );
        }
      }
      await repository.refreshTaskEntrySnapshots();

      final rng = Random(7);
      final stored = <int, StravaActivity>{};
      var nextId = 1;
      var version = 0;
      // Whole hours keep entry dates (noon) hit exactly now and then.
      DateTime randomDate() => DateTime.utc(2024, 1, 1 + rng.nextInt(30), rng.nextInt(24));
      StravaActivity activity(int id, DateTime startDate) => StravaActivity(
        id: id,
        lastModified: DateTime.utc(2024, 2, 1).add(Duration(seconds: version++)),
        name: 'Ride $id',
        athlete: 1,
        sportType: SportType.Ride,
        startDate: startDate,
        startDateLocal: startDate.copyWith(isUtc: false),
        gearId: rng.nextDouble() < 0.8 ? 'g1' : 'g2',
        startLat: null,
        startLon: null,
        distance: 1000.0 * (1 + rng.nextInt(50)),
        totalElevationGain: 10.0 * rng.nextInt(50),
        movingTime: Duration(minutes: 30 + rng.nextInt(120)),
        elapsedTime: Duration(minutes: 30 + rng.nextInt(150)),
      );

      for (var round = 0; round < 40; round++) {
        final upserts = <StravaActivity>[];
        final deletes = <int>[];
        for (var op = 0; op < 1 + rng.nextInt(3); op++) {
          final ids = stored.keys.toList();
          final roll = ids.isEmpty ? 0 : rng.nextInt(4);
          switch (roll) {
            case 0: // new
              upserts.add(activity(nextId++, randomDate()));
            case 1: // changed, possibly moved to another date
              final id = ids[rng.nextInt(ids.length)];
              upserts.add(activity(id, rng.nextBool() ? stored[id]!.startDate : randomDate()));
            case 2: // deleted
              deletes.add(ids[rng.nextInt(ids.length)]);
            case 3: // re-delivered unchanged
              upserts.add(stored[ids[rng.nextInt(ids.length)]]!);
          }
        }
        deletes.removeWhere((id) => upserts.any((a) => a.id == id));
        await repository.setStravaActivities(upserts, toDelete: deletes);
        for (final a in upserts) {
          stored[a.id] = a;
        }
        deletes.forEach(stored.remove);

        for (final row in await database.taskDao.getAllEntriesBypass()) {
          final entry = row.toModel();
          final expected = await repository.getStatsAt(
            componentId: entry.association.componentId,
            bikeId: entry.association.bikeId,
            date: entry.dateTimeUTC,
          );
          expect(entry.snapshot, expected, reason: 'round $round, entry ${entry.dateTimeUTC} ${entry.association}');
        }
      }
    });
  });

  // `_isStoredUnchanged` rebuilds the activity field by field: a field it takes
  // from the wrong side would make changes to it look unchanged, never written.
  group('setStravaActivities — writes a change to any field', () {
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

    final base = StravaActivity(
      id: 1,
      lastModified: DateTime.utc(2024, 2, 1),
      name: 'Ride',
      athlete: 1,
      sportType: SportType.Ride,
      startDate: DateTime.utc(2024, 1, 1, 12),
      startDateLocal: DateTime(2024, 1, 1, 13),
      gearId: 'g1',
      startLat: 47.0,
      startLon: 11.0,
      distance: 10000.0,
      totalElevationGain: 100.0,
      movingTime: const Duration(hours: 1),
      elapsedTime: const Duration(hours: 1),
      workoutType: 10,
      averageWatts: 150.0,
    );

    // Keyed by `toJson`, so a field added to the model fails the check below
    // until it is covered here and in `_isStoredUnchanged`.
    final changes = <String, Object>{
      'lastModified': '2024-02-02T00:00:00.000Z',
      'name': 'Renamed',
      'athleteId': 2,
      'sportType': SportType.GravelRide.name,
      'startDate': '2024-01-02T12:00:00.000Z',
      'startDateLocal': '2024-01-02T13:00:00.000',
      'gearId': 'g2',
      'startLat': 48.0,
      'startLon': 12.0,
      'distance': 20000.0,
      'totalElevationGain': 200.0,
      'movingTime': 7200,
      'elapsedTime': 7200,
      'workoutType': 11,
      'averageWatts': 250.0,
    };

    test('covers every field of the model', () {
      expect(changes.keys.toSet(), base.toJson().keys.toSet()..remove('id'));
    });

    for (final MapEntry(key: field, value: value) in changes.entries) {
      test(field, () async {
        await repository.setStravaActivities([base]);
        final changed = StravaActivity.fromJson({...base.toJson(), field: value});
        expect(changed, isNot(base));

        await repository.setStravaActivities([changed]);

        expect((await database.stravaDao.getActivityById(1))!.toModel(), changed);
      });
    }
  });
}
