import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/rating.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/models/bike.dart';

Future<void> pumpEventQueue() => Future.delayed(const Duration(milliseconds: 100));

void main() {
  late AppDatabase database;
  late AppRepository repository;

  setUp(() async {
    database = AppDatabase.memory();
    repository = AppRepository(database);
    await pumpEventQueue();
  });

  tearDown(() async {
    await database.close();
  });

  group("Reordering Tests", () {
    test("Reorder Bikes", () async {
      final bike1 = Bike(id: "1", name: "Bike 1", person: null);
      final bike2 = Bike(id: "2", name: "Bike 2", person: null);
      final bike3 = Bike(id: "3", name: "Bike 3", person: null);

      await repository.addBike(bike1);
      await repository.addBike(bike2);
      await repository.addBike(bike3);
      await pumpEventQueue();

      // Initial order should be 1, 2, 3 (orderIndex defaults to 0, but inserted in this order)
      // Actually without explicit orderIndex during insert, they all have 0. 
      // Drift order by order_index will be stable but order depends on insertion if all index equal they are likely returned in insertion order but not guaranteed.
      // After manual reorder call, they MUST be in the correct order.

      final bikes = repository.bikes.values.toList();
      await repository.reorderBike(oldIndex: 0, newIndex: 3, filteredBikesList: bikes); // Move 1 to end
      await pumpEventQueue();

      final reorderedBikes = repository.bikes.values.toList();
      expect(reorderedBikes[0].id, "2");
      expect(reorderedBikes[1].id, "3");
      expect(reorderedBikes[2].id, "1");
    });

    test("Reorder Components", () async {
      final comp1 = Component(id: "c1", name: "C1", installations: [], componentType: ComponentType.other);
      final comp2 = Component(id: "c2", name: "C2", installations: [], componentType: ComponentType.other);
      final comp3 = Component(id: "c3", name: "C3", installations: [], componentType: ComponentType.other);

      await repository.addComponent(comp1);
      await repository.addComponent(comp2);
      await repository.addComponent(comp3);
      await pumpEventQueue();

      final comps = repository.components.values.toList();
      await repository.reorderComponent(oldIndex: 2, newIndex: 0, filteredComponentsList: comps); // Move 3 to top
      await pumpEventQueue();

      final reorderedComps = repository.components.values.toList();
      expect(reorderedComps[0].id, "c3");
      expect(reorderedComps[1].id, "c1");
      expect(reorderedComps[2].id, "c2");
    });

    test("Reorder Persons", () async {
      final p1 = Person(id: "p1", name: "P1");
      final p2 = Person(id: "p2", name: "P2");
      final p3 = Person(id: "p3", name: "P3");

      await repository.addPerson(p1);
      await repository.addPerson(p2);
      await repository.addPerson(p3);
      await pumpEventQueue();

      final persons = repository.persons.values.toList();
      await repository.reorderPerson(oldIndex: 1, newIndex: 0, filteredPersonsList: persons); // Move 2 to top
      await pumpEventQueue();

      final reorderedPersons = repository.persons.values.toList();
      expect(reorderedPersons[0].id, "p2");
      expect(reorderedPersons[1].id, "p1");
      expect(reorderedPersons[2].id, "p3");
    });

    test("Reorder Ratings", () async {
      final r1 = Rating(id: "r1", name: "R1", filter: null, filterType: FilterType.global);
      final r2 = Rating(id: "r2", name: "R2", filter: null, filterType: FilterType.global);
      final r3 = Rating(id: "r3", name: "R3", filter: null, filterType: FilterType.global);

      await repository.addRating(r1);
      await repository.addRating(r2);
      await repository.addRating(r3);
      await pumpEventQueue();

      final ratings = repository.ratings.values.toList();
      await repository.reorderRating(oldIndex: 1, newIndex: 3, filteredRatingsList: ratings); // Move 2 to bottom
      await pumpEventQueue();

      final reorderedRatings = repository.ratings.values.toList();
      expect(reorderedRatings[0].id, "r1");
      expect(reorderedRatings[1].id, "r3");
      expect(reorderedRatings[2].id, "r2");
    });
  });
}
