import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/rating.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/installation.dart';

/// Allow Drift streams to propagate through subscriptions.
Future<void> pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

void main() {
  group("AppRepository - Bikes", () {
    late AppDatabase database;
    late AppRepository repository;
    final bike1 = Bike(name: "Bike #1", person: null);

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      // Wait for repository to initialize/fetch initial empty state
      await pumpEventQueue();
    });

    tearDown(() async {
      await database.close();
    });

    test("addBike", () async {
      await repository.addBike(bike1);
      await pumpEventQueue();
      
      expect(repository.bikes.containsKey(bike1.id), true);
    });

    test("removeBike (unselected)", () async {
      await repository.addBike(bike1);
      await pumpEventQueue();
      await repository.removeBike(bike1);
      await pumpEventQueue();

      expect(repository.bikes.containsKey(bike1.id), false);
    });

    test("restoreBike", () async {
      await repository.addBike(bike1);
      await pumpEventQueue();
      await repository.removeBike(bike1);
      await pumpEventQueue();
      await repository.restoreBike(bike1);
      await pumpEventQueue();

      expect(repository.bikes.containsKey(bike1.id), true);
    });

    test("removeBike (selected)", () async {
      await repository.addBike(bike1);
      await pumpEventQueue();
      repository.onBikeTap(bike1.id);
      await pumpEventQueue();

      expect(repository.selectedBike == bike1.id, true);

      await repository.removeBike(bike1);
      await pumpEventQueue();

      expect(repository.selectedBike == null, true);
      expect(repository.bikes.containsKey(bike1.id), false);
    });
  });

  group("AppRepository - Components", () {
    late AppDatabase database;
    late AppRepository repository;
    final bike1 = Bike(name: "Bike #1", person: null);
    late Component component1;

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      await pumpEventQueue();
      component1 = Component(
        name: "Component #1", 
        installations: [Installation.sinceBeginning(parent: bike1.id)], 
        componentType: ComponentType.fork, 
        adjustments: []
      );
    });

    tearDown(() async {
      await database.close();
    });

    test("addComponent", () async {
      await repository.addBike(bike1);
      await repository.addComponent(component1);
      await pumpEventQueue();
      
      expect(repository.components.containsKey(component1.id), true);
    });

    test("removeComponents", () async {
      await repository.addBike(bike1);
      await repository.addComponent(component1);
      await pumpEventQueue();
      await repository.removeComponents([component1]);
      await pumpEventQueue();

      expect(repository.components.containsKey(component1.id), false);
    });
  });

  group("AppRepository - Setups", () {
    late AppDatabase database;
    late AppRepository repository;
    final bike1 = Bike(name: "Bike #1", person: null);
    late Setup setup1;

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      await pumpEventQueue();
      setup1 = Setup(
        name: "Setup #1", 
        tags: {},
        datetime: DateTime(2000).toUtc(),
        datetimeLocal: DateTime(2000).toLocal(),
        bike: bike1.id, 
        person: null, 
        bikeAdjustmentValues: {}, 
        personAdjustmentValues: {},
        ratingAdjustmentValues: {},
        isCurrent: true,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test("addSetup", () async {
      await repository.addBike(bike1);
      await repository.addSetup(setup1);
      await pumpEventQueue();
      
      expect(repository.setups.containsKey(setup1.id), true);
    });
  });

  group("AppRepository - Persons", () {
    late AppDatabase database;
    late AppRepository repository;
    final person1 = Person(name: "Person #1", adjustments: []);

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      await pumpEventQueue();
    });

    tearDown(() async {
      await database.close();
    });

    test("addPerson", () async {
      await repository.addPerson(person1);
      await pumpEventQueue();
      
      expect(repository.persons.containsKey(person1.id), true);
    });
  });

  group("AppRepository - Ratings", () {
    late AppDatabase database;
    late AppRepository repository;
    final rating1 = Rating(name: "Rating #1", filterType: FilterType.global, filter: null, adjustments: []);

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      await pumpEventQueue();
    });

    tearDown(() async {
      await database.close();
    });

    test("addRating", () async {
      await repository.addRating(rating1);
      await pumpEventQueue();
      
      expect(repository.ratings.containsKey(rating1.id), true);
    });
  });
}
