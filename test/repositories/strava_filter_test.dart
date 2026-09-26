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
      await repository.addBikes([bikeLinked, bikeUnlinked, bikeOtherUnlinked]);
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

    test("Filtering with an unlinked bike selected should show no activities", () async {
      repository.onBikeTap(bikeUnlinked.id);
      await pumpEventQueue();

      // Ride 2 (null gear) and Ride 3 (gear_unknown) are unattributed, not this
      // bike's rides: its stats count neither, so its list shows neither.
      expect(repository.filteredStravaActivities, isEmpty);
      expect(repository.selectedBikeHasNoStravaGear, true);
    });

    test("Every unlinked bike shows nothing rather than a shared unassigned pool", () async {
      repository.onBikeTap(bikeOtherUnlinked.id);
      await pumpEventQueue();
      expect(repository.filteredStravaActivities, isEmpty);
      expect(repository.selectedBikeHasNoStravaGear, true);
    });

    test("Deselecting an unlinked bike brings every activity back", () async {
      repository.onBikeTap(bikeUnlinked.id);
      await pumpEventQueue();
      expect(repository.filteredStravaActivities, isEmpty);

      repository.onBikeTap(bikeUnlinked.id); // tapping again clears the selection
      await pumpEventQueue();
      expect(repository.selectedBike, null);
      expect(repository.filteredStravaActivities.length, 3);
      expect(repository.selectedBikeHasNoStravaGear, false);
    });

    test("A linked bike is not reported as missing its gear", () async {
      repository.onBikeTap(bikeLinked.id);
      await pumpEventQueue();
      expect(repository.selectedBikeHasNoStravaGear, false);
    });

    test("Search and map positions follow the same scope as the list", () async {
      repository.onBikeTap(bikeUnlinked.id);
      await pumpEventQueue();

      expect(await repository.searchStravaActivities("Ride"), isEmpty);
      expect(await repository.getFilteredStravaActivitiesWithPosition(), isEmpty);
    });
  });
}
