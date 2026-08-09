import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Strava activity search', () {
    late AppDatabase database;

    setUp(() async {
      database = AppDatabase.memory();
      await database.into(database.stravaActivities).insert(_activity(1, 'Ride b a'));
      await database.into(database.stravaActivities).insert(_activity(2, 'Ride a only'));
      await database.into(database.stravaActivities).insert(_activity(3, 'Morning ride'));
    });

    tearDown(() => database.close());

    test('matches every token regardless of order', () async {
      final results = await database.stravaDao.searchActivitiesByName('a b');

      expect(results.map((activity) => activity.id), [1]);
    });

    test('is case-insensitive and ignores repeated whitespace', () async {
      final results = await database.stravaDao.searchActivitiesByName('  MORNING   RIDE ');

      expect(results.map((activity) => activity.id), [3]);
    });
  });
}

StravaActivityDb _activity(int id, String name) => StravaActivityDb(
  id: id,
  lastModified: DateTime.utc(2024),
  name: name,
  athlete: 1,
  sportType: SportType.Ride,
  startDate: DateTime.utc(2024),
  startDateLocal: DateTime(2024),
  movingTime: 3600,
  elapsedTime: 3600,
);
