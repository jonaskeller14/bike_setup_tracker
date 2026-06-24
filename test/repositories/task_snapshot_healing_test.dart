import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/component_stats.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/utils/file_import.dart';
import 'package:flutter_test/flutter_test.dart';

/// Allow Drift streams to propagate through subscriptions.
Future<void> pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

void main() {
  group("Task Snapshot Healing - Integration Test", () {
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

    test("strava sync old activities should update task entry snapshot", () async {
      // 1. Setup: Bike, Component, and Task Rule
      final bike = Bike(name: "Test Bike", person: null, stravaGear: "g123");
      await repository.addBike(bike);
      
      final component = Component(
        name: "Chain",
        componentType: ComponentType.chain,
        installations: [Installation.sinceBeginning(parent: bike.id)],
      );
      await repository.addComponent(component);

      final rule = TaskRule(
        name: "Chain Wax",
        componentId: component.id,
        tags: const {},
      );
      await repository.addTaskRule(rule);
      await pumpEventQueue();

      // 2. Add a recent activity (Activity A)
      final activityA = StravaActivity(
        id: 1,
        name: "Ride A",
        athlete: 1,
        sportType: SportType.Ride,
        startDate: DateTime.utc(2024, 1, 1, 12),
        startDateLocal: DateTime(2024, 1, 1, 12),
        gearId: "g123",
        startLat: 0,
        startLon: 0,
        distance: 100000.0, // 100km
        totalElevationGain: 1000.0,
        movingTime: const Duration(hours: 4),
        elapsedTime: const Duration(hours: 5),
      );
      await repository.setStravaActivities([activityA]);
      await pumpEventQueue();

      // 3. Create a Task Entry at 2024-01-02
      // At this point, the statistics at Jan 2nd should be 100km (from Activity A)
      final entryDate = DateTime.utc(2024, 1, 2);
      final initialStats = await repository.getStatsAt(
        componentId: component.id,
        date: entryDate,
      );
      
      expect(initialStats.distance, 100000.0);

      final entry = TaskEntry(
        name: "Waxed",
        taskRule: rule.id,
        componentId: component.id,
        dateTimeUTC: entryDate,
        dateTimeLocal: entryDate.toLocal(),
        snapshot: initialStats,
      );
      await repository.addTaskEntry(entry);
      await pumpEventQueue();

      // Verify entry is stored with 100km snapshot
      expect(repository.taskEntries[entry.id]?.snapshot?.distance, 100000.0);

      // 4. "Sync" an OLD activity (Activity B) that happened BEFORE the entry
      // This activity happened on Dec 31st, 2023.
      final activityB = StravaActivity(
        id: 2,
        name: "Ride B (Historical)",
        athlete: 1,
        sportType: SportType.Ride,
        startDate: DateTime.utc(2023, 12, 31, 12),
        startDateLocal: DateTime(2023, 12, 31, 12),
        gearId: "g123",
        startLat: 0,
        startLon: 0,
        distance: 50000.0, // 50km
        totalElevationGain: 500.0,
        movingTime: const Duration(hours: 2),
        elapsedTime: const Duration(hours: 2, minutes: 30),
      );

      // setStravaActivities triggers refreshTaskEntrySnapshots()
      await repository.setStravaActivities([activityA, activityB]);
      await pumpEventQueue();

      // 5. Verification: The entry snapshot should now be 150km (100km + 50km)
      final updatedEntry = repository.taskEntries[entry.id];
      expect(updatedEntry?.snapshot?.distance, 150000.0);
      expect(updatedEntry?.snapshot?.activityCount, 2);
    });

    test("stats should sum up across multiple installation windows (Bike A -> Archive -> Bike B)", () async {
      // 1. Setup: Two bikes and one component
      final bikeA = Bike(name: "Bike A", person: null, stravaGear: "gear_a");
      final bikeB = Bike(name: "Bike B", person: null, stravaGear: "gear_b");
      await repository.addBike(bikeA);
      await repository.addBike(bikeB);

      // Component initially installed on Bike A
      final component = Component(
        id: "comp_1",
        name: "Test Component",
        componentType: ComponentType.other,
        installations: [
          Installation.sinceBeginning(parent: bikeA.id),
        ],
      );
      await repository.addComponent(component);
      await pumpEventQueue();

      // 2. Activity on Bike A (Jan 1st)
      final activityA = StravaActivity(
        id: 101,
        name: "Ride on Bike A",
        athlete: 1,
        sportType: SportType.Ride,
        startDate: DateTime.utc(2024, 1, 1, 12),
        startDateLocal: DateTime(2024, 1, 1, 12),
        gearId: "gear_a",
        startLat: 0, 
        startLon: 0,
        distance: 50000.0, // 50km
        totalElevationGain: 500.0,
        movingTime: const Duration(hours: 2),
        elapsedTime: const Duration(hours: 2),
      );
      await repository.setStravaActivities([activityA]);
      await pumpEventQueue();

      expect((await repository.getStatsAt(componentId: component.id, date: DateTime.utc(2024, 1, 1, 23))).distance, 50000.0);

      // 3. Move to Archive (Jan 2nd) and Ride Bike A again
      // The component is NOT on Bike A anymore, so stats shouldn't increase from Bike A rides.
      final deinstallDate = DateTime.utc(2024, 1, 2, 10);
      final componentInArchive = component.copyWith(
        installations: [
          ...component.installations,
          Installation(parent: null, dateTimeUTC: deinstallDate, dateTimeLocal: deinstallDate.toLocal()),
        ],
      );
      await repository.editComponent(componentInArchive);
      await pumpEventQueue();

      final activityA2 = StravaActivity(
        id: 102,
        name: "Another Ride on Bike A (Component removed)",
        athlete: 1,
        sportType: SportType.Ride,
        startDate: DateTime.utc(2024, 1, 2, 12),
        startDateLocal: DateTime(2024, 1, 2, 12),
        gearId: "gear_a",
        startLat: 0, 
        startLon: 0,
        distance: 50000.0, // 50km
        totalElevationGain: 500.0,
        movingTime: const Duration(hours: 2),
        elapsedTime: const Duration(hours: 2),
      );
      await repository.setStravaActivities([activityA, activityA2]);
      await pumpEventQueue();

      // Stats should still be 50km because activityA2 happened while component was in Archive
      expect((await repository.getStatsAt(componentId: component.id, date: DateTime.utc(2024, 1, 2, 23))).distance, 50000.0);

      // 4. Move to Bike B (Jan 3rd) and Ride Bike B
      final reinstallDate = DateTime.utc(2024, 1, 3, 10);
      final componentOnB = repository.components[component.id]!;
      await repository.editComponent(componentOnB.copyWith(
        installations: [
          ...componentOnB.installations,
          Installation(parent: bikeB.id, dateTimeUTC: reinstallDate, dateTimeLocal: reinstallDate.toLocal()),
        ],
      ));
      await pumpEventQueue();

      final activityB = StravaActivity(
        id: 103,
        name: "Ride on Bike B",
        athlete: 1,
        sportType: SportType.Ride,
        startDate: DateTime.utc(2024, 1, 3, 12),
        startDateLocal: DateTime(2024, 1, 3, 12),
        gearId: "gear_b",
        startLat: 0, 
        startLon: 0,
        distance: 30000.0, // 30km
        totalElevationGain: 300.0,
        movingTime: const Duration(hours: 1),
        elapsedTime: const Duration(hours: 1),
      );
      await repository.setStravaActivities([activityA, activityA2, activityB]);
      await pumpEventQueue();

      // 5. Grand Total verification: 50km (Bike A) + 30km (Bike B) = 80km
      final finalStats = await repository.getStatsAt(componentId: component.id, date: DateTime.utc(2024, 1, 4));
      expect(finalStats.distance, 80000.0);
      expect(finalStats.activityCount, 2); // Excludes the middle activityA2
    });
  });

  group("Task Snapshot Healing - Gear Linking", () {
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

    test("linking Strava gear to a bike recomputes task entry snapshots", () async {
      // 1. Bike with NO gear linked yet, plus a component and task rule.
      final bike = Bike(name: "Test Bike", person: null, stravaGear: null);
      await repository.addBike(bike);

      final component = Component(
        name: "Chain",
        componentType: ComponentType.chain,
        installations: [Installation.sinceBeginning(parent: bike.id)],
      );
      await repository.addComponent(component);

      final rule = TaskRule(name: "Chain Wax", componentId: component.id, tags: const {});
      await repository.addTaskRule(rule);
      await pumpEventQueue();

      // 2. A Strava activity exists for gear "g123" (not yet linked to any bike).
      final activity = StravaActivity(
        id: 1,
        name: "Ride",
        athlete: 1,
        sportType: SportType.Ride,
        startDate: DateTime.utc(2024, 1, 1, 12),
        startDateLocal: DateTime(2024, 1, 1, 12),
        gearId: "g123",
        startLat: 0,
        startLon: 0,
        distance: 100000.0, // 100km
        totalElevationGain: 1000.0,
        movingTime: const Duration(hours: 4),
        elapsedTime: const Duration(hours: 5),
      );
      await repository.setStravaActivities([activity]);
      await pumpEventQueue();

      // 3. Task entry created while the bike has no gear -> snapshot is 0km.
      final entryDate = DateTime.utc(2024, 1, 2);
      final initialStats = await repository.getStatsAt(componentId: component.id, date: entryDate);
      expect(initialStats.distance, 0.0);

      final entry = TaskEntry(
        name: "Waxed",
        taskRule: rule.id,
        componentId: component.id,
        dateTimeUTC: entryDate,
        dateTimeLocal: entryDate.toLocal(),
        snapshot: initialStats,
      );
      await repository.addTaskEntry(entry);
      await pumpEventQueue();
      expect(repository.taskEntries[entry.id]?.snapshot?.distance, 0.0);

      // 4. Link the gear to the bike. This should heal the task entry snapshot.
      await repository.editBike(bike.copyWith(stravaGear: "g123"));
      await pumpEventQueue();

      // 5. The snapshot now reflects the gear's activity (100km, 1 activity).
      final updated = repository.taskEntries[entry.id];
      expect(updated?.snapshot?.distance, 100000.0);
      expect(updated?.snapshot?.activityCount, 1);
    });

    test("unlinking Strava gear from a bike recomputes task entry snapshots", () async {
      // 1. Bike already linked to gear "g123", with a component and task rule.
      final bike = Bike(name: "Test Bike", person: null, stravaGear: "g123");
      await repository.addBike(bike);

      final component = Component(
        name: "Chain",
        componentType: ComponentType.chain,
        installations: [Installation.sinceBeginning(parent: bike.id)],
      );
      await repository.addComponent(component);

      final rule = TaskRule(name: "Chain Wax", componentId: component.id, tags: const {});
      await repository.addTaskRule(rule);

      final activity = StravaActivity(
        id: 1,
        name: "Ride",
        athlete: 1,
        sportType: SportType.Ride,
        startDate: DateTime.utc(2024, 1, 1, 12),
        startDateLocal: DateTime(2024, 1, 1, 12),
        gearId: "g123",
        startLat: 0,
        startLon: 0,
        distance: 100000.0,
        totalElevationGain: 1000.0,
        movingTime: const Duration(hours: 4),
        elapsedTime: const Duration(hours: 5),
      );
      await repository.setStravaActivities([activity]);
      await pumpEventQueue();

      // 2. Entry snapshot reflects the linked gear (100km).
      final entryDate = DateTime.utc(2024, 1, 2);
      final initialStats = await repository.getStatsAt(componentId: component.id, date: entryDate);
      expect(initialStats.distance, 100000.0);

      final entry = TaskEntry(
        name: "Waxed",
        taskRule: rule.id,
        componentId: component.id,
        dateTimeUTC: entryDate,
        dateTimeLocal: entryDate.toLocal(),
        snapshot: initialStats,
      );
      await repository.addTaskEntry(entry);
      await pumpEventQueue();
      expect(repository.taskEntries[entry.id]?.snapshot?.distance, 100000.0);

      // 3. Unlink the gear. The snapshot should fall back to 0km.
      await repository.editBike(bike.copyWith(stravaGear: null));
      await pumpEventQueue();

      final updated = repository.taskEntries[entry.id];
      expect(updated?.snapshot?.distance, 0.0);
      expect(updated?.snapshot?.activityCount, 0);
    });
  });

  group("Task Snapshot Healing - Component Edits", () {
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

    test("moving a component to a gear-linked bike recomputes task entry snapshots", () async {
      // Two bikes: one linked to a gear with activities, one with no gear.
      final bikeWithGear = Bike(name: "Bike A", person: null, stravaGear: "g123");
      final bikeNoGear = Bike(name: "Bike B", person: null, stravaGear: null);
      await repository.addBike(bikeWithGear);
      await repository.addBike(bikeNoGear);

      // Component starts on the gear-less bike.
      final component = Component(
        name: "Chain",
        componentType: ComponentType.chain,
        installations: [Installation.sinceBeginning(parent: bikeNoGear.id)],
      );
      await repository.addComponent(component);

      final rule = TaskRule(name: "Chain Wax", componentId: component.id, tags: const {});
      await repository.addTaskRule(rule);

      final activity = StravaActivity(
        id: 1,
        name: "Ride",
        athlete: 1,
        sportType: SportType.Ride,
        startDate: DateTime.utc(2024, 1, 1, 12),
        startDateLocal: DateTime(2024, 1, 1, 12),
        gearId: "g123",
        startLat: 0,
        startLon: 0,
        distance: 100000.0,
        totalElevationGain: 1000.0,
        movingTime: const Duration(hours: 4),
        elapsedTime: const Duration(hours: 5),
      );
      await repository.setStravaActivities([activity]);
      await pumpEventQueue();

      // Entry created while the component is on the gear-less bike -> 0km.
      final entryDate = DateTime.utc(2024, 1, 2);
      final entry = TaskEntry(
        name: "Waxed",
        taskRule: rule.id,
        componentId: component.id,
        dateTimeUTC: entryDate,
        dateTimeLocal: entryDate.toLocal(),
        snapshot: await repository.getStatsAt(componentId: component.id, date: entryDate),
      );
      await repository.addTaskEntry(entry);
      await pumpEventQueue();
      expect(repository.taskEntries[entry.id]?.snapshot?.distance, 0.0);

      // Move the component onto the gear-linked bike (since the beginning), so
      // the 100km activity now counts toward it.
      await repository.editComponent(component.copyWith(
        installations: [Installation.sinceBeginning(parent: bikeWithGear.id)],
      ));
      await pumpEventQueue();

      final updated = repository.taskEntries[entry.id];
      expect(updated?.snapshot?.distance, 100000.0);
      expect(updated?.snapshot?.activityCount, 1);
    });

    test("editing a component's initial stats recomputes task entry snapshots", () async {
      final bike = Bike(name: "Test Bike", person: null, stravaGear: null);
      await repository.addBike(bike);

      final component = Component(
        name: "Chain",
        componentType: ComponentType.chain,
        installations: [Installation.sinceBeginning(parent: bike.id)],
        initialDistance: 0.0,
      );
      await repository.addComponent(component);

      final rule = TaskRule(name: "Chain Wax", componentId: component.id, tags: const {});
      await repository.addTaskRule(rule);
      await pumpEventQueue();

      final entryDate = DateTime.utc(2024, 1, 2);
      final entry = TaskEntry(
        name: "Waxed",
        taskRule: rule.id,
        componentId: component.id,
        dateTimeUTC: entryDate,
        dateTimeLocal: entryDate.toLocal(),
        snapshot: await repository.getStatsAt(componentId: component.id, date: entryDate),
      );
      await repository.addTaskEntry(entry);
      await pumpEventQueue();
      expect(repository.taskEntries[entry.id]?.snapshot?.distance, 0.0);

      // Bump the component's initial distance (e.g. a used part). The snapshot,
      // which includes initial stats, must reflect the new baseline.
      await repository.editComponent(component.copyWith(initialDistance: 25000.0));
      await pumpEventQueue();

      expect(repository.taskEntries[entry.id]?.snapshot?.distance, 25000.0);
    });
  });

  group("Task Snapshot Healing - Clear Strava Data", () {
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

    test("clearing Strava data resets task entry snapshots to initial stats", () async {
      final bike = Bike(name: "Test Bike", person: null, stravaGear: "g123");
      await repository.addBike(bike);

      final component = Component(
        name: "Chain",
        componentType: ComponentType.chain,
        installations: [Installation.sinceBeginning(parent: bike.id)],
      );
      await repository.addComponent(component);

      final rule = TaskRule(name: "Chain Wax", componentId: component.id, tags: const {});
      await repository.addTaskRule(rule);

      final activity = StravaActivity(
        id: 1,
        name: "Ride",
        athlete: 1,
        sportType: SportType.Ride,
        startDate: DateTime.utc(2024, 1, 1, 12),
        startDateLocal: DateTime(2024, 1, 1, 12),
        gearId: "g123",
        startLat: 0,
        startLon: 0,
        distance: 100000.0,
        totalElevationGain: 1000.0,
        movingTime: const Duration(hours: 4),
        elapsedTime: const Duration(hours: 5),
      );
      await repository.setStravaActivities([activity]);
      await pumpEventQueue();

      final entryDate = DateTime.utc(2024, 1, 2);
      final entry = TaskEntry(
        name: "Waxed",
        taskRule: rule.id,
        componentId: component.id,
        dateTimeUTC: entryDate,
        dateTimeLocal: entryDate.toLocal(),
        snapshot: await repository.getStatsAt(componentId: component.id, date: entryDate),
      );
      await repository.addTaskEntry(entry);
      await pumpEventQueue();
      expect(repository.taskEntries[entry.id]?.snapshot?.distance, 100000.0);

      // Disconnecting Strava wipes all activities; the snapshot must fall back
      // to the component's initial-only stats (0km here).
      await repository.clearStravaData();
      await pumpEventQueue();

      final updated = repository.taskEntries[entry.id];
      expect(updated?.snapshot?.distance, 0.0);
      expect(updated?.snapshot?.activityCount, 0);
    });
  });

  group("Task Snapshot Healing - Bike-linked entries", () {
    // The other groups all exercise component-linked entries (getComponentStatsAt).
    // These cover the parallel getBikeStatsAt path: a task entry linked directly
    // to a bike (bikeId, no componentId) must heal the same way.
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

    StravaActivity rideForGear(String gearId) => StravaActivity(
          id: 1,
          name: "Ride",
          athlete: 1,
          sportType: SportType.Ride,
          startDate: DateTime.utc(2024, 1, 1, 12),
          startDateLocal: DateTime(2024, 1, 1, 12),
          gearId: gearId,
          startLat: 0,
          startLon: 0,
          distance: 100000.0,
          totalElevationGain: 1000.0,
          movingTime: const Duration(hours: 4),
          elapsedTime: const Duration(hours: 5),
        );

    test("linking and unlinking gear recomputes a bike-linked entry snapshot", () async {
      // Bike with no gear yet + a bike-linked task rule.
      final bike = Bike(name: "Test Bike", person: null, stravaGear: null);
      await repository.addBike(bike);
      final rule = TaskRule(name: "Bike Service", bikeId: bike.id, tags: const {});
      await repository.addTaskRule(rule);

      // An activity exists for gear "g123" (not linked to any bike yet).
      await repository.setStravaActivities([rideForGear("g123")]);
      await pumpEventQueue();

      // Entry created while the bike has no gear -> 0km.
      final entryDate = DateTime.utc(2024, 1, 2);
      final entry = TaskEntry(
        name: "Serviced",
        taskRule: rule.id,
        bikeId: bike.id,
        dateTimeUTC: entryDate,
        dateTimeLocal: entryDate.toLocal(),
        snapshot: await repository.getStatsAt(bikeId: bike.id, date: entryDate),
      );
      await repository.addTaskEntry(entry);
      await pumpEventQueue();
      expect(repository.taskEntries[entry.id]?.snapshot?.distance, 0.0);

      // Link the gear -> the bike-linked snapshot picks up the 100km activity.
      await repository.editBike(bike.copyWith(stravaGear: "g123"));
      await pumpEventQueue();
      expect(repository.taskEntries[entry.id]?.snapshot?.distance, 100000.0);
      expect(repository.taskEntries[entry.id]?.snapshot?.activityCount, 1);

      // Unlink again -> back to 0km.
      await repository.editBike(bike.copyWith(stravaGear: null));
      await pumpEventQueue();
      expect(repository.taskEntries[entry.id]?.snapshot?.distance, 0.0);
      expect(repository.taskEntries[entry.id]?.snapshot?.activityCount, 0);
    });

    test("clearing Strava data resets a bike-linked entry snapshot", () async {
      final bike = Bike(name: "Test Bike", person: null, stravaGear: "g123");
      await repository.addBike(bike);
      final rule = TaskRule(name: "Bike Service", bikeId: bike.id, tags: const {});
      await repository.addTaskRule(rule);

      await repository.setStravaActivities([rideForGear("g123")]);
      await pumpEventQueue();

      final entryDate = DateTime.utc(2024, 1, 2);
      final entry = TaskEntry(
        name: "Serviced",
        taskRule: rule.id,
        bikeId: bike.id,
        dateTimeUTC: entryDate,
        dateTimeLocal: entryDate.toLocal(),
        snapshot: await repository.getStatsAt(bikeId: bike.id, date: entryDate),
      );
      await repository.addTaskEntry(entry);
      await pumpEventQueue();
      expect(repository.taskEntries[entry.id]?.snapshot?.distance, 100000.0);

      await repository.clearStravaData();
      await pumpEventQueue();
      expect(repository.taskEntries[entry.id]?.snapshot?.distance, 0.0);
      expect(repository.taskEntries[entry.id]?.snapshot?.activityCount, 0);
    });
  });

  group("Task Snapshot Healing - Import", () {
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

    test("importing entries with stale snapshots heals them against local Strava data", () async {
      // Local Strava data already exists: one 100km activity on gear "g123".
      // It survives the import (import does not touch Strava tables).
      final activity = StravaActivity(
        id: 1,
        name: "Local Ride",
        athlete: 1,
        sportType: SportType.Ride,
        startDate: DateTime.utc(2024, 1, 1, 12),
        startDateLocal: DateTime(2024, 1, 1, 12),
        gearId: "g123",
        startLat: 0,
        startLon: 0,
        distance: 100000.0, // 100km
        totalElevationGain: 1000.0,
        movingTime: const Duration(hours: 4),
        elapsedTime: const Duration(hours: 5),
      );
      await repository.setStravaActivities([activity]);
      await pumpEventQueue();

      // Build the imported payload: a bike + component + rule + a task entry
      // whose snapshot is STALE (999km — e.g. computed on the source device
      // against different Strava data).
      const bikeId = "bike_1";
      const componentId = "comp_1";
      final bike = Bike(id: bikeId, name: "Imported Bike", person: null, stravaGear: "g123");
      final component = Component(
        id: componentId,
        name: "Chain",
        componentType: ComponentType.chain,
        installations: [Installation.sinceBeginning(parent: bikeId)],
      );
      final rule = TaskRule(name: "Chain Wax", componentId: componentId, tags: const {});
      final entryDate = DateTime.utc(2024, 1, 2);
      final entry = TaskEntry(
        name: "Waxed",
        taskRule: rule.id,
        componentId: componentId,
        dateTimeUTC: entryDate,
        dateTimeLocal: entryDate.toLocal(),
        snapshot: const ComponentStats(
          distance: 999000.0, // stale / foreign value
          elevationGain: 0,
          movingTime: Duration.zero,
          elapsedTime: Duration.zero,
          activityCount: 99,
        ),
      );

      final remoteData = SelectedData(
        bikes: {bike.id: bike},
        components: {component.id: component},
        taskRules: {rule.id: rule},
        taskEntries: {entry.id: entry},
      );

      // Import (replace) writes the entry straight to the DB with its stale snapshot.
      await FileImport.replace(remoteData: remoteData, database: database);
      await pumpEventQueue();

      // Documents the bug: the imported snapshot is stale right after import.
      expect(repository.taskEntries[entry.id]?.snapshot?.distance, 999000.0);

      // The fix: importData() calls this after a successful import.
      await repository.refreshTaskEntrySnapshots();
      await pumpEventQueue();

      // Healed to the local stats (100km, 1 activity).
      expect(repository.taskEntries[entry.id]?.snapshot?.distance, 100000.0);
      expect(repository.taskEntries[entry.id]?.snapshot?.activityCount, 1);
    });

    test("trashed entries are healed too, and stay trashed", () async {
      final bike = Bike(name: "Test Bike", person: null, stravaGear: "g123");
      await repository.addBike(bike);
      final component = Component(
        name: "Chain",
        componentType: ComponentType.chain,
        installations: [Installation.sinceBeginning(parent: bike.id)],
      );
      await repository.addComponent(component);
      final rule = TaskRule(name: "Chain Wax", componentId: component.id, tags: const {});
      await repository.addTaskRule(rule);

      final activity = StravaActivity(
        id: 1,
        name: "Local Ride",
        athlete: 1,
        sportType: SportType.Ride,
        startDate: DateTime.utc(2024, 1, 1, 12),
        startDateLocal: DateTime(2024, 1, 1, 12),
        gearId: "g123",
        startLat: 0,
        startLon: 0,
        distance: 100000.0,
        totalElevationGain: 1000.0,
        movingTime: const Duration(hours: 4),
        elapsedTime: const Duration(hours: 5),
      );
      await repository.setStravaActivities([activity]);
      await pumpEventQueue();

      // A deleted (trashed) entry with a stale snapshot, written directly to the DB.
      final entryDate = DateTime.utc(2024, 1, 2);
      final trashedEntry = TaskEntry(
        name: "Waxed",
        taskRule: rule.id,
        componentId: component.id,
        dateTimeUTC: entryDate,
        dateTimeLocal: entryDate.toLocal(),
        isDeleted: true,
        snapshot: const ComponentStats(
          distance: 999000.0,
          elevationGain: 0,
          movingTime: Duration.zero,
          elapsedTime: Duration.zero,
          activityCount: 99,
        ),
      );
      await database.taskDao.insertEntry(trashedEntry.toCompanion());
      await pumpEventQueue();

      await repository.refreshTaskEntrySnapshots();

      // Read back from the DB (the in-memory cache omits trashed entries).
      final healed = (await database.taskDao.getAllEntriesBypass())
          .firstWhere((e) => e.id == trashedEntry.id);
      expect(healed.isDeleted, isTrue); // still trashed
      expect(healed.snapshot, isNotNull);
      expect(healed.toModel().snapshot?.distance, 100000.0); // healed
    });

    test("importing entries with broken component links succeeds with zero stats", () async {
      // Import data with a task entry that references a non-existent component.
      // This can happen when components are deleted but task entries survive.
      const taskRuleId = "rule_1";
      const componentId = "nonexistent_comp";
      final entryDate = DateTime.utc(2024, 1, 2);

      final entry = TaskEntry(
        name: "Task for missing component",
        taskRule: taskRuleId,
        componentId: componentId,
        dateTimeUTC: entryDate,
        dateTimeLocal: entryDate.toLocal(),
        snapshot: const ComponentStats(
          distance: 500000.0, // stale/foreign value
          elevationGain: 5000.0,
          movingTime: Duration(hours: 20),
          elapsedTime: Duration(hours: 25),
          activityCount: 50,
        ),
      );

      final remoteData = SelectedData(
        taskRules: {taskRuleId: TaskRule(name: "Orphaned Rule", componentId: componentId, tags: const {})},
        taskEntries: {entry.id: entry},
      );

      // Import should succeed without crashing ("Bad state: no element").
      await FileImport.replace(remoteData: remoteData, database: database);
      await pumpEventQueue();

      // After import, refreshing snapshots should not crash and should default to zero.
      await repository.refreshTaskEntrySnapshots();
      await pumpEventQueue();

      // The entry should be in the DB with zero stats (since component doesn't exist).
      final dbEntries = await database.taskDao.getAllEntriesBypass();
      final importedEntry = dbEntries.firstWhere((e) => e.id == entry.id).toModel();
      expect(importedEntry.snapshot, isNotNull);
      expect(importedEntry.snapshot!.distance, 0.0);
      expect(importedEntry.snapshot!.elevationGain, 0.0);
      expect(importedEntry.snapshot!.activityCount, 0);
    });
  });
}
