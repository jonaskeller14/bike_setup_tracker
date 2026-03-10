import 'package:bike_setup_tracker/models/app_data.dart';
import 'package:bike_setup_tracker/models/filtered_data.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/rating.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

/// Allow Drift streams to propagate through subscriptions.
Future<void> pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

void main() {
  group("Deleted Items (Trash)", () {
    late AppDatabase database;
    late AppData data;
    late FilteredData filteredData;
    final bike1 = Bike(name: "Bike #1", person: null);
    final person1 = Person(name: "Person #1", adjustments: []);
    final rating1 = Rating(name: "Rating #1", filterType: FilterType.global, filter: null, adjustments: []);
    late Component component1;
    late Setup setup1;

    setUp(() {
      database = AppDatabase.memory();
      data = AppData(database);
      filteredData = FilteredData(database);
      component1 = Component(
        name: "Component #1",
        installations: [Installation.sinceBeginning(parent: bike1.id)],
        componentType: ComponentType.fork,
        adjustments: [],
      );
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
      data.dispose();
      filteredData.dispose();
      await database.close();
    });

    test("deleted bike appears in deletedBikes, not in bikes", () async {
      await data.addBike(bike1);
      await pumpEventQueue();
      expect(filteredData.bikes.containsKey(bike1.id), true);
      expect(filteredData.deletedBikes.any((b) => b.id == bike1.id), false);

      await data.removeBike(bike1);
      await pumpEventQueue();
      expect(filteredData.bikes.containsKey(bike1.id), false);
      expect(filteredData.deletedBikes.any((b) => b.id == bike1.id), true);
    });

    test("deleted person appears in deletedPersons, not in persons", () async {
      await data.addPerson(person1);
      await pumpEventQueue();
      expect(filteredData.persons.containsKey(person1.id), true);
      expect(filteredData.deletedPersons.any((p) => p.id == person1.id), false);

      await data.removePerson(person1);
      await pumpEventQueue();
      expect(filteredData.persons.containsKey(person1.id), false);
      expect(filteredData.deletedPersons.any((p) => p.id == person1.id), true);
    });

    test("deleted component appears in deletedComponents, not in components", () async {
      await data.addBike(bike1);
      await data.addComponent(component1);
      await pumpEventQueue();
      expect(filteredData.components.containsKey(component1.id), true);
      expect(filteredData.deletedComponents.any((c) => c.id == component1.id), false);

      await data.removeComponents([component1]);
      await pumpEventQueue();
      expect(filteredData.components.containsKey(component1.id), false);
      expect(filteredData.deletedComponents.any((c) => c.id == component1.id), true);
    });

    test("deleted rating appears in deletedRatings, not in ratings", () async {
      await data.addRating(rating1);
      await pumpEventQueue();
      expect(filteredData.ratings.containsKey(rating1.id), true);
      expect(filteredData.deletedRatings.any((r) => r.id == rating1.id), false);

      await data.removeRatings([rating1]);
      await pumpEventQueue();
      expect(filteredData.ratings.containsKey(rating1.id), false);
      expect(filteredData.deletedRatings.any((r) => r.id == rating1.id), true);
    });

    test("deleted setup appears in deletedSetups, not in setups", () async {
      await data.addBike(bike1);
      await data.addSetup(setup1);
      await pumpEventQueue();
      expect(filteredData.setups.containsKey(setup1.id), true);
      expect(filteredData.deletedSetups.any((s) => s.id == setup1.id), false);

      await data.removeSetups([setup1]);
      await pumpEventQueue();
      expect(filteredData.setups.containsKey(setup1.id), false);
      expect(filteredData.deletedSetups.any((s) => s.id == setup1.id), true);
    });

    test("restored item moves back from deleted to active", () async {
      await data.addBike(bike1);
      await data.removeBike(bike1);
      await pumpEventQueue();
      expect(filteredData.deletedBikes.any((b) => b.id == bike1.id), true);
      expect(filteredData.bikes.containsKey(bike1.id), false);

      await data.restoreBike(bike1);
      await pumpEventQueue();
      expect(filteredData.deletedBikes.any((b) => b.id == bike1.id), false);
      expect(filteredData.bikes.containsKey(bike1.id), true);
    });
  });
}
