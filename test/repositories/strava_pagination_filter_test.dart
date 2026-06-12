import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

void main() {
  // Regression coverage for the per-filter (DAO-level) Strava pagination.
  //
  // Previously activities were paged globally (newest N across all bikes) and
  // then filtered by gear. A bike whose activities fell outside the loaded
  // global page produced an empty list, and because the lazy-load trigger only
  // fires on a rendered Strava entry, it dead-ended — most visibly under the
  // descending sort. Pagination now applies the gear filter in SQL, so a bike's
  // activities always surface regardless of where they sit in the global order.
  group("AppRepository - Strava per-filter pagination", () {
    late AppDatabase database;
    late AppRepository repository;

    final bikeOld = Bike(name: "Old Bike", person: null, stravaGear: "gear_old");
    final bikeNew = Bike(name: "New Bike", person: null, stravaGear: "gear_new");

    StravaActivity activity(int id, DateTime date, String? gearId) {
      return StravaActivity(
        id: id,
        name: "Activity $id",
        athlete: 1,
        sportType: SportType.Ride,
        startDate: date.toUtc(),
        startDateLocal: date,
        gearId: gearId,
        startLat: null,
        startLon: null,
        distance: null,
        totalElevationGain: null,
        movingTime: Duration.zero,
        elapsedTime: Duration.zero,
      );
    }

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      // Small page size so bikeOld's single activity falls behind a full page
      // of bikeNew's newer activities under a descending global ordering.
      repository.debugSetStravaLimit(2);

      await repository.addBike(bikeOld);
      await repository.addBike(bikeNew);

      // bikeOld owns one OLD activity; bikeNew owns several NEWER ones.
      await repository.setStravaActivities([
        activity(1, DateTime(2023, 1, 1), "gear_old"),
        activity(2, DateTime(2023, 2, 1), "gear_new"),
        activity(3, DateTime(2023, 2, 2), "gear_new"),
        activity(4, DateTime(2023, 2, 3), "gear_new"),
        activity(5, DateTime(2023, 2, 4), "gear_new"),
        activity(6, DateTime(2023, 2, 5), "gear_new"),
      ]);
      await pumpEventQueue();
    });

    tearDown(() async {
      await database.close();
    });

    test("DESC: a bike's older activity surfaces despite a full page of newer ones", () async {
      expect(repository.stravaSortAscending, false); // default ordering

      repository.onBikeTap(bikeOld.id);
      await pumpEventQueue();

      // The previous global-then-filter pagination returned empty here.
      expect(repository.filteredStravaActivities.length, 1);
      expect(repository.filteredStravaActivities.containsKey(1), true);
    });

    test("Toggling the sort order keeps the bike's activity visible (the reported bug)", () async {
      repository.onBikeTap(bikeOld.id);
      await pumpEventQueue();
      expect(repository.filteredStravaActivities.containsKey(1), true);

      await repository.setStravaSortOrder(true); // ascending
      await pumpEventQueue();
      expect(repository.filteredStravaActivities.containsKey(1), true);

      await repository.setStravaSortOrder(false); // back to descending
      await pumpEventQueue();
      expect(repository.filteredStravaActivities.containsKey(1), true);
    });

    test("Pagination walks only the selected bike's activities", () async {
      repository.onBikeTap(bikeNew.id);
      await pumpEventQueue();

      // First page (limit 2) of bikeNew's 5 activities.
      expect(repository.filteredStravaActivities.length, 2);
      expect(repository.hasMoreStrava, true);
      expect(repository.filteredStravaActivities.values.every((a) => a.gearId == "gear_new"), true);

      await repository.loadMoreStravaActivities();
      await pumpEventQueue();
      expect(repository.filteredStravaActivities.length, 4);

      await repository.loadMoreStravaActivities();
      await pumpEventQueue();
      expect(repository.filteredStravaActivities.length, 5);
      expect(repository.hasMoreStrava, false);
      // The other bike's activity never leaks into the filtered window.
      expect(repository.filteredStravaActivities.containsKey(1), false);
    });

    test("Switching bikes re-pages from the top for the new filter", () async {
      repository.onBikeTap(bikeNew.id);
      await pumpEventQueue();
      expect(repository.filteredStravaActivities.values.every((a) => a.gearId == "gear_new"), true);
      expect(repository.filteredStravaActivities.containsKey(1), false);

      repository.onBikeTap(bikeOld.id);
      await pumpEventQueue();
      expect(repository.filteredStravaActivities.length, 1);
      expect(repository.filteredStravaActivities.containsKey(1), true);
    });
  });
}
