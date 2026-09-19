import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
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

  Future<void> insertBike(String id, String gearId, {
    bool isDeleted = false,
    double initialDistance = 0,
    int initialActivityCount = 0,
    double initialKilojoules = 0,
  }) async {
    await db.into(db.bikes).insert(BikesCompanion.insert(
          id: id,
          lastModified: DateTime.now().toUtc(),
          name: 'Bike $id',
          stravaGear: Value(gearId),
          isDeleted: Value(isDeleted),
          initialDistance: Value(initialDistance),
          initialActivityCount: Value(initialActivityCount),
          initialKilojoules: Value(initialKilojoules),
        ));
  }

  Future<void> insertComponent(String id, {
    double initialDistance = 0,
    double initialElevationGain = 0,
    Duration initialMovingTime = Duration.zero,
    Duration initialElapsedTime = Duration.zero,
    double initialKilojoules = 0,
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
          initialKilojoules: Value(initialKilojoules),
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

  Future<void> installOnComponent(
    String componentId,
    String parentComponentId,
    DateTime installedAt,
  ) async {
    await db.into(db.installations).insert(InstallationsCompanion.insert(
          id: uuid.v4(),
          componentId: componentId,
          parent: Value(parentComponentId),
          parentType: const Value(InstallationParentType.component),
          dateTimeUTC: installedAt,
          dateTimeLocal: installedAt.toLocal(),
        ));
  }

  Future<void> insertActivity(int id, String gearId, DateTime startDate, double distance, {double? averageWatts}) async {
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
          averageWatts: Value(averageWatts),
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

    test('Kilojoules are summed from average watts and moving time', () async {
      await insertBike('b1', 'gear1');
      await insertComponent('c1');
      final now = DateTime.now().toUtc();

      await installComponent('c1', 'b1', now.subtract(const Duration(days: 10)));
      // distance 100 -> movingTime 20s @ 200W = 4 kJ
      await insertActivity(1, 'gear1', now.subtract(const Duration(days: 5)), 100.0, averageWatts: 200);
      // distance 200 -> movingTime 40s @ 150W = 6 kJ
      await insertActivity(2, 'gear1', now.subtract(const Duration(days: 2)), 200.0, averageWatts: 150);
      // No power meter on this ride — contributes 0 kJ, not null.
      await insertActivity(3, 'gear1', now.subtract(const Duration(days: 1)), 30.0);

      final statsMap = await db.stravaDao.watchComponentStats().first;
      expect(statsMap['c1']!.kilojoules, closeTo(10.0, 0.001));
    });

    test('Initial kilojoules are added to activity kilojoules', () async {
      await insertBike('b1', 'gear1');
      await insertComponent('c1', initialKilojoules: 500.0);
      final now = DateTime.now().toUtc();

      await installComponent('c1', 'b1', now.subtract(const Duration(days: 10)));
      // distance 100 -> movingTime 20s @ 200W = 4 kJ
      await insertActivity(1, 'gear1', now.subtract(const Duration(days: 5)), 100.0, averageWatts: 200);

      final statsMap = await db.stravaDao.watchComponentStats().first;
      expect(statsMap['c1']!.kilojoules, closeTo(504.0, 0.001));
    });

    test('a deleted bike stops crediting the components it carried', () async {
      await insertBike('b1', 'gear1', isDeleted: true);
      await insertComponent('c1', initialDistance: 7);
      final now = DateTime.now().toUtc();

      await installComponent('c1', 'b1', now.subtract(const Duration(days: 10)));
      await insertActivity(1, 'gear1', now.subtract(const Duration(days: 2)), 100.0);

      final stats = await db.stravaDao.watchComponentStats().first;
      // Only the manually entered initial distance survives.
      expect(stats['c1']!.distance, 7.0);
      expect(stats['c1']!.activityCount, 0);
    });

    test('a deleted bike stops crediting nested components too', () async {
      await insertBike('b1', 'gear1', isDeleted: true);
      await insertComponent('wheel');
      await insertComponent('tire');
      final now = DateTime.now().toUtc();

      await installComponent('wheel', 'b1', now.subtract(const Duration(days: 10)));
      await installOnComponent('tire', 'wheel', now.subtract(const Duration(days: 9)));
      await insertActivity(1, 'gear1', now.subtract(const Duration(days: 2)), 42.0);

      final stats = await db.stravaDao.watchComponentStats().first;
      expect(stats['wheel']!.distance, 0.0);
      expect(stats['tire']!.distance, 0.0);
    });

    test('credits an activity to every component at arbitrary nesting depth', () async {
      await insertBike('b1', 'gear1');
      await insertComponent('wheel');
      await insertComponent('tire');
      await insertComponent('insert');
      final now = DateTime.now().toUtc();

      await installComponent('wheel', 'b1', now.subtract(const Duration(days: 10)));
      await installOnComponent('tire', 'wheel', now.subtract(const Duration(days: 9)));
      await installOnComponent('insert', 'tire', now.subtract(const Duration(days: 8)));
      await insertActivity(1, 'gear1', now.subtract(const Duration(days: 2)), 42.0);

      final stats = await db.stravaDao.watchComponentStats().first;
      expect(stats['wheel']!.distance, 42.0);
      expect(stats['tire']!.distance, 42.0);
      expect(stats['insert']!.distance, 42.0);
    });

    test('parent move and deinstallation implicitly bound child stats', () async {
      await insertBike('bikeA', 'gearA');
      await insertBike('bikeB', 'gearB');
      await insertComponent('wheel');
      await insertComponent('tire');
      final now = DateTime.now().toUtc();

      await installComponent('wheel', 'bikeA', now.subtract(const Duration(days: 20)));
      await installOnComponent('tire', 'wheel', now.subtract(const Duration(days: 19)));
      await installComponent('wheel', 'bikeB', now.subtract(const Duration(days: 10)));
      await installComponent('wheel', null, now.subtract(const Duration(days: 3)));
      await insertActivity(1, 'gearA', now.subtract(const Duration(days: 15)), 10.0);
      await insertActivity(2, 'gearB', now.subtract(const Duration(days: 5)), 20.0);
      await insertActivity(3, 'gearB', now.subtract(const Duration(days: 1)), 99.0);

      final stats = await db.stravaDao.watchComponentStats().first;
      expect(stats['wheel']!.distance, 30.0);
      expect(stats['tire']!.distance, 30.0);
    });

    test('dangling component parents receive no activity credit', () async {
      await insertBike('b1', 'gear1');
      await insertComponent('tire', initialDistance: 5);
      final now = DateTime.now().toUtc();
      await installOnComponent('tire', 'missing-wheel', now.subtract(const Duration(days: 10)));
      await insertActivity(1, 'gear1', now.subtract(const Duration(days: 2)), 42.0);

      final stats = await db.stravaDao.watchComponentStats().first;
      expect(stats['tire']!.distance, 5.0);
    });
  });

  group('Bike initial stats', () {
    final sinceBeginning = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    test('a bike without activities reports its initial stats', () async {
      await insertBike('b1', 'gear1', initialDistance: 5000, initialActivityCount: 3, initialKilojoules: 900);

      final stats = (await db.stravaDao.watchBikeStats().first)['b1']!;
      expect(stats.distance, 5000.0);
      expect(stats.activityCount, 3);
      expect(stats.kilojoules, 900.0);
    });

    test('initial stats are added to the bike activity totals', () async {
      await insertBike('b1', 'gear1', initialDistance: 5000, initialActivityCount: 3, initialKilojoules: 900);
      final now = DateTime.now().toUtc();
      // distance 100 -> movingTime 20s @ 200W = 4 kJ
      await insertActivity(1, 'gear1', now.subtract(const Duration(days: 5)), 100.0, averageWatts: 200);
      await insertActivity(2, 'gear1', now.subtract(const Duration(days: 2)), 50.0);

      final stats = (await db.stravaDao.watchBikeStats().first)['b1']!;
      expect(stats.distance, 5150.0);
      expect(stats.activityCount, 5);
      expect(stats.kilojoules, closeTo(904.0, 0.001));
    });

    test('getBikeStatsAt before the first activity still returns the initial stats', () async {
      await insertBike('b1', 'gear1', initialDistance: 5000, initialActivityCount: 3);
      final now = DateTime.now().toUtc();
      await insertActivity(1, 'gear1', now.subtract(const Duration(days: 2)), 50.0);

      final stats = await db.stravaDao.getBikeStatsAt('b1', now.subtract(const Duration(days: 10)));
      expect(stats.distance, 5000.0);
      expect(stats.activityCount, 3);
    });

    test('getBikeStatsAt counts only activities up to the date on top of the initial stats', () async {
      await insertBike('b1', 'gear1', initialDistance: 5000);
      final now = DateTime.now().toUtc();
      await insertActivity(1, 'gear1', now.subtract(const Duration(days: 5)), 100.0);
      await insertActivity(2, 'gear1', now.subtract(const Duration(days: 1)), 50.0);

      final stats = await db.stravaDao.getBikeStatsAt('b1', now.subtract(const Duration(days: 3)));
      expect(stats.distance, 5100.0);
      expect(stats.activityCount, 1);
    });

    test('a component installed since beginning inherits the bike initial stats', () async {
      await insertBike('b1', 'gear1', initialDistance: 5000, initialActivityCount: 3);
      await insertComponent('c1', initialDistance: 200);
      final now = DateTime.now().toUtc();
      await installComponent('c1', 'b1', sinceBeginning);
      await insertActivity(1, 'gear1', now.subtract(const Duration(days: 2)), 50.0);

      final stats = (await db.stravaDao.watchComponentStats().first)['c1']!;
      expect(stats.distance, 5250.0);
      expect(stats.activityCount, 4);
    });

    test('a component installed at a real date does not inherit', () async {
      await insertBike('b1', 'gear1', initialDistance: 5000);
      await insertComponent('c1');
      final now = DateTime.now().toUtc();
      await installComponent('c1', 'b1', now.subtract(const Duration(days: 10)));

      final stats = (await db.stravaDao.watchComponentStats().first)['c1']!;
      expect(stats.distance, 0.0);
    });

    test('nested components inherit transitively only when since beginning', () async {
      await insertBike('b1', 'gear1', initialDistance: 5000);
      await insertComponent('wheel');
      await insertComponent('tire');
      await insertComponent('insert');
      await insertComponent('laterTire');
      final now = DateTime.now().toUtc();
      await installComponent('wheel', 'b1', sinceBeginning);
      await installOnComponent('tire', 'wheel', sinceBeginning);
      await installOnComponent('insert', 'tire', sinceBeginning);
      await installOnComponent('laterTire', 'wheel', now.subtract(const Duration(days: 10)));

      final stats = await db.stravaDao.watchComponentStats().first;
      expect(stats['wheel']!.distance, 5000.0);
      expect(stats['tire']!.distance, 5000.0);
      expect(stats['insert']!.distance, 5000.0);
      expect(stats['laterTire']!.distance, 0.0);
    });

    test('a component moved to another bike keeps the since-beginning bike initial stats', () async {
      await insertBike('bikeA', 'gearA', initialDistance: 5000);
      await insertBike('bikeB', 'gearB', initialDistance: 8000);
      await insertComponent('c1');
      final now = DateTime.now().toUtc();
      await installComponent('c1', 'bikeA', sinceBeginning);
      await installComponent('c1', 'bikeB', now.subtract(const Duration(days: 10)));

      final stats = (await db.stravaDao.watchComponentStats().first)['c1']!;
      expect(stats.distance, 5000.0);
    });

    test('a since-beginning component that is uninstalled first does not inherit', () async {
      await insertBike('b1', 'gear1', initialDistance: 5000);
      await insertComponent('c1');
      final now = DateTime.now().toUtc();
      await installComponent('c1', null, sinceBeginning);
      await installComponent('c1', 'b1', now.subtract(const Duration(days: 10)));

      final stats = (await db.stravaDao.watchComponentStats().first)['c1']!;
      expect(stats.distance, 0.0);
    });

    test('a deleted bike passes on no initial stats', () async {
      await insertBike('b1', 'gear1', isDeleted: true, initialDistance: 5000);
      await insertComponent('c1', initialDistance: 7);
      await installComponent('c1', 'b1', sinceBeginning);

      final stats = (await db.stravaDao.watchComponentStats().first)['c1']!;
      expect(stats.distance, 7.0);
    });

    test('getComponentStatsAt includes the inherited initial stats at any date', () async {
      await insertBike('b1', 'gear1', initialDistance: 5000);
      await insertComponent('c1', initialDistance: 200);
      final now = DateTime.now().toUtc();
      await installComponent('c1', 'b1', sinceBeginning);
      await insertActivity(1, 'gear1', now.subtract(const Duration(days: 2)), 50.0);

      final before = await db.stravaDao.getComponentStatsAt('c1', now.subtract(const Duration(days: 10)));
      final after = await db.stravaDao.getComponentStatsAt('c1', now);
      expect(before.distance, 5200.0);
      expect(after.distance, 5250.0);
    });
  });
}
