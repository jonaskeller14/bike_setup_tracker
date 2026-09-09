import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/activity_rate_window.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  final now = DateTime.now().toUtc();

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertBike(String id, String? gearId, {bool isDeleted = false}) async {
    await db
        .into(db.bikes)
        .insert(
          BikesCompanion.insert(
            id: id,
            lastModified: now,
            name: 'Bike $id',
            stravaGear: Value(gearId),
            isDeleted: Value(isDeleted),
          ),
        );
  }

  Future<void> insertActivity(
    int id,
    String? gearId, {
    required Duration ago,
    double distance = 1000,
    double elevation = 100,
    int movingTime = 300,
    int elapsedTime = 400,
  }) async {
    final start = now.subtract(ago);
    await db
        .into(db.stravaActivities)
        .insert(
          StravaActivitiesCompanion.insert(
            id: Value(id),
            lastModified: now,
            name: 'Activity $id',
            athlete: 1,
            sportType: SportType.Ride,
            startDate: start,
            startDateLocal: start.toLocal(),
            gearId: Value(gearId),
            distance: Value(distance),
            totalElevationGain: Value(elevation),
            movingTime: movingTime,
            elapsedTime: elapsedTime,
          ),
        );
  }

  Future<Map<String, ActivityRateWindow>> rates({
    int sampleSize = 10,
    Duration maxLookback = const Duration(days: 180),
  }) {
    return db.stravaDao.watchBikeActivityRates(sampleSize: sampleSize, maxLookback: maxLookback).first;
  }

  group('StravaDao.watchBikeActivityRates', () {
    test('Sums the window and reports the span it covers', () async {
      await insertBike('b1', 'g1');
      await insertActivity(1, 'g1', ago: const Duration(days: 10), distance: 30000);
      await insertActivity(2, 'g1', ago: const Duration(days: 5), distance: 20000);
      await insertActivity(3, 'g1', ago: const Duration(days: 2), distance: 10000);

      final window = (await rates())['b1'];

      expect(window, isNotNull);
      expect(window!.count, 3);
      expect(window.sum.distance, 60000);
      expect(window.sum.elevationGain, 300);
      expect(window.sum.movingTime, const Duration(seconds: 900));
      expect(window.sum.elapsedTime, const Duration(seconds: 1200));
      expect(window.sum.activityCount, 3);
      expect(window.sampleSpan, const Duration(days: 8));
      expect(window.lastStart.isUtc, isTrue);
    });

    test('Keeps only the most recent sampleSize activities, whatever the insert order', () async {
      await insertBike('b1', 'g1');
      // Inserted oldest-last on purpose: the window is picked by start date.
      await insertActivity(1, 'g1', ago: const Duration(days: 4), distance: 1000);
      await insertActivity(2, 'g1', ago: const Duration(days: 20), distance: 99000);
      await insertActivity(3, 'g1', ago: const Duration(days: 8), distance: 1000);

      final window = (await rates(sampleSize: 2))['b1'];

      expect(window!.count, 2);
      expect(window.sum.distance, 2000);
      expect(window.sampleSpan, const Duration(days: 4));
    });

    test('Drops activities older than the lookback', () async {
      await insertBike('b1', 'g1');
      await insertActivity(1, 'g1', ago: const Duration(days: 200), distance: 99000);
      await insertActivity(2, 'g1', ago: const Duration(days: 10), distance: 1000);
      await insertActivity(3, 'g1', ago: const Duration(days: 3), distance: 1000);

      final window = (await rates())['b1'];

      expect(window!.count, 2);
      expect(window.sum.distance, 2000);
      expect(window.sampleSpan, const Duration(days: 7));
    });

    test('Attributes activities to their own bike only', () async {
      await insertBike('b1', 'g1');
      await insertBike('b2', 'g2');
      await insertActivity(1, 'g1', ago: const Duration(days: 6), distance: 1000);
      await insertActivity(2, 'g2', ago: const Duration(days: 4), distance: 5000);
      await insertActivity(3, 'g2', ago: const Duration(days: 1), distance: 5000);

      final result = await rates();

      expect(result['b1']!.sum.distance, 1000);
      expect(result['b2']!.sum.distance, 10000);
    });

    test('Bikes without activities, without gear, or deleted are absent', () async {
      await insertBike('b1', 'g1');
      await insertBike('b2', null);
      await insertBike('b3', 'g3', isDeleted: true);
      await insertActivity(1, 'g3', ago: const Duration(days: 2));
      await insertActivity(2, null, ago: const Duration(days: 2));

      expect(await rates(), isEmpty);
    });

    test('A single activity covers no sample span', () async {
      await insertBike('b1', 'g1');
      await insertActivity(1, 'g1', ago: const Duration(days: 2), distance: 1000);

      final window = (await rates())['b1'];

      expect(window!.count, 1);
      expect(window.sampleSpan, Duration.zero);
    });
  });
}
