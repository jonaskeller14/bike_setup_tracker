import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Strava activity search', () {
    late AppDatabase database;

    setUp(() async {
      database = AppDatabase.memory();
      await database.into(database.stravaActivities).insert(_activity(1, 'Ride b a', gearId: 'g1'));
      await database.into(database.stravaActivities).insert(_activity(2, 'Ride a only', gearId: 'g2'));
      await database.into(database.stravaActivities).insert(_activity(3, 'Morning ride'));
    });

    tearDown(() => database.close());

    test('matches every token regardless of order', () async {
      final results = await database.stravaDao.searchActivitiesByName('a b', const StravaActivityQuery());

      expect(results.map((activity) => activity.id), [1]);
    });

    test('is case-insensitive and ignores repeated whitespace', () async {
      final results = await database.stravaDao.searchActivitiesByName(
        '  MORNING   RIDE ',
        const StravaActivityQuery(),
      );

      expect(results.map((activity) => activity.id), [3]);
    });

    test('narrows the matches to the gear of the query', () async {
      final results = await database.stravaDao.searchActivitiesByName('ride', const StravaActivityQuery(gearId: 'g2'));

      expect(results.map((activity) => activity.id), [2]);
    });

    test('an empty text returns every activity of the gear', () async {
      final results = await database.stravaDao.searchActivitiesByName('', const StravaActivityQuery(gearId: 'g1'));

      expect(results.map((activity) => activity.id), [1]);
    });
  });

  group('Strava activities with position', () {
    late AppDatabase database;

    setUp(() async {
      database = AppDatabase.memory();
      await database.into(database.stravaActivities).insert(_activity(1, 'Old', day: 1, gearId: 'g1', lat: 44, lon: 8));
      await database.into(database.stravaActivities).insert(_activity(2, 'New', day: 3, gearId: 'g1', lat: 45, lon: 9));
      await database.into(database.stravaActivities).insert(_activity(3, 'Other', day: 2, gearId: 'g2', lat: 46, lon: 7));
      await database.into(database.stravaActivities).insert(_activity(4, 'No gear', day: 4, lat: 47, lon: 6));
      await database.into(database.stravaActivities).insert(_activity(5, 'Indoor', day: 5, gearId: 'g1'));
      await database.into(database.stravaActivities).insert(_activity(6, 'Half', day: 6, gearId: 'g1', lat: 44));
    });

    tearDown(() => database.close());

    test('the unscoped query returns every positioned activity, newest first', () async {
      final results = await database.stravaDao.getActivitiesWithPosition(const StravaActivityQuery());

      expect(results.map((activity) => activity.id), [4, 2, 3, 1]);
    });

    test('a gear query returns only the positioned activities of that gear', () async {
      final results = await database.stravaDao.getActivitiesWithPosition(const StravaActivityQuery(gearId: 'g1'));

      expect(results.map((activity) => activity.id), [2, 1]);
    });

    test('a gear without activities returns nothing', () async {
      final results = await database.stravaDao.getActivitiesWithPosition(const StravaActivityQuery(gearId: 'g9'));

      expect(results, isEmpty);
    });

    test('hasActivitiesWithPosition is true once one activity carries both coordinates', () async {
      expect(await database.stravaDao.hasActivitiesWithPosition(), true);
    });

    test('hasActivitiesWithPosition is false when no activity carries both coordinates', () async {
      await database.stravaDao.deleteActivities([1, 2, 3, 4]);

      expect(await database.stravaDao.hasActivitiesWithPosition(), false);
    });
  });
}

StravaActivityDb _activity(int id, String name, {int day = 1, String? gearId, double? lat, double? lon}) =>
    StravaActivityDb(
      id: id,
      lastModified: DateTime.utc(2024),
      name: name,
      athlete: 1,
      sportType: SportType.Ride,
      startDate: DateTime.utc(2024, 1, day),
      startDateLocal: DateTime(2024, 1, day),
      gearId: gearId,
      startLat: lat,
      startLon: lon,
      movingTime: 3600,
      elapsedTime: 3600,
    );
