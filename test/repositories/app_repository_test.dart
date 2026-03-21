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
  group("AppRepository - Installations", () {
    late AppDatabase database;
    late AppRepository repository;
    final bike1 = Bike(name: "Bike #1", person: null);
    final bike2 = Bike(name: "Bike #2", person: null);

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      await pumpEventQueue();
    });

    tearDown(() async {
      await database.close();
    });

    test("filteredInstallations excludes sinceBeginning", () async {
      final component = Component(
        name: "C1",
        installations: [
          Installation.sinceBeginning(parent: bike1.id),
          Installation(parent: bike1.id, dateTimeUTC: DateTime(2025).toUtc(), dateTimeLocal: DateTime(2025).toLocal()),
        ],
        componentType: ComponentType.fork,
      );

      await repository.addBike(bike1);
      await repository.addComponent(component);
      await pumpEventQueue();

      expect(repository.filteredInstallations.length, 1);
      expect(repository.filteredInstallations.first.installation.dateTimeUTC, DateTime(2025).toUtc());
    });

    test("filteredInstallations filters by selectedBike", () async {
      final component1 = Component(
        name: "C1",
        installations: [
          Installation(parent: bike1.id, dateTimeUTC: DateTime(2025).toUtc(), dateTimeLocal: DateTime(2025).toLocal()),
        ],
        componentType: ComponentType.fork,
      );
      final component2 = Component(
        name: "C2",
        installations: [
          Installation(parent: bike2.id, dateTimeUTC: DateTime(2025).toUtc(), dateTimeLocal: DateTime(2025).toLocal()),
        ],
        componentType: ComponentType.fork,
      );

      await repository.addBike(bike1);
      await repository.addBike(bike2);
      await repository.addComponent(component1);
      await repository.addComponent(component2);
      await pumpEventQueue();

      expect(repository.filteredInstallations.length, 2);

      repository.onBikeTap(bike1.id);
      await pumpEventQueue();

      expect(repository.filteredInstallations.length, 1);
      expect(repository.filteredInstallations.first.component.name, "C1");
    });

    test("filteredInstallations includes deinstallations for selectedBike", () async {
      final component = Component(
        name: "C1",
        installations: [
          Installation.sinceBeginning(parent: bike1.id),
          // Event 1: move from bike1 to bike2
          Installation(parent: bike2.id, dateTimeUTC: DateTime(2025, 1, 1).toUtc(), dateTimeLocal: DateTime(2025, 1, 1).toLocal()),
          // Event 2: move from bike2 to null (Archive)
          Installation(parent: null, dateTimeUTC: DateTime(2025, 1, 2).toUtc(), dateTimeLocal: DateTime(2025, 1, 2).toLocal()),
        ],
        componentType: ComponentType.fork,
      );

      await repository.addBike(bike1);
      await repository.addBike(bike2);
      await repository.addComponent(component);
      await pumpEventQueue();

      // Without filter: 2 events (sinceBeginning is excluded)
      expect(repository.filteredInstallations.length, 2);

      // Filter by bike1: should see Event 1 (origin is bike1)
      repository.onBikeTap(bike1.id);
      await pumpEventQueue();
      expect(repository.filteredInstallations.length, 1);
      expect(repository.filteredInstallations.first.originParent, bike1.id);
      expect(repository.filteredInstallations.first.installation.parent, bike2.id);

      // Filter by bike2: should see Event 1 (target is bike2) AND Event 2 (origin is bike2)
      repository.onBikeTap(bike2.id); 
      await pumpEventQueue();
      expect(repository.filteredInstallations.length, 2);
      expect(repository.filteredInstallations.any((ci) => ci.originParent == bike1.id && ci.installation.parent == bike2.id), true);
      expect(repository.filteredInstallations.any((ci) => ci.originParent == bike2.id && ci.installation.parent == null), true);
    });
  });
}
