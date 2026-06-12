import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

void main() {
  group("AppRepository - Strava Filtering", () {
    late AppDatabase database;
    late AppRepository repository;

    final bikeLinked = Bike(name: "Linked Bike", person: null, stravaGear: "gear_1");
    final bikeUnlinked = Bike(name: "Unlinked Bike", person: null, stravaGear: null);
    final bikeOtherUnlinked = Bike(name: "Other Unlinked Bike", person: null, stravaGear: null);

    final activityLinked = StravaActivity(
      id: 1,
      name: "Ride 1",
      athlete: 1,
      sportType: SportType.Ride,
      startDate: DateTime(2023, 1, 1).toUtc(),
      startDateLocal: DateTime(2023, 1, 1).toLocal(),
      gearId: "gear_1",
      startLat: null,
      startLon: null,
      distance: null,
      totalElevationGain: null,
      movingTime: Duration.zero,
      elapsedTime: Duration.zero,
    );

    final activityUnlinked = StravaActivity(
      id: 2,
      name: "Ride 2",
      athlete: 1,
      sportType: SportType.Ride,
      startDate: DateTime(2023, 1, 2).toUtc(),
      startDateLocal: DateTime(2023, 1, 2).toLocal(),
      gearId: null, // No gear assigned in Strava
      startLat: null,
      startLon: null,
      distance: null,
      totalElevationGain: null,
      movingTime: Duration.zero,
      elapsedTime: Duration.zero,
    );

    final activityUnknownGear = StravaActivity(
      id: 3,
      name: "Ride 3",
      athlete: 1,
      sportType: SportType.Ride,
      startDate: DateTime(2023, 1, 3).toUtc(),
      startDateLocal: DateTime(2023, 1, 3).toLocal(),
      gearId: "gear_unknown", // Gear assigned in Strava but not linked to any bike in app
      startLat: null,
      startLon: null,
      distance: null,
      totalElevationGain: null,
      movingTime: Duration.zero,
      elapsedTime: Duration.zero,
    );

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      
      // Load data into DB
      await repository.addBike(bikeLinked);
      await repository.addBike(bikeUnlinked);
      await repository.addBike(bikeOtherUnlinked);
      await repository.setStravaActivities([activityLinked, activityUnlinked, activityUnknownGear]);
      
      await pumpEventQueue();
    });

    tearDown(() async {
      await database.close();
    });

    test("Filtering with no bike selected should show all activities", () {
      expect(repository.selectedBike, null);
      expect(repository.filteredStravaActivities.length, 3);
    });

    test("Filtering with a linked bike selected should show only its activities", () async {
      repository.onBikeTap(bikeLinked.id);
      await pumpEventQueue(); // selection re-pages Strava at the DB level
      expect(repository.filteredStravaActivities.length, 1);
      expect(repository.filteredStravaActivities.containsKey(activityLinked.id), true);
    });

    test("Filtering with an unlinked bike selected should show unassigned activities", () async {
      // Selecting the first unlinked bike
      repository.onBikeTap(bikeUnlinked.id);
      await pumpEventQueue();

      // Should show Ride 2 (null gear) and Ride 3 (gear_unknown)
      // because they are not assigned to any bike.
      // This verifies the user's fix for Ride 2 (null gear).
      expect(repository.filteredStravaActivities.length, 2);
      expect(repository.filteredStravaActivities.containsKey(activityUnlinked.id), true);
      expect(repository.filteredStravaActivities.containsKey(activityUnknownGear.id), true);
    });

    test("Filtering with another unlinked bike should show the same unassigned pool", () async {
      repository.onBikeTap(bikeOtherUnlinked.id);
      await pumpEventQueue();
      expect(repository.filteredStravaActivities.length, 2);
      expect(repository.filteredStravaActivities.containsKey(activityUnlinked.id), true);
      expect(repository.filteredStravaActivities.containsKey(activityUnknownGear.id), true);
    });
  });
}
