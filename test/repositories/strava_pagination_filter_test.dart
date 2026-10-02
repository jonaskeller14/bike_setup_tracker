import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/filters/activity_filter.dart';
import 'package:bike_setup_tracker/models/filters/local_date_range.dart';
import 'package:bike_setup_tracker/models/filters/numeric_range.dart';
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

    StravaActivity activity(
      int id,
      DateTime date,
      String? gearId, {
      double? distance,
      double? elevationGain,
      bool positioned = false,
    }) {
      return StravaActivity(
        id: id,
        name: "Activity $id",
        athlete: 1,
        sportType: SportType.Ride,
        startDate: date.toUtc(),
        startDateLocal: date,
        gearId: gearId,
        startLat: positioned ? 44 : null,
        startLon: positioned ? 8 : null,
        distance: distance,
        totalElevationGain: elevationGain,
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

      await repository.addBikes([bikeOld, bikeNew]);

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

      repository.filters.toggleBike(bikeOld.id);
      await pumpEventQueue();

      // The previous global-then-filter pagination returned empty here.
      expect(repository.stravaActivities.length, 1);
      expect(repository.stravaActivities.containsKey(1), true);
    });

    test("Toggling the sort order keeps the bike's activity visible (the reported bug)", () async {
      repository.filters.toggleBike(bikeOld.id);
      await pumpEventQueue();
      expect(repository.stravaActivities.containsKey(1), true);

      await repository.setStravaSortOrder(true); // ascending
      await pumpEventQueue();
      expect(repository.stravaActivities.containsKey(1), true);

      await repository.setStravaSortOrder(false); // back to descending
      await pumpEventQueue();
      expect(repository.stravaActivities.containsKey(1), true);
    });

    test("Pagination walks only the selected bike's activities", () async {
      repository.filters.toggleBike(bikeNew.id);
      await pumpEventQueue();

      // First page (limit 2) of bikeNew's 5 activities.
      expect(repository.stravaActivities.length, 2);
      expect(repository.hasMoreStrava, true);
      expect(repository.stravaActivities.values.every((a) => a.gearId == "gear_new"), true);

      await repository.loadMoreStravaActivities();
      await pumpEventQueue();
      expect(repository.stravaActivities.length, 4);

      await repository.loadMoreStravaActivities();
      await pumpEventQueue();
      expect(repository.stravaActivities.length, 5);
      expect(repository.hasMoreStrava, false);
      // The other bike's activity never leaks into the filtered window.
      expect(repository.stravaActivities.containsKey(1), false);
    });

    test("Switching bikes re-pages from the top for the new filter", () async {
      repository.filters.toggleBike(bikeNew.id);
      await pumpEventQueue();
      expect(repository.stravaActivities.values.every((a) => a.gearId == "gear_new"), true);
      expect(repository.stravaActivities.containsKey(1), false);

      repository.filters.toggleBike(bikeOld.id);
      await pumpEventQueue();
      expect(repository.stravaActivities.length, 1);
      expect(repository.stravaActivities.containsKey(1), true);
    });

    test("Results of a superseded selection are dropped", () async {
      // Both loads are in flight at once; only the last selection may land.
      repository.filters.toggleBike(bikeNew.id);
      repository.filters.toggleBike(bikeOld.id);
      await pumpEventQueue();

      expect(repository.stravaActivities.keys, [1]);
      expect(repository.hasMoreStrava, false);
    });

    group("activity ranges", () {
      ActivityFilter distance({double? min, double? max}) =>
          ActivityFilter(distance: NumericRange(min: min, max: max));

      setUp(() async {
        // Activity 6 keeps no distance and no elevation gain.
        await repository.setStravaActivities([
          activity(1, DateTime(2023, 1, 1), "gear_old", distance: 40000, elevationGain: 900, positioned: true),
          activity(2, DateTime(2023, 2, 1), "gear_new", distance: 10000, elevationGain: 100, positioned: true),
          activity(3, DateTime(2023, 2, 2), "gear_new", distance: 20000, elevationGain: 300, positioned: true),
          activity(4, DateTime(2023, 2, 3), "gear_new", distance: 30000, elevationGain: 500, positioned: true),
          activity(5, DateTime(2023, 2, 4), "gear_new", distance: 40000, elevationGain: 700, positioned: true),
        ]);
        await pumpEventQueue();
      });

      test("Pagination walks only the activities in the distance range", () async {
        repository.filters.activity = distance(min: 20000);
        await pumpEventQueue();

        expect(repository.stravaActivities.keys, [5, 4]);
        expect(repository.hasMoreStrava, true);

        await repository.loadMoreStravaActivities();
        await pumpEventQueue();
        expect(repository.stravaActivities.keys, [5, 4, 3, 1]);

        await repository.loadMoreStravaActivities();
        await pumpEventQueue();
        expect(repository.stravaActivities.keys, [5, 4, 3, 1]);
        expect(repository.hasMoreStrava, false);
      });

      test("Pagination walks only the activities in the elevation gain range", () async {
        repository.filters.activity = const ActivityFilter(elevationGain: NumericRange(min: 300, max: 700));
        await pumpEventQueue();
        await repository.loadMoreStravaActivities();
        await pumpEventQueue();

        expect(repository.stravaActivities.keys, [5, 4, 3]);
        expect(repository.hasMoreStrava, false);
      });

      test("An activity without a value is hidden while its range is active", () async {
        repository.debugSetStravaLimit(10);
        await repository.initialStravaLoad();
        expect(repository.stravaActivities.containsKey(6), true);

        repository.filters.activity = distance(max: 100000);
        await pumpEventQueue();
        expect(repository.stravaActivities.keys, [5, 4, 3, 2, 1]);

        repository.filters.activity = const ActivityFilter(elevationGain: NumericRange(max: 10000));
        await pumpEventQueue();
        expect(repository.stravaActivities.keys, [5, 4, 3, 2, 1]);
      });

      test("Changing a range re-pages from the top", () async {
        repository.filters.activity = distance(min: 20000);
        await pumpEventQueue();
        await repository.loadMoreStravaActivities();
        await pumpEventQueue();
        expect(repository.stravaActivities.length, 4);

        repository.filters.activity = distance(min: 40000);
        await pumpEventQueue();
        expect(repository.stravaActivities.keys, [5, 1]);

        repository.filters.activity = const ActivityFilter();
        await pumpEventQueue();
        expect(repository.stravaActivities.keys, [6, 5]);
        expect(repository.hasMoreStrava, true);
      });

      test("A range narrows within the selected bike's activities", () async {
        repository.filters.toggleBike(bikeNew.id);
        repository.filters.activity = distance(min: 20000);
        await pumpEventQueue();
        await repository.loadMoreStravaActivities();
        await pumpEventQueue();

        // Activity 1 is in range but belongs to the other bike.
        expect(repository.stravaActivities.keys, [5, 4, 3]);
        expect(repository.hasMoreStrava, false);
      });

      test("Results of a superseded range are dropped", () async {
        repository.filters.activity = distance(min: 20000);
        repository.filters.activity = distance(min: 40000);
        await pumpEventQueue();

        expect(repository.stravaActivities.keys, [5, 1]);
      });

      test("Map positions and search follow the ranges", () async {
        repository.filters.activity = distance(min: 30000);
        await pumpEventQueue();

        expect((await repository.getFilteredStravaActivitiesWithPosition()).map((a) => a.id), [5, 4, 1]);
        expect((await repository.searchStravaActivities("Activity")).map((a) => a.id), unorderedEquals([1, 4, 5]));
      });
    });

    group("date range", () {
      LocalDateRange february({required int from, required int to}) =>
          LocalDateRange(start: DateTime(2023, 2, from), end: DateTime(2023, 2, to));

      test("Pagination walks only the activities in the date range", () async {
        repository.filters.dateRange = february(from: 2, to: 4);
        await pumpEventQueue();

        expect(repository.stravaActivities.keys, [5, 4]);
        expect(repository.hasMoreStrava, true);

        await repository.loadMoreStravaActivities();
        await pumpEventQueue();
        expect(repository.stravaActivities.keys, [5, 4, 3]);
        expect(repository.hasMoreStrava, false);
      });

      test("A range that ends on a full page still ends with hasMore == false", () async {
        repository.filters.dateRange = february(from: 1, to: 4);
        await pumpEventQueue();
        await repository.loadMoreStravaActivities();
        await pumpEventQueue();
        expect(repository.stravaActivities.keys, [5, 4, 3, 2]);
        expect(repository.hasMoreStrava, true);

        await repository.loadMoreStravaActivities();
        await pumpEventQueue();
        expect(repository.stravaActivities.keys, [5, 4, 3, 2]);
        expect(repository.hasMoreStrava, false);
      });

      test("Changing or clearing the range re-pages from the top", () async {
        repository.filters.dateRange = february(from: 1, to: 5);
        await pumpEventQueue();
        await repository.loadMoreStravaActivities();
        await pumpEventQueue();
        expect(repository.stravaActivities.length, 4);

        repository.filters.dateRange = february(from: 1, to: 2);
        await pumpEventQueue();
        expect(repository.stravaActivities.keys, [3, 2]);

        repository.filters.dateRange = LocalDateRange(start: DateTime(2023, 1, 1), end: DateTime(2023, 1, 1));
        await pumpEventQueue();
        expect(repository.stravaActivities.keys, [1]);
        expect(repository.hasMoreStrava, false);

        repository.filters.dateRange = null;
        await pumpEventQueue();
        expect(repository.stravaActivities.keys, [6, 5]);
        expect(repository.hasMoreStrava, true);
      });

      test("A range without activities gives an empty window", () async {
        repository.filters.dateRange = LocalDateRange(start: DateTime(2022), end: DateTime(2022, 12, 31));
        await pumpEventQueue();

        expect(repository.stravaActivities, isEmpty);
        expect(repository.hasMoreStrava, false);
      });

      test("Results of a superseded range are dropped", () async {
        repository.filters.dateRange = february(from: 4, to: 5);
        repository.filters.dateRange = february(from: 1, to: 2);
        await pumpEventQueue();

        expect(repository.stravaActivities.keys, [3, 2]);
      });

      test("A range narrows within the selected bike and the activity ranges", () async {
        await repository.setStravaActivities([
          activity(1, DateTime(2023, 1, 1), "gear_old", distance: 40000),
          activity(2, DateTime(2023, 2, 1), "gear_new", distance: 10000),
          activity(3, DateTime(2023, 2, 2), "gear_new", distance: 20000),
          activity(4, DateTime(2023, 2, 3), "gear_new", distance: 30000),
          activity(5, DateTime(2023, 2, 4), "gear_new", distance: 40000),
          activity(7, DateTime(2023, 2, 3), "gear_old", distance: 30000),
        ]);
        await pumpEventQueue();

        repository.filters.toggleBike(bikeNew.id);
        repository.filters.activity = const ActivityFilter(distance: NumericRange(min: 20000));
        repository.filters.dateRange = february(from: 1, to: 3);
        await pumpEventQueue();
        await repository.loadMoreStravaActivities();
        await pumpEventQueue();

        // 2 is too short, 5 too late and 7 on the other bike.
        expect(repository.stravaActivities.keys, [4, 3]);
        expect(repository.hasMoreStrava, false);
      });

      test("Map positions and search follow the date range", () async {
        await repository.setStravaActivities([
          for (var day = 1; day <= 5; day++) activity(day + 1, DateTime(2023, 2, day), "gear_new", positioned: true),
        ]);
        await pumpEventQueue();

        repository.filters.dateRange = february(from: 2, to: 3);
        await pumpEventQueue();

        expect((await repository.getFilteredStravaActivitiesWithPosition()).map((a) => a.id), [4, 3]);
        expect((await repository.searchStravaActivities("Activity")).map((a) => a.id), unorderedEquals([3, 4]));
      });
    });
  });
}
