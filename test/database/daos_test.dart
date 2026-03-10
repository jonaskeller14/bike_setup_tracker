import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.memory();
  });

  tearDown(() async {
    await database.close();
  });

  group('DAOs Test', () {
    test('BikesDao - Insert and watch', () async {
      final bikes = await database.bikesDao.watchAllBikes().first;
      expect(bikes, isEmpty);

      final bike = Bike(id: 'bike1', name: 'Mtb', person: null);
      await database.bikesDao.insertBike(bike.toCompanion());

      final updatedBikes = await database.bikesDao.watchAllBikes().first;
      expect(updatedBikes, hasLength(1));
      expect(updatedBikes.first.name, 'Mtb');
    });

    test('ComponentsDao - Insert and watch', () async {
      final components = await database.componentsDao.watchAllComponents().first;
      expect(components, isEmpty);

      final component = Component(
        id: 'comp1', 
        name: 'Fork', 
        componentType: ComponentType.fork,
        adjustments: [],
        installations: [],
      );
      await database.componentsDao.insertComponent(component.toCompanion());

      final updatedComponents = await database.componentsDao.watchAllComponents().first;
      expect(updatedComponents, hasLength(1));
      expect(updatedComponents.first.name, 'Fork');
    });

    test('ComponentsDao - Delete (Soft Delete)', () async {
      final component = Component(
        id: 'comp1', 
        name: 'Fork', 
        componentType: ComponentType.fork,
        installations: [],
      );
      await database.componentsDao.insertComponent(component.toCompanion());

      await database.componentsDao.deleteComponent('comp1');

      final activeComponents = await database.componentsDao.watchAllComponents().first;
      expect(activeComponents, isEmpty);

      final deletedComponents = await database.componentsDao.watchDeletedComponents().first;
      expect(deletedComponents, hasLength(1));
      expect(deletedComponents.first.isDeleted, true);
    });

    test('BikesDao - Get bike by ID', () async {
      final bike = Bike(id: 'bike1', name: 'Mtb', person: null);
      await database.bikesDao.insertBike(bike.toCompanion());

      final fetched = await database.bikesDao.getBike('bike1');
      expect(fetched, isNotNull);
      expect(fetched?.name, 'Mtb');

      final nonExistent = await database.bikesDao.getBike('none');
      expect(nonExistent, isNull);
    });
  });
}
