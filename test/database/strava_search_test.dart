import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/filters/activity_filter.dart';
import 'package:bike_setup_tracker/models/filters/numeric_range.dart';
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

  group('Strava activity ranges', () {
    late AppDatabase database;

    Future<List<int>> positioned(StravaActivityQuery query) async =>
        (await database.stravaDao.getActivitiesWithPosition(query)).map((activity) => activity.id).toList();

    StravaActivityQuery ranges({String? gearId, NumericRange? distance, NumericRange? elevationGain}) =>
        StravaActivityQuery(
          gearId: gearId,
          activity: ActivityFilter(
            distance: distance ?? const NumericRange(),
            elevationGain: elevationGain ?? const NumericRange(),
          ),
        );

    setUp(() async {
      database = AppDatabase.memory();
      final activities = [
        _activity(1, 'Short ride', day: 1, gearId: 'g1', lat: 44, lon: 8, distance: 5000, elevationGain: 50),
        _activity(2, 'Long ride', day: 2, gearId: 'g1', lat: 44, lon: 8, distance: 60000, elevationGain: 1500),
        _activity(3, 'Other ride', day: 3, gearId: 'g2', lat: 44, lon: 8, distance: 30000, elevationGain: 600),
        _activity(4, 'No distance', day: 4, gearId: 'g1', lat: 44, lon: 8, elevationGain: 800),
        _activity(5, 'No elevation', day: 5, gearId: 'g1', lat: 44, lon: 8, distance: 30000),
      ];
      for (final activity in activities) {
        await database.into(database.stravaActivities).insert(activity);
      }
    });

    tearDown(() => database.close());

    test('open ranges keep every activity, also those without a value', () async {
      expect(await positioned(ranges()), [5, 4, 3, 2, 1]);
    });

    test('a minimum distance is inclusive and hides activities without a distance', () async {
      expect(await positioned(ranges(distance: const NumericRange(min: 30000))), [5, 3, 2]);
    });

    test('a maximum distance is inclusive and hides activities without a distance', () async {
      expect(await positioned(ranges(distance: const NumericRange(max: 30000))), [5, 3, 1]);
    });

    test('a distance range applies both bounds', () async {
      expect(await positioned(ranges(distance: const NumericRange(min: 10000, max: 40000))), [5, 3]);
    });

    test('a minimum elevation gain is inclusive and hides activities without an elevation gain', () async {
      expect(await positioned(ranges(elevationGain: const NumericRange(min: 600))), [4, 3, 2]);
    });

    test('a maximum elevation gain is inclusive and hides activities without an elevation gain', () async {
      expect(await positioned(ranges(elevationGain: const NumericRange(max: 600))), [3, 1]);
    });

    test('distance, elevation gain and gear narrow together', () async {
      final query = ranges(
        gearId: 'g1',
        distance: const NumericRange(min: 10000),
        elevationGain: const NumericRange(max: 2000),
      );

      expect(await positioned(query), [2]);
    });

    test('paging walks only the activities in range', () async {
      final query = ranges(distance: const NumericRange(min: 30000));

      final first = await database.stravaDao.getActivitiesPaginated(limit: 2, offset: 0, query: query);
      final second = await database.stravaDao.getActivitiesPaginated(limit: 2, offset: 2, query: query);

      expect(first.map((activity) => activity.id), [5, 3]);
      expect(second.map((activity) => activity.id), [2]);
    });

    test('search narrows the matches to the ranges', () async {
      final results = await database.stravaDao.searchActivitiesByName(
        'ride',
        ranges(distance: const NumericRange(min: 10000)),
      );

      expect(results.map((activity) => activity.id), unorderedEquals([2, 3]));
    });
  });
}

StravaActivityDb _activity(
  int id,
  String name, {
  int day = 1,
  String? gearId,
  double? lat,
  double? lon,
  double? distance,
  double? elevationGain,
}) =>
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
      distance: distance,
      totalElevationGain: elevationGain,
      movingTime: 3600,
      elapsedTime: 3600,
    );
