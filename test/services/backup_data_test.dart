import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/services/data_export_service.dart';
import 'package:bike_setup_tracker/utils/file_import.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.memory();
  });

  tearDown(() async {
    await database.close();
  });

  group('Backup Data Tests', () {
    test('DataExportService.backupDatabaseToJson - Excludes Strava Data', () async {
      // 1. Insert some Strava data
      await database.into(database.stravaAthletes).insert(
        StravaAthletesCompanion.insert(
          id: const Value(123),
          lastModified: DateTime.now().toUtc(),
          gears: {},
        ),
      );
      await database.into(database.stravaGears).insert(
        StravaGearsCompanion.insert(
          id: 'gear1',
          lastModified: DateTime.now().toUtc(),
          name: 'My Bike',
        ),
      );
      await database.into(database.stravaActivities).insert(
        StravaActivitiesCompanion.insert(
          id: const Value(456),
          lastModified: DateTime.now().toUtc(),
          name: 'Morning Ride',
          athlete: 123,
          sportType: SportType.Ride,
          startDate: DateTime.now().toUtc(),
          startDateLocal: DateTime.now(),
          movingTime: 3600,
          elapsedTime: 4000,
        ),
      );

      // 2. Perform backup
      final backup = await DataExportService.backupDatabaseToJson(database);

      // 3. Verify Strava keys are missing
      expect(backup.containsKey('stravaAthletes'), isFalse);
      expect(backup.containsKey('stravaGears'), isFalse);
      expect(backup.containsKey('stravaActivities'), isFalse);
      
      // 4. Verify other keys are present (smoke check)
      expect(backup.containsKey('bikes'), isTrue);
      expect(backup.containsKey('components'), isTrue);
    });

    test('FileImport.merge - Preserves Local Strava Data', () async {
      // 1. Setup local database with Strava data
      await database.into(database.stravaActivities).insert(
        StravaActivitiesCompanion.insert(
          id: const Value(456),
          lastModified: DateTime.now().toUtc(),
          name: 'Local Activity',
          athlete: 123,
          sportType: SportType.Ride,
          startDate: DateTime.now().toUtc(),
          startDateLocal: DateTime.now(),
          movingTime: 3600,
          elapsedTime: 4000,
        ),
      );

      // 2. Mock remote data (missing Strava activities)
      final remoteDataJson = {
        'persons': [],
        'bikes': [],
        'setups': [],
        'components': [],
        'ratings': [],
        'taskRules': [],
        'taskEntries': [],
        // No Strava keys here as they would be in a new backup
      };
      final remoteData = SelectedData.fromJson(remoteDataJson);

      // 3. Perform merge
      await FileImport.merge(remoteData: remoteData, database: database);

      // 4. Verify local Strava data is STILL THERE
      final localActivities = await database.stravaDao.getAllActivitiesBypass();
      expect(localActivities, hasLength(1));
      expect(localActivities.first.name, 'Local Activity');
    });
  });
}
