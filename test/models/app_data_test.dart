import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/rating.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bike_setup_tracker/models/app_data.dart';
import 'package:bike_setup_tracker/models/bike.dart';

void main() {
  group("Bikes", () {
    final data = AppData();
    final bike1 = Bike(name: "Bike #1", person: null);

    test("AppData/addBike", () {
      data.addBike(bike1);
      
      expect(data.bikes.containsValue(bike1), true);
      expect(data.filteredBikes.containsValue(bike1), true);
    });
    test("AppData/removeBike (unselected)", () {
      data.removeBike(bike1);

      expect(bike1.isDeleted, true);
      expect(data.bikes.containsValue(bike1), true);
      expect(data.filteredBikes.containsValue(bike1), false);
    });
    test("AppData/restoreBike", () {
      data.restoreBike(bike1);

      expect(bike1.isDeleted, false);
      expect(data.bikes.containsValue(bike1), true);
      expect(data.filteredBikes.containsValue(bike1), true);
    });
    test("AppData/removeBike (selected)", () {
      data.onBikeTap(bike1);

      expect(data.selectedBike == bike1, true);
      expect(data.bikes.containsValue(bike1), true);
      expect(data.filteredBikes.containsValue(bike1), true);

      data.removeBike(bike1);

      expect(bike1.isDeleted, true);
      expect(data.selectedBike == null, true);
      expect(data.bikes.containsValue(bike1), true);
      expect(data.filteredBikes.containsValue(bike1), false);
    });
  });
  group("Components", () {
    final data = AppData();
    final bike1 = Bike(name: "Bike #1", person: null);
    final component1 = Component(name: "Component #1", bike: bike1.id, componentType: ComponentType.fork, adjustments: []);

    test("AppData/addComponent", () {
      data.addBike(bike1);
      data.addComponent(component1);
      
      expect(data.components.containsValue(component1), true);
      expect(data.filteredComponents.containsValue(component1), true);
    });
    test("AppData/removeComponents", () {
      data.removeComponents([component1]);

      expect(component1.isDeleted, true);
      expect(data.components.containsValue(component1), true);
      expect(data.filteredComponents.containsValue(component1), false);
    });
    test("AppData/restoreComponents", () {
      data.restoreComponents([component1]);

      expect(component1.isDeleted, false);
      expect(data.components.containsValue(component1), true);
      expect(data.filteredComponents.containsValue(component1), true);
    });
  });
  group("Setups", () {
    final data = AppData();
    final bike1 = Bike(name: "Bike #1", person: null);
    final component1 = Component(name: "Component #1", bike: bike1.id, componentType: ComponentType.fork, adjustments: []);
    final setup1 = Setup(
      name: "Setup #1", 
      datetime: DateTime(2000),
      bike: bike1.id, 
      person: null, 
      bikeAdjustmentValues: {}, 
      personAdjustmentValues: {},
      ratingAdjustmentValues: {},
      isCurrent: true,
    );

    test("AppData/addSetup", () {
      data.addBike(bike1);
      data.addComponent(component1);
      data.addSetup(setup1);
      
      expect(data.setups.containsValue(setup1), true);
      expect(data.filteredSetups.containsValue(setup1), true);
    });
    test("AppData/removeSetups", () {
      data.removeSetups([setup1]);

      expect(setup1.isDeleted, true);
      expect(data.setups.containsValue(setup1), true);
      expect(data.filteredSetups.containsValue(setup1), false);
    });
    test("AppData/restoreSetups", () {
      data.restoreSetups([setup1]);

      expect(setup1.isDeleted, false);
      expect(data.setups.containsValue(setup1), true);
      expect(data.filteredSetups.containsValue(setup1), true);
    });
  });
  group("Persons", () {
    final data = AppData();
    final person1 = Person(name: "Person #1", adjustments: []);
    test("AppData/addPerson", () {
      data.addPerson(person1);
      
      expect(data.persons.containsValue(person1), true);
      expect(data.filteredPersons.containsValue(person1), true);
    });
    test("AppData/removePerson", () {
      data.removePerson(person1);

      expect(person1.isDeleted, true);
      expect(data.persons.containsValue(person1), true);
      expect(data.filteredPersons.containsValue(person1), false);
    });
    test("AppData/restorePerson", () {
      data.restorePerson(person1);

      expect(person1.isDeleted, false);
      expect(data.persons.containsValue(person1), true);
      expect(data.filteredPersons.containsValue(person1), true);
    });
  });
  group("Ratings", () {
    final data = AppData();
    final rating1 = Rating(name: "Rating #1", filterType: FilterType.global, filter: null, adjustments: []);
    test("AppData/addPerson", () {
      data.addRating(rating1);
      
      expect(data.ratings.containsValue(rating1), true);
      expect(data.filteredRatings.containsValue(rating1), true);
    });
    test("AppData/removePerson", () {
      data.removeRating(rating1);

      expect(rating1.isDeleted, true);
      expect(data.ratings.containsValue(rating1), true);
      expect(data.filteredRatings.containsValue(rating1), false);
    });
    test("AppData/restorePerson", () {
      data.restoreRating(rating1);

      expect(rating1.isDeleted, false);
      expect(data.ratings.containsValue(rating1), true);
      expect(data.filteredRatings.containsValue(rating1), true);
    });
  });
}
