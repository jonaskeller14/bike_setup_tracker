import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/filtered_data.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/rating.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bike_setup_tracker/models/app_data.dart';
import 'package:bike_setup_tracker/models/bike.dart';

void main() {
  group("Bikes", () {
    final data = AppData();
    final filteredData = FilteredData(data);
    final bike1 = Bike(name: "Bike #1", person: null);

    test("AppData/addBike", () {
      data.addBike(bike1);
      filteredData.update(data);
      
      expect(data.bikes.containsValue(bike1), true);
      expect(filteredData.bikes.containsValue(bike1), true);
      expect(filteredData.filteredBikes.containsValue(bike1), true);
    });
    test("AppData/removeBike (unselected)", () {
      data.removeBike(bike1);
      filteredData.update(data);

      expect(bike1.isDeleted, true);
      expect(data.bikes.containsValue(bike1), true);
      expect(filteredData.bikes.containsValue(bike1), false);
      expect(filteredData.filteredBikes.containsValue(bike1), false);
    });
    test("AppData/restoreBike", () {
      data.restoreBike(bike1);
      filteredData.update(data);

      expect(bike1.isDeleted, false);
      expect(data.bikes.containsValue(bike1), true);
      expect(filteredData.filteredBikes.containsValue(bike1), true);
    });
    test("AppData/removeBike (selected)", () {
      filteredData.onBikeTap(bike1);

      expect(filteredData.selectedBike == bike1, true);
      expect(data.bikes.containsValue(bike1), true);
      expect(filteredData.bikes.containsValue(bike1), true);
      expect(filteredData.filteredBikes.containsValue(bike1), true);

      data.removeBike(bike1);
      filteredData.update(data);

      expect(bike1.isDeleted, true);
      expect(filteredData.selectedBike == null, true);
      expect(data.bikes.containsValue(bike1), true);
      expect(filteredData.bikes.containsValue(bike1), false);
      expect(filteredData.filteredBikes.containsValue(bike1), false);
    });
  });
  group("Components", () {
    final data = AppData();
    final filteredData = FilteredData(data);
    final bike1 = Bike(name: "Bike #1", person: null);
    final component1 = Component(name: "Component #1", bike: bike1.id, componentType: ComponentType.fork, adjustments: []);

    test("AppData/addComponent", () {
      data.addBike(bike1);
      filteredData.update(data);
      data.addComponent(component1);
      filteredData.update(data);
      
      expect(data.components.containsValue(component1), true);
      expect(filteredData.components.containsValue(component1), true);
      expect(filteredData.filteredComponents.containsValue(component1), true);
    });
    test("AppData/removeComponents", () {
      data.removeComponents([component1]);
      filteredData.update(data);

      expect(component1.isDeleted, true);
      expect(data.components.containsValue(component1), true);
      expect(filteredData.components.containsValue(component1), false);
      expect(filteredData.filteredComponents.containsValue(component1), false);
    });
    test("AppData/restoreComponents", () {
      data.restoreComponents([component1]);
      filteredData.update(data);

      expect(component1.isDeleted, false);
      expect(data.components.containsValue(component1), true);
      expect(filteredData.components.containsValue(component1), true);
      expect(filteredData.filteredComponents.containsValue(component1), true);
    });
  });
  group("Setups", () {
    final data = AppData();
    final filteredData = FilteredData(data);
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
      filteredData.update(data);
      data.addComponent(component1);
      filteredData.update(data);
      data.addSetup(setup1);
      filteredData.update(data);
      
      expect(data.setups.containsValue(setup1), true);
      expect(filteredData.setups.containsValue(setup1), true);
      expect(filteredData.filteredSetups.containsValue(setup1), true);
    });
    test("AppData/removeSetups", () {
      data.removeSetups([setup1]);
      filteredData.update(data);

      expect(setup1.isDeleted, true);
      expect(data.setups.containsValue(setup1), true);
      expect(filteredData.setups.containsValue(setup1), false);
      expect(filteredData.filteredSetups.containsValue(setup1), false);
    });
    test("AppData/restoreSetups", () {
      data.restoreSetups([setup1]);
      filteredData.update(data);

      expect(setup1.isDeleted, false);
      expect(data.setups.containsValue(setup1), true);
      expect(filteredData.setups.containsValue(setup1), true);
      expect(filteredData.filteredSetups.containsValue(setup1), true);
    });
  });
  group("Persons", () {
    final data = AppData();
    final filteredData = FilteredData(data);
    final person1 = Person(name: "Person #1", adjustments: []);
    test("AppData/addPerson", () {
      data.addPerson(person1);
      filteredData.update(data);
      
      expect(data.persons.containsValue(person1), true);
      expect(filteredData.persons.containsValue(person1), true);
      expect(filteredData.filteredPersons.containsValue(person1), true);
    });
    test("AppData/removePerson", () {
      data.removePerson(person1);
      filteredData.update(data);

      expect(person1.isDeleted, true);
      expect(data.persons.containsValue(person1), true);
      expect(filteredData.persons.containsValue(person1), false);
      expect(filteredData.filteredPersons.containsValue(person1), false);
    });
    test("AppData/restorePerson", () {
      data.restorePerson(person1);
      filteredData.update(data);

      expect(person1.isDeleted, false);
      expect(data.persons.containsValue(person1), true);
      expect(filteredData.persons.containsValue(person1), true);
      expect(filteredData.filteredPersons.containsValue(person1), true);
    });
  });
  group("Ratings", () {
    final data = AppData();
    final filteredData = FilteredData(data);
    final rating1 = Rating(name: "Rating #1", filterType: FilterType.global, filter: null, adjustments: []);
    test("AppData/addPerson", () {
      data.addRating(rating1);
      filteredData.update(data);
      
      expect(data.ratings.containsValue(rating1), true);
      expect(filteredData.ratings.containsValue(rating1), true);
      expect(filteredData.filteredRatings.containsValue(rating1), true);
    });
    test("AppData/removePerson", () {
      data.removeRating(rating1);
      filteredData.update(data);

      expect(rating1.isDeleted, true);
      expect(data.ratings.containsValue(rating1), true);
      expect(filteredData.ratings.containsValue(rating1), false);
      expect(filteredData.filteredRatings.containsValue(rating1), false);
    });
    test("AppData/restorePerson", () {
      data.restoreRating(rating1);
      filteredData.update(data);

      expect(rating1.isDeleted, false);
      expect(data.ratings.containsValue(rating1), true);
      expect(filteredData.ratings.containsValue(rating1), true);
      expect(filteredData.filteredRatings.containsValue(rating1), true);
    });
  });
}
