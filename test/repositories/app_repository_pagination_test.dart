import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

void main() {
  group("AppRepository - Strava Pagination", () {
    late AppDatabase database;
    late AppRepository repository;

    StravaActivity createActivity(int id, DateTime date) {
      return StravaActivity(
        id: id,
        name: "Activity $id",
        athlete: 1,
        sportType: SportType.Ride,
        startDate: date,
        startDateLocal: date,
        gearId: null,
        startLat: 44.0,
        startLon: 8.0,
        distance: 1000,
        totalElevationGain: 100,
        movingTime: const Duration(minutes: 30),
        elapsedTime: const Duration(minutes: 35),
      );
    }

    setUp(() async {
      database = AppDatabase.memory();
    });

    tearDown(() async {
      await database.close();
    });

    test("Initial load and Load More (Descending)", () async {
      // Insert 5 activities
      for (int i = 1; i <= 5; i++) {
        final activity = createActivity(i, DateTime(2023, 1, i));
        await database.stravaDao.upsertActivity(StravaActivitiesCompanion.insert(
          id: drift.Value(activity.id),
          name: activity.name,
          athlete: activity.athlete,
          sportType: activity.sportType,
          startDate: activity.startDate,
          startDateLocal: activity.startDateLocal,
          movingTime: activity.movingTime.inSeconds,
          elapsedTime: activity.elapsedTime.inSeconds,
          lastModified: activity.lastModified,
          gearId: drift.Value(activity.gearId),
          startLat: drift.Value(activity.startLat),
          startLon: drift.Value(activity.startLon),
          distance: drift.Value(activity.distance),
          totalElevationGain: drift.Value(activity.totalElevationGain),
        ));
      }

      repository = AppRepository(database);
      repository.debugSetStravaLimit(2);
      await repository.initialStravaLoad();
      
      // Note: _stravaLimit is currently 2 in my implementation
      expect(repository.stravaActivities.length, 2);
      
      // Check if they are the newest (ID 5 and 4)
      final activities = repository.stravaActivities.values.toList();
      activities.sort((a, b) => b.startDate.compareTo(a.startDate));
      expect(activities[0].id, 5);
      expect(activities[1].id, 4);

      // Load more
      await repository.loadMoreStravaActivities();
      await pumpEventQueue();
      
      expect(repository.stravaActivities.length, 4);
      expect(repository.stravaActivities.containsKey(3), true);
      expect(repository.stravaActivities.containsKey(2), true);

      // Load more (last one)
      await repository.loadMoreStravaActivities();
      await pumpEventQueue();
      expect(repository.stravaActivities.length, 5);
      expect(repository.stravaActivities.containsKey(1), true);
      expect(repository.isLoadingMoreStrava, false);
    });

    test("Sort Order Change (Ascending)", () async {
      // Insert 3 activities
      for (int i = 1; i <= 3; i++) {
        final activity = createActivity(i, DateTime(2023, 1, i));
        await database.stravaDao.upsertActivity(StravaActivitiesCompanion.insert(
          id: drift.Value(activity.id),
          name: activity.name,
          athlete: activity.athlete,
          sportType: activity.sportType,
          startDate: activity.startDate,
          startDateLocal: activity.startDateLocal,
          movingTime: activity.movingTime.inSeconds,
          elapsedTime: activity.elapsedTime.inSeconds,
          lastModified: activity.lastModified,
          gearId: drift.Value(activity.gearId),
          startLat: drift.Value(activity.startLat),
          startLon: drift.Value(activity.startLon),
          distance: drift.Value(activity.distance),
          totalElevationGain: drift.Value(activity.totalElevationGain),
        ));
      }

      repository = AppRepository(database);
      repository.debugSetStravaLimit(2);
      await repository.initialStravaLoad();
      
      expect(repository.stravaSortAscending, false); // Default
      
      // Switch to Ascending
      await repository.setStravaSortOrder(true);
      await pumpEventQueue();
      
      expect(repository.stravaSortAscending, true);
      expect(repository.stravaActivities.length, 2);
      
      // Should be ID 1 and 2 (the oldest)
      final activities = repository.stravaActivities.values.toList();
      activities.sort((a, b) => a.startDate.compareTo(b.startDate));
      expect(activities[0].id, 1);
      expect(activities[1].id, 2);
    });
  });
}
