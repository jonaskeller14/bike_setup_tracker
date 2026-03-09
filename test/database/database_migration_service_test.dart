import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_data.dart';
import 'package:bike_setup_tracker/services/database_migration_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DatabaseMigrationService Test', () {
    test('Full Migration from JSON-like AppData', () async {
      final db = AppDatabase.memory();
      final migrationService = DatabaseMigrationService(db);
      
      // We use a separate in-memory DB for AppData if needed, 
      // but AppData.addJson just populates the maps which are then read by migration.
      final sourceAppData = AppData(AppDatabase.memory());
      
      final legacyJson = {
        'persons': [
          {'id': 'p1', 'name': 'Jonas', 'isDeleted': false, 'lastModified': '2023-01-01T00:00:00Z'}
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
               {'version': 1, 'type': 'step', 'id': 'adj1', 'name': 'Rebound', 'category': 'AdjustmentCategory.component', 'min': 0.0, 'max': 10.0, 'step': 1.0, 'visualization': 'slider'}
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
            'bikeAdjustmentValues': {'adj1': 5.0},
            'isDeleted': false,
            'lastModified': '2023-01-01T12:00:00Z'
          }
        ]
      };

      AppData.addJson(data: sourceAppData, json: legacyJson);
      
      await migrationService.migrateFromAppData(sourceAppData);

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

      // Verify Adjustments
      final adjustments = await db.select(db.adjustments).get();
      expect(adjustments, hasLength(1));
      expect(adjustments.first.name, 'Rebound');
      expect(adjustments.first.componentId, 'c1');

      // Verify Setups
      final setups = await db.setupsDao.watchAllSetups().first;
      expect(setups, hasLength(1));
      expect(setups.first.name, 'Dry Trace');

      // Verify Setup Values
      final values = await db.select(db.setupAdjustmentValues).get();
      expect(values, hasLength(1));
      expect(values.first.setupId, 's1');
      expect(values.first.adjustmentId, 'adj1');
      expect(values.first.value, '5.0');
    });
  });
}
