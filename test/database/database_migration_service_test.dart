import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/database_migration_service.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AppDatabase sourceDb;

  // This test intentionally creates two separate databases (target + source).
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  tearDownAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false);

  setUp(() {
    db = AppDatabase.memory();
    sourceDb = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
    await sourceDb.close();
  });

  group('DatabaseMigrationService Test', () {
    test('Full Migration from JSON-like AppRepository', () async {
      final migrationService = DatabaseMigrationService(db);
      
      // We use a separate in-memory DB for AppRepository if needed, 
      // but AppRepository.addJson just populates the maps which are then read by migration.
      final sourceAppData = AppRepository(sourceDb);
      
      final legacyJson = {
        'persons': [
          {
            'id': 'p1', 
            'name': 'Jonas', 
            'isDeleted': false, 
            'lastModified': '2023-01-01T00:00:00Z',
            'adjustments': [
              {'type': 'numerical', 'id': 'adj_p1', 'name': 'Weight', 'unit': 'kg', 'min': 0.0, 'max': 150.0, 'category': 'AdjustmentCategory.body'}
            ]
          }
        ],
        'bikes': [
          {'id': 'b1', 'name': 'Strive', 'person': 'p1', 'isDeleted': false, 'lastModified': '2023-01-01T00:00:00Z'}
        ],
        'components': [
          {
            'id': 'c1', 
            'name': 'Lyrik', 
            'componentType': 'ComponentType.fork', 
            'isDeleted': false, 
            'lastModified': '2023-01-01T00:00:00Z',
            'bike': 'b1', // legacy field for installation
            'adjustments': [
               {'type': 'step', 'id': 'adj1', 'name': 'Rebound', 'category': 'AdjustmentCategory.component', 'min': 0.0, 'max': 10.0, 'step': 1.0, 'visualization': 'slider'},
               {'type': 'boolean', 'id': 'adj2', 'name': 'Lockout', 'category': 'AdjustmentCategory.component'},
               {'type': 'categorical', 'id': 'adj3', 'name': 'Mode', 'category': 'AdjustmentCategory.component', 'options': ['Open', 'Firm', 'Locked']},
               {'type': 'numerical', 'id': 'adj4', 'name': 'Pressure', 'unit': 'psi', 'category': 'AdjustmentCategory.component', 'min': 0.0, 'max': 200.0},
               {'type': 'text', 'id': 'adj5', 'name': 'Note', 'category': 'AdjustmentCategory.component'},
               {'type': 'duration', 'id': 'adj6', 'name': 'Service', 'category': 'AdjustmentCategory.component'}
            ]
          }
        ],
        'ratings': [
          {
            'id': 'r1',
            'name': 'Overall Feel',
            'filter': 'c1',
            'filterType': 'FilterType.component',
            'adjustments': [
              {'type': 'numerical', 'id': 'adj_r1', 'name': 'Grip', 'min': 1.0, 'max': 10.0, 'category': 'AdjustmentCategory.rating'}
            ]
          }
        ],
        'setups': [
          {
            'id': 's1',
            'name': 'Dry Trace',
            'datetime': '2023-01-01T12:00:00Z',
            'datetimeLocal': '2023-01-01T13:00:00Z',
            'bike': 'b1',
            'person': 'p1',
            'tags': ['race'],
            'bikeAdjustmentValues': {
              'adj1': 5.0,
              'adj2': true,
              'adj3': 'Open',
              'adj4': 85.5,
              'adj5': 'Some note',
              'adj6': '01:30:00'
            },
            'personAdjustmentValues': {
              'adj_p1': 75.0
            },
            'ratingAdjustmentValues': {
              'adj_r1': 8.0
            },
            'weather': {
              'currentDateTime': '2023-01-01T12:00:00Z',
              'currentTemperature': 15.5,
              'condition': 'Condition.dry'
            },
            'position': {
              'latitude': 47.6,
              'longitude': 9.4,
              'altitude': 400.0
            },
            'place': {
              'name': 'Leogang',
              'country': 'Austria'
            },
            'isDeleted': false,
            'lastModified': '2023-01-01T12:00:00Z'
          }
        ]
      };

      final selectedData = SelectedData.fromJson(legacyJson);
      
      await migrationService.migrateFromSelectedData(selectedData);

      // Verify Persons
      final persons = await db.personsDao.watchAllPersons().first;
      expect(persons, hasLength(1));
      expect(persons.first.name, 'Jonas');

      // Verify Bikes
      final bikes = await db.bikesDao.watchAllBikes().first;
      expect(bikes, hasLength(1));
      expect(bikes.first.name, 'Strive');
      expect(bikes.first.person, 'p1');

      // Verify Components
      final components = await db.componentsDao.watchAllComponents().first;
      expect(components, hasLength(1));
      expect(components.first.name, 'Lyrik');

      // Verify Adjustments (rating metrics now live in their own table, not here)
      final adjustments = await db.select(db.adjustments).get();
      expect(adjustments, hasLength(7)); // 6 (component) + 1 (person)
      expect(adjustments.any((a) => a.name == 'Rebound'), true);
      expect(adjustments.any((a) => a.name == 'Lockout'), true);
      expect(adjustments.any((a) => a.name == 'Mode'), true);
      expect(adjustments.any((a) => a.name == 'Pressure'), true);
      expect(adjustments.any((a) => a.name == 'Note'), true);
      expect(adjustments.any((a) => a.name == 'Service'), true);
      expect(adjustments.any((a) => a.name == 'Weight'), true);

      // Verify Ratings
      final ratings = await db.ratingsDao.watchAllRatings().first;
      expect(ratings, hasLength(1));
      expect(ratings.first.name, 'Overall Feel');

      // Verify Rating Metrics (migrated into the dedicated rating_metrics table)
      final ratingMetrics = await db.select(db.ratingMetrics).get();
      expect(ratingMetrics, hasLength(1));
      expect(ratingMetrics.first.name, 'Grip');

      // Verify Setups
      final setups = await db.setupsDao.watchAllSetups().first;
      expect(setups, hasLength(1));
      expect(setups.first.name, 'Dry Trace');
      expect(setups.first.datetime.toIso8601String(), '2023-01-01T12:00:00.000Z');
      expect(setups.first.datetimeLocal.toIso8601String(), '2023-01-01T13:00:00.000');
      expect(setups.first.weather?.currentTemperature, 15.5);
      expect(setups.first.position?.latitude, 47.6);
      expect(setups.first.place?.name, 'Leogang');

      // Verify Setup Values (rating answers are no longer stored on setups)
      final values = await db.select(db.setupAdjustmentValues).get();
      expect(values, hasLength(7)); // 6 (bike) + 1 (person)

      // Values are stored JSON-encoded (via encodeAdjustmentValue), the same as
      // the DAO write path — strings are quoted and durations are microseconds.
      final valueMap = {for (var v in values) v.adjustmentId: v.value};
      expect(valueMap['adj1'], '5.0');
      expect(valueMap['adj2'], 'true');
      expect(valueMap['adj3'], '"Open"');
      expect(valueMap['adj4'], '85.5');
      expect(valueMap['adj5'], '"Some note"');
      expect(valueMap['adj6'], '5400000000');
      expect(valueMap['adj_p1'], '75.0');

      sourceAppData.dispose();
    });
  });
}
