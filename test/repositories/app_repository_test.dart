import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/rating.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/task_rule.dart';
import 'package:bike_setup_tracker/models/task_entry.dart';

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

    test("restoreBike preserves setup adjustment values", () async {
      final adjustment = NumericalAdjustment(
        name: "Pressure",
        notes: "",
        unit: "psi",
        category: AdjustmentCategory.component,
      );
      final bikeWithAdj = bike1.copyWith(id: bike1.id);
      final component = Component(
        name: "Fork",
        componentType: ComponentType.fork,
        adjustments: [adjustment],
        installations: [Installation.sinceBeginning(parent: bikeWithAdj.id)],
      );
      
      final setupWithVals = setup1.copyWith(
        bike: bikeWithAdj.id,
        bikeAdjustmentValues: {adjustment.id: 100.0},
      );

      await repository.addBike(bikeWithAdj);
      await repository.addComponent(component);
      await repository.addSetup(setupWithVals);
      await pumpEventQueue();

      expect(repository.setups[setupWithVals.id]?.bikeAdjustmentValues[adjustment.id], 100.0);

      // Simulate BikeActions.removeBike logic
      final obsoleteComponents = repository.components.values.where((c) => c.bike == bikeWithAdj.id).toList();
      final obsoleteSetups = repository.setups.values.where((s) => s.bike == bikeWithAdj.id).toList();

      await repository.removeBike(bikeWithAdj);
      await repository.removeComponents(obsoleteComponents);
      await repository.removeSetups(obsoleteSetups);
      await pumpEventQueue();

      expect(repository.bikes.containsKey(bikeWithAdj.id), false);
      expect(repository.setups.containsKey(setupWithVals.id), false);
      
      final deletedSetup = repository.deletedSetups.firstWhere((s) => s.id == setupWithVals.id);
      expect(deletedSetup.bikeAdjustmentValues.isEmpty, true); // This is the bug: it should NOT be empty but it IS

      // Restore using the object from the repository's deleted list (simulating TrashPage)
      await repository.restoreBike(bikeWithAdj);
      await repository.restoreComponents(obsoleteComponents);
      await repository.restoreSetups([deletedSetup]);
      await pumpEventQueue();

      expect(repository.bikes.containsKey(bikeWithAdj.id), true);
      expect(repository.setups.containsKey(setupWithVals.id), true);
      // This is expected to fail before the fix
      expect(repository.setups[setupWithVals.id]?.bikeAdjustmentValues[adjustment.id], 100.0);
    });

    test("restoreBike preserves component installations", () async {
      final bikeWithComp = bike1.copyWith(id: bike1.id);
      final component = Component(
        name: "Fork",
        componentType: ComponentType.fork,
        adjustments: [],
        installations: [
          Installation.sinceBeginning(parent: bikeWithComp.id),
          Installation(
            parent: null, // Archive
            dateTimeUTC: DateTime(2025, 1, 1).toUtc(),
            dateTimeLocal: DateTime(2025, 1, 1).toLocal(),
          ),
        ],
      );

      await repository.addBike(bikeWithComp);
      await repository.addComponent(component);
      await pumpEventQueue();

      expect(repository.components[component.id]?.installations.length, 2);

      // Simulate removal
      final obsoleteComponents = [repository.components[component.id]!];
      await repository.removeComponents(obsoleteComponents);
      await pumpEventQueue();

      expect(repository.components.containsKey(component.id), false);
      final deletedComponent = repository.deletedComponents.firstWhere((c) => c.id == component.id);
      
      // The current implementation uses toModel(installations: []) for deleted components
      expect(deletedComponent.installations.isEmpty, true);

      // Restore
      await repository.restoreComponents([deletedComponent]);
      await pumpEventQueue();

      expect(repository.components.containsKey(component.id), true);
      // This should ALREADY pass because restoreComponents uses updateComponent (root only)
      expect(repository.components[component.id]?.installations.length, 2);
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

    test("restorePerson preserves adjustments", () async {
      final adjustment = NumericalAdjustment(
        name: "Weight",
        notes: "",
        unit: "kg",
        category: AdjustmentCategory.body,
      );
      final personWithAdj = person1.copyWith(id: person1.id, adjustments: [adjustment]);

      await repository.addPerson(personWithAdj);
      await pumpEventQueue();

      expect(repository.persons[personWithAdj.id]?.adjustments.length, 1);

      // Remove
      await repository.removePerson(personWithAdj);
      await pumpEventQueue();

      expect(repository.persons.containsKey(personWithAdj.id), false);
      final deletedPerson = repository.deletedPersons.firstWhere((p) => p.id == personWithAdj.id);
      expect(deletedPerson.adjustments.isEmpty, true);

      // Restore
      await repository.restorePerson(deletedPerson);
      await pumpEventQueue();

      expect(repository.persons.containsKey(personWithAdj.id), true);
      expect(repository.persons[personWithAdj.id]?.adjustments.length, 1);
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

    test("restoreRating preserves adjustments", () async {
      final adjustment = NumericalAdjustment(
        name: "Difficulty",
        notes: "",
        unit: "",
        category: AdjustmentCategory.rating,
      );
      final ratingWithAdj = rating1.copyWith(id: rating1.id, adjustments: [adjustment]);

      await repository.addRating(ratingWithAdj);
      await pumpEventQueue();

      expect(repository.ratings[ratingWithAdj.id]?.adjustments.length, 1);

      // Remove
      await repository.removeRatings([ratingWithAdj]);
      await pumpEventQueue();

      expect(repository.ratings.containsKey(ratingWithAdj.id), false);
      final deletedRating = repository.deletedRatings.firstWhere((r) => r.id == ratingWithAdj.id);
      expect(deletedRating.adjustments.isEmpty, true);

      // Restore
      await repository.restoreRatings([deletedRating]);
      await pumpEventQueue();

      expect(repository.ratings.containsKey(ratingWithAdj.id), true);
      expect(repository.ratings[ratingWithAdj.id]?.adjustments.length, 1);
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

  group("AppRepository - Tasks", () {
    late AppDatabase database;
    late AppRepository repository;
    final bike1 = Bike(name: "Bike #1", person: null);
    late Component component1;
    late TaskRule rule1;

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      await pumpEventQueue();
      component1 = Component(
        name: "C1", 
        installations: [Installation.sinceBeginning(parent: bike1.id)], 
        componentType: ComponentType.fork, 
        adjustments: []
      );
      rule1 = TaskRule(name: "Rule 1", componentId: component1.id);
    });

    tearDown(() async {
      await database.close();
    });

    test("openTaskCount updates when adding rule and entry", () async {
      await repository.addBike(bike1);
      await repository.addComponent(component1);
      await repository.addTaskRule(rule1);
      await pumpEventQueue();

      // Rule added, no entry -> open count should be 1
      expect(repository.filteredOpenTaskRulesCount, 1);
      expect(repository.filteredOpenTaskRules.containsKey(rule1.id), true);

      final entry1 = TaskEntry(
        name: "Entry 1",
        dateTimeUTC: DateTime.now().toUtc(),
        dateTimeLocal: DateTime.now().toLocal(),
        taskRule: rule1.id,
        componentId: component1.id,
      );

      await repository.addTaskEntry(entry1);
      await pumpEventQueue();

      // Entry added -> open count should be 0
      expect(repository.filteredOpenTaskRulesCount, 0);
      expect(repository.filteredOpenTaskRules.containsKey(rule1.id), false);
    });

    test("openTaskCount handles filtering by bike", () async {
      final bike2 = Bike(name: "Bike #2", person: null);
      final component2 = Component(
        name: "C2", 
        installations: [Installation.sinceBeginning(parent: bike2.id)], 
        componentType: ComponentType.fork, 
        adjustments: []
      );
      final rule2 = TaskRule(name: "Rule 2", componentId: component2.id);

      await repository.addBike(bike1);
      await repository.addBike(bike2);
      await repository.addComponent(component1);
      await repository.addComponent(component2);
      await repository.addTaskRule(rule1);
      await repository.addTaskRule(rule2);
      await pumpEventQueue();

      expect(repository.filteredOpenTaskRulesCount, 2);

      // Filter by bike1
      repository.onBikeTap(bike1.id);
      await pumpEventQueue();

      expect(repository.filteredOpenTaskRulesCount, 1);
      expect(repository.filteredOpenTaskRules.containsKey(rule1.id), true);
      expect(repository.filteredOpenTaskRules.containsKey(rule2.id), false);
    });

    test("toDoTaskRules sorts by status, then progress, then priority", () async {
      final ruleLow = TaskRule(name: "Low", priority: TaskPriority.low);
      final ruleHigh = TaskRule(name: "High", priority: TaskPriority.high);
      final ruleMedium = TaskRule(name: "Medium", priority: TaskPriority.medium);
      final ruleCritical = TaskRule(name: "Critical", priority: TaskPriority.critical);

      await repository.addTaskRule(ruleLow);
      await repository.addTaskRule(ruleHigh);
      await repository.addTaskRule(ruleMedium);
      await repository.addTaskRule(ruleCritical);
      await pumpEventQueue();

      final toDo = repository.toDoTaskRules;
      expect(toDo.length, 4);
      
      // Since all have the same status (Due, because interval is null) and progress (0.0), 
      // they should be sorted by priority (Critical > High > Medium > Low)
      expect(toDo[0].rule.name, "Critical");
      expect(toDo[1].rule.name, "High");
      expect(toDo[2].rule.name, "Medium");
      expect(toDo[3].rule.name, "Low");
    });
  });
}
