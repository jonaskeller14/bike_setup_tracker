import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/selected_data.dart';
import 'package:bike_setup_tracker/utils/file_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.memory();
  });

  tearDown(() async {
    await database.close();
  });

  Person createPerson({required String id, required String name, DateTime? lastModified, bool? isDeleted}) {
    return Person(
      id: id,
      name: name,
      lastModified: lastModified,
      isDeleted: isDeleted,
    );
  }

  Bike createBike({required String id, required String name, String? person, DateTime? lastModified, bool? isDeleted}) {
    return Bike(
      id: id,
      name: name,
      person: person,
      lastModified: lastModified,
      isDeleted: isDeleted,
    );
  }

  Component createComponent({required String id, required String name, DateTime? lastModified, bool? isDeleted}) {
    return Component(
      id: id,
      name: name,
      lastModified: lastModified,
      isDeleted: isDeleted,
      componentType: ComponentType.other,
      installations: [],
    );
  }

  group('FileImport Tests', () {
    test('replace - clears local state and replaces with remote', () async {
      // 1. Setup local data
      final localPerson = createPerson(id: 'p1', name: 'Local Person');
      final localBike = createBike(id: 'b1', name: 'Local Bike', person: 'p1');
      final localComponent = createComponent(id: 'c1', name: 'Local Component');
      
      await database.into(database.persons).insert(localPerson.toCompanion());
      await database.into(database.bikes).insert(localBike.toCompanion());
      await database.into(database.components).insert(localComponent.toCompanion());

      // 2. Mock remote data
      final remotePerson = createPerson(id: 'p2', name: 'Remote Person');
      final remoteData = SelectedData(
        persons: {'p2': remotePerson},
        bikes: {},
        components: {},
      );

      // 3. Perform replace
      await FileImport.replace(remoteData: remoteData, database: database);

      // 4. Verify
      final personsInDb = await database.select(database.persons).get();
      final bikesInDb = await database.select(database.bikes).get();
      final componentsInDb = await database.select(database.components).get();

      expect(personsInDb, hasLength(1));
      expect(personsInDb.first.name, 'Remote Person');
      expect(bikesInDb, isEmpty);
      expect(componentsInDb, isEmpty);
    });

    test('overwrite - replaces existing items by ID but keeps unique local items', () async {
      final now = DateTime.now().toUtc();
      final older = now.subtract(const Duration(hours: 1));

      // 1. Setup local data
      final localBike1 = createBike(id: 'b1', name: 'Local Bike 1', person: null, lastModified: now);
      final localBike2 = createBike(id: 'b2', name: 'Local Bike 2', person: null, lastModified: now);
      final localComp1 = createComponent(id: 'c1', name: 'Local Comp 1', lastModified: now);
      
      await database.into(database.bikes).insert(localBike1.toCompanion());
      await database.into(database.bikes).insert(localBike2.toCompanion());
      await database.into(database.components).insert(localComp1.toCompanion());

      // 2. Mock remote data
      // Bike 1: Overlapping ID, older lastModified but should still overwrite
      final remoteBike1 = createBike(id: 'b1', name: 'Remote Bike 1', person: null, lastModified: older);
      // Comp 1: Overlapping ID, older lastModified but should still overwrite
      final remoteComp1 = createComponent(id: 'c1', name: 'Remote Comp 1', lastModified: older);
      // Bike 3: New unique ID
      final remoteBike3 = createBike(id: 'b3', name: 'Remote Bike 3', person: null, lastModified: now);
      
      final remoteData = SelectedData(
        bikes: {'b1': remoteBike1, 'b3': remoteBike3},
        components: {'c1': remoteComp1},
      );

      // 3. Perform overwrite
      await FileImport.overwrite(remoteData: remoteData, database: database);

      // 4. Verify
      final bikesInDb = await database.select(database.bikes).get();
      expect(bikesInDb, hasLength(3));
      
      final bike1 = bikesInDb.firstWhere((b) => b.id == 'b1');
      final bike2 = bikesInDb.firstWhere((b) => b.id == 'b2');
      final bike3 = bikesInDb.firstWhere((b) => b.id == 'b3');

      expect(bike1.name, 'Remote Bike 1'); // Overwritten
      expect(bike2.name, 'Local Bike 2');  // Preserved
      expect(bike3.name, 'Remote Bike 3'); // Added

      final componentsInDb = await database.select(database.components).get();
      expect(componentsInDb, hasLength(1));
      expect(componentsInDb.first.name, 'Remote Comp 1'); // Overwritten
    });

    test('merge - keeps the newest items based on lastModified', () async {
      final now = DateTime.now().toUtc();
      final older = now.subtract(const Duration(hours: 1));

      // 1. Setup local data
      // Bike 1: Newer than remote
      final localBike1 = createBike(id: 'b1', name: 'Local Bike 1 Newer', person: null, lastModified: now);
      // Bike 2: Older than remote
      final localBike2 = createBike(id: 'b2', name: 'Local Bike 2 Older', person: null, lastModified: older);
      
      await database.into(database.bikes).insert(localBike1.toCompanion());
      await database.into(database.bikes).insert(localBike2.toCompanion());

      // 2. Mock remote data
      final remoteBike1 = createBike(id: 'b1', name: 'Remote Bike 1 Older', person: null, lastModified: older);
      final remoteBike2 = createBike(id: 'b2', name: 'Remote Bike 2 Newer', person: null, lastModified: now);
      final remoteBike3 = createBike(id: 'b3', name: 'Remote Bike 3 New', person: null, lastModified: now);
      
      final remoteData = SelectedData(
        bikes: {'b1': remoteBike1, 'b2': remoteBike2, 'b3': remoteBike3},
      );

      // 3. Perform merge
      await FileImport.merge(remoteData: remoteData, database: database);

      // 4. Verify
      final bikesInDb = await database.select(database.bikes).get();
      expect(bikesInDb, hasLength(3));
      
      final bike1 = bikesInDb.firstWhere((b) => b.id == 'b1');
      final bike2 = bikesInDb.firstWhere((b) => b.id == 'b2');
      final bike3 = bikesInDb.firstWhere((b) => b.id == 'b3');

      expect(bike1.name, 'Local Bike 1 Newer'); // Local wins
      expect(bike2.name, 'Remote Bike 2 Newer'); // Remote wins
      expect(bike3.name, 'Remote Bike 3 New');   // Added
    });

    test('cleanupIsDeleted - removes items deleted > 30 days ago', () async {
      final oldDate = DateTime.now().toUtc().subtract(const Duration(days: 31));
      final recentDate = DateTime.now().toUtc().subtract(const Duration(days: 1));

      // 1. Setup local data
      final oldDeletedBike = createBike(id: 'old', name: 'Old Deleted', person: null, lastModified: oldDate, isDeleted: true);
      final recentDeletedBike = createBike(id: 'recent', name: 'Recent Deleted', person: null, lastModified: recentDate, isDeleted: true);
      
      await database.into(database.bikes).insert(oldDeletedBike.toCompanion());
      await database.into(database.bikes).insert(recentDeletedBike.toCompanion());

      // 2. Perform merge (which calls cleanupIsDeleted)
      await FileImport.merge(remoteData: SelectedData(), database: database);

      // 3. Verify
      final bikesInDb = await database.select(database.bikes).get();
      expect(bikesInDb, hasLength(1));
      expect(bikesInDb.first.id, 'recent');
    });
  });
}
