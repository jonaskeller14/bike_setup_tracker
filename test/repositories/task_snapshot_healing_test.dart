import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/models/task_entry.dart';
import 'package:bike_setup_tracker/models/task_rule.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
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
}
