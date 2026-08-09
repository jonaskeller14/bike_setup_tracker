import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
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

    test('DataExportService.backupDatabaseToJson - subset filters task rules', () async {
      final now = DateTime.now().toUtc();
      await database.into(database.taskRules).insert(TaskRulesCompanion.insert(id: 'rule-1', lastModified: now, name: 'Rule 1'));
      await database.into(database.taskRules).insert(TaskRulesCompanion.insert(id: 'rule-2', lastModified: now, name: 'Rule 2'));

      final subset = SelectedData(taskRules: {'rule-1': (await database.taskDao.getAllRulesBypass()).first.toModel()});
      final backup = await DataExportService.backupDatabaseToJson(database, subset: subset);

      final exportedIds = (backup['taskRules'] as List).map((r) => r['id'] as String).toList();
      expect(exportedIds, equals(['rule-1']));
    });

    test('DataExportService.backupDatabaseToJson - subset filters task entries', () async {
      final now = DateTime.now().toUtc();
      await database.into(database.taskRules).insert(TaskRulesCompanion.insert(id: 'rule-1', lastModified: now, name: 'Rule 1'));
      await database.into(database.taskEntries).insert(TaskEntriesCompanion.insert(id: 'entry-1', lastModified: now, name: 'Entry 1', dateTimeUTC: now, dateTimeLocal: now, taskRule: 'rule-1'));
      await database.into(database.taskEntries).insert(TaskEntriesCompanion.insert(id: 'entry-2', lastModified: now, name: 'Entry 2', dateTimeUTC: now, dateTimeLocal: now, taskRule: 'rule-1'));

      final subset = SelectedData(taskEntries: {'entry-1': (await database.taskDao.getAllEntriesBypass()).first.toModel()});
      final backup = await DataExportService.backupDatabaseToJson(database, subset: subset);

      final exportedIds = (backup['taskEntries'] as List).map((e) => e['id'] as String).toList();
      expect(exportedIds, equals(['entry-1']));
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
      final remoteDataJson = <String, dynamic>{
        'persons': <dynamic>[],
        'bikes': <dynamic>[],
        'setups': <dynamic>[],
        'components': <dynamic>[],
        'ratings': <dynamic>[],
        'taskRules': <dynamic>[],
        'taskEntries': <dynamic>[],
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
