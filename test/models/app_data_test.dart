import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/filtered_data.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/rating.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bike_setup_tracker/models/app_data.dart';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/installation.dart';

/// Allow Drift streams to propagate through subscriptions.
Future<void> pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

void main() {
  group("Bikes", () {
    late AppDatabase database;
    late AppData data;
    late FilteredData filteredData;
    final bike1 = Bike(name: "Bike #1", person: null);

    setUp(() {
      database = AppDatabase.memory();
      data = AppData(database);
      filteredData = FilteredData(database);
    });

    tearDown(() async {
      data.dispose();
      filteredData.dispose();
      await database.close();
    });

    test("AppData/addBike", () async {
      await data.addBike(bike1);
      await pumpEventQueue();
      
      expect(filteredData.bikes.containsKey(bike1.id), true);
      expect(filteredData.filteredBikes.containsKey(bike1.id), true);
    });
    test("AppData/removeBike (unselected)", () async {
      await data.addBike(bike1);
      await data.removeBike(bike1);
      await pumpEventQueue();

      expect(filteredData.bikes.containsKey(bike1.id), false);
      expect(filteredData.filteredBikes.containsKey(bike1.id), false);
    });
    test("AppData/restoreBike", () async {
      await data.addBike(bike1);
      await data.removeBike(bike1);
      await data.restoreBike(bike1);
      await pumpEventQueue();

      expect(filteredData.filteredBikes.containsKey(bike1.id), true);
    });
    test("AppData/removeBike (selected)", () async {
      await data.addBike(bike1);
      await pumpEventQueue();
      filteredData.onBikeTap(bike1.id);

      expect(filteredData.selectedBike == bike1.id, true);

      await data.removeBike(bike1);
      await pumpEventQueue();

      expect(filteredData.selectedBike == null, true);
      expect(filteredData.bikes.containsKey(bike1.id), false);
    });
  });

  group("Components", () {
    late AppDatabase database;
    late AppData data;
    late FilteredData filteredData;
    final bike1 = Bike(name: "Bike #1", person: null);
    late Component component1;

    setUp(() {
      database = AppDatabase.memory();
      data = AppData(database);
      filteredData = FilteredData(database);
      component1 = Component(
        name: "Component #1", 
        installations: [Installation.sinceBeginning(parent: bike1.id)], 
        componentType: ComponentType.fork, 
        adjustments: []
      );
    });

    tearDown(() async {
      data.dispose();
      filteredData.dispose();
      await database.close();
    });

    test("AppData/addComponent", () async {
      await data.addBike(bike1);
      await data.addComponent(component1);
      await Future.delayed(Duration(seconds: 1));
      
      expect(filteredData.components.containsKey(component1.id), true);
      expect(filteredData.filteredComponents.containsKey(component1.id), true);
    });
    test("AppData/removeComponents", () async {
      await data.addBike(bike1);
      await data.addComponent(component1);
      await data.removeComponents([component1]);
      await pumpEventQueue();

      expect(filteredData.components.containsKey(component1.id), false);
      expect(filteredData.filteredComponents.containsKey(component1.id), false);
    });
  });

  group("Setups", () {
    late AppDatabase database;
    late AppData data;
    late FilteredData filteredData;
    final bike1 = Bike(name: "Bike #1", person: null);
    late Setup setup1;

    setUp(() {
      database = AppDatabase.memory();
      data = AppData(database);
      filteredData = FilteredData(database);
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

    test("AppData/addSetup", () async {
      await data.addBike(bike1);
      await data.addSetup(setup1);
      await pumpEventQueue();
      
      expect(filteredData.setups.containsKey(setup1.id), true);
      expect(filteredData.filteredSetups.containsKey(setup1.id), true);
    });
  });

  group("Persons", () {
    late AppDatabase database;
    late AppData data;
    late FilteredData filteredData;
    final person1 = Person(name: "Person #1", adjustments: []);

    setUp(() {
      database = AppDatabase.memory();
      data = AppData(database);
      filteredData = FilteredData(database);
    });

    tearDown(() async {
      data.dispose();
      filteredData.dispose();
      await database.close();
    });

    test("AppData/addPerson", () async {
      await data.addPerson(person1);
      await pumpEventQueue();
      
      expect(filteredData.persons.containsKey(person1.id), true);
      expect(filteredData.filteredPersons.containsKey(person1.id), true);
    });
  });

  group("Ratings", () {
    late AppDatabase database;
    late AppData data;
    late FilteredData filteredData;
    final rating1 = Rating(name: "Rating #1", filterType: FilterType.global, filter: null, adjustments: []);

    setUp(() {
      database = AppDatabase.memory();
      data = AppData(database);
      filteredData = FilteredData(database);
    });

    tearDown(() async {
      data.dispose();
      filteredData.dispose();
      await database.close();
    });

    test("AppData/addRating", () async {
      await data.addRating(rating1);
      await pumpEventQueue();
      
      expect(filteredData.ratings.containsKey(rating1.id), true);
      expect(filteredData.filteredRatings.containsKey(rating1.id), true);
    });
  });
}
