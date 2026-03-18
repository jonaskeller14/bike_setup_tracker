import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:drift/drift.dart' hide Component, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  const uuid = Uuid();

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertBike(String id, String gearId) async {
    await db.into(db.bikes).insert(BikesCompanion.insert(
          id: id,
          lastModified: DateTime.now().toUtc(),
          name: 'Bike $id',
          stravaGear: Value(gearId),
        ));
  }

  Future<void> insertComponent(String id, {
    double initialDistance = 0,
    double initialElevationGain = 0,
    Duration initialMovingTime = Duration.zero,
    Duration initialElapsedTime = Duration.zero,
  }) async {
    await db.into(db.components).insert(ComponentsCompanion.insert(
          id: id,
          lastModified: DateTime.now().toUtc(),
          name: 'Component $id',
          componentType: ComponentType.other,
          initialDistance: Value(initialDistance),
          initialElevationGain: Value(initialElevationGain),
          initialMovingTime: Value(initialMovingTime),
          initialElapsedTime: Value(initialElapsedTime),
        ));
  }

  Future<void> installComponent(String componentId, String? bikeId, DateTime installedAt) async {
    await db.into(db.installations).insert(InstallationsCompanion.insert(
          id: uuid.v4(),
          componentId: componentId,
          parent: Value(bikeId),
          dateTimeUTC: installedAt,
          dateTimeLocal: installedAt.toLocal(),
        ));
  }

  Future<void> insertActivity(int id, String gearId, DateTime startDate, double distance) async {
    await db.into(db.stravaActivities).insert(StravaActivitiesCompanion.insert(
          id: Value(id),
          lastModified: DateTime.now().toUtc(),
          name: 'Activity $id',
          athlete: 1,
          sportType: SportType.Ride,
          startDate: startDate,
          startDateLocal: startDate.toLocal(),
          gearId: Value(gearId),
          distance: Value(distance),
          totalElevationGain: Value(distance / 10), // dummy
          movingTime: (distance / 5).toInt(), // dummy
          elapsedTime: (distance / 4).toInt(), // dummy
        ));
  }

  group('Component Stats Aggregation Tests', () {
    test('Initial stats are returned when no activities exist', () async {
      await insertComponent('c1', initialDistance: 100.5, initialElevationGain: 50.0);
      
      final statsMap = await db.stravaDao.watchComponentStats().first;
      final stats = statsMap['c1'];
      
      expect(stats, isNotNull);
      expect(stats!.distance, 100.5);
      expect(stats.elevationGain, 50.0);
    });

    test('Activities are summed correctly for a single installation', () async {
      await insertBike('b1', 'gear1');
      await insertComponent('c1');
      final now = DateTime.now().toUtc();
      
      await installComponent('c1', 'b1', now.subtract(const Duration(days: 10)));
      
      await insertActivity(1, 'gear1', now.subtract(const Duration(days: 5)), 20.0);
      await insertActivity(2, 'gear1', now.subtract(const Duration(days: 2)), 30.0);
      
      final statsMap = await db.stravaDao.watchComponentStats().first;
      final stats = statsMap['c1'];
      
      expect(stats!.distance, 50.0);
    });

    test('Activities before installation are ignored', () async {
      await insertBike('b1', 'gear1');
      await insertComponent('c1');
      final now = DateTime.now().toUtc();
      
      await installComponent('c1', 'b1', now.subtract(const Duration(days: 5)));
      
      await insertActivity(1, 'gear1', now.subtract(const Duration(days: 10)), 20.0); // Before
      await insertActivity(2, 'gear1', now.subtract(const Duration(days: 2)), 30.0);  // After
      
      final statsMap = await db.stravaDao.watchComponentStats().first;
      expect(statsMap['c1']!.distance, 30.0);
    });

    test('Activities after uninstallation (via next null entry) are ignored', () async {
      await insertBike('b1', 'gear1');
      await insertComponent('c1');
      final now = DateTime.now().toUtc();
      
      // Install 10 days ago
      await installComponent('c1', 'b1', now.subtract(const Duration(days: 10)));
      // Uninstall 5 days ago (next entry with null parent)
      await installComponent('c1', null, now.subtract(const Duration(days: 5)));
      
      await insertActivity(1, 'gear1', now.subtract(const Duration(days: 7)), 20.0); // Inside
      await insertActivity(2, 'gear1', now.subtract(const Duration(days: 2)), 30.0); // After
      
      final statsMap = await db.stravaDao.watchComponentStats().first;
      expect(statsMap['c1']!.distance, 20.0);
    });

    test('Component moving between bikes attributes correctly', () async {
      await insertBike('bikeA', 'gearA');
      await insertBike('bikeB', 'gearB');
      await insertComponent('comp1');
      final now = DateTime.now().toUtc();
      
      // Period 1 on Bike A (20 days ago)
      await installComponent('comp1', 'bikeA', now.subtract(const Duration(days: 20)));
      
      // Period 2 on Bike B (10 days ago) - implicitly removes from Bike A
      await installComponent('comp1', 'bikeB', now.subtract(const Duration(days: 10)));
      
      await insertActivity(1, 'gearA', now.subtract(const Duration(days: 15)), 10.0); // On Bike A
      await insertActivity(2, 'gearB', now.subtract(const Duration(days: 5)), 25.0);  // On Bike B
      await insertActivity(3, 'gearA', now.subtract(const Duration(days: 5)), 99.0);  // Wrong bike A while on B
      
      final statsMap = await db.stravaDao.watchComponentStats().first;
      // Should result in 10.0 + 25.0 = 35.0
      expect(statsMap['comp1']!.distance, 35.0);
    });

    test('Initial stats are added to activity totals', () async {
      await insertBike('b1', 'gear1');
      await insertComponent('c1', initialDistance: 1000.0);
      final now = DateTime.now().toUtc();
      
      await installComponent('c1', 'b1', now.subtract(const Duration(days: 10)));
      await insertActivity(1, 'gear1', now.subtract(const Duration(days: 5)), 50.0);
      
      final statsMap = await db.stravaDao.watchComponentStats().first;
      expect(statsMap['c1']!.distance, 1050.0);
    });
  });
}
