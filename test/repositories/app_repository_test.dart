import 'package:bike_setup_tracker/database/adjustment_value_codec.dart';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/models/person.dart';
import 'package:bike_setup_tracker/models/rating.dart';
import 'package:bike_setup_tracker/models/rating_association.dart';
import 'package:bike_setup_tracker/models/rating_entry.dart';
import 'package:bike_setup_tracker/models/rating_metric.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/utils/unit_conversion.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

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
        unit: AdjustmentUnit.fromLegacy("psi"),
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
        unit: AdjustmentUnit.fromLegacy("kg"),
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
    final rating1 = Rating(name: "Rating #1", filterType: FilterType.global, filter: null, metrics: []);

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
        unit: null,
      );
      final ratingWithAdj = rating1.copyWith(id: rating1.id, metrics: [RatingMetric(adjustment: adjustment)]);

      await repository.addRating(ratingWithAdj);
      await pumpEventQueue();

      expect(repository.ratings[ratingWithAdj.id]?.metrics.length, 1);

      // Remove
      await repository.removeRatings([ratingWithAdj]);
      await pumpEventQueue();

      expect(repository.ratings.containsKey(ratingWithAdj.id), false);
      final deletedRating = repository.deletedRatings.firstWhere((r) => r.id == ratingWithAdj.id);
      expect(deletedRating.metrics.isEmpty, true);

      // Restore
      await repository.restoreRatings([deletedRating]);
      await pumpEventQueue();

      expect(repository.ratings.containsKey(ratingWithAdj.id), true);
      expect(repository.ratings[ratingWithAdj.id]?.metrics.length, 1);
    });
  });
  group("AppRepository - Unit Conversions", () {
    late AppDatabase database;
    late AppRepository repository;

    const psi = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi');
    const bar = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'bar');
    const kg = KnownUnit(quantity: UnitQuantity.mass, unitId: 'kilograms');
    const lb = KnownUnit(quantity: UnitQuantity.mass, unitId: 'pounds');

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      await pumpEventQueue();
    });

    tearDown(() async {
      await database.close();
    });

    Setup buildSetup(String bikeId, {String? personId, Map<String, dynamic>? bikeValues, Map<String, dynamic>? personValues}) => Setup(
      name: "Setup",
      tags: {},
      datetime: DateTime(2020).toUtc(),
      datetimeLocal: DateTime(2020),
      bike: bikeId,
      person: personId,
      bikeAdjustmentValues: bikeValues ?? {},
      personAdjustmentValues: personValues ?? {},
    );

    test("editComponent with Convert rewrites setup values and bumps lastModified", () async {
      final bike = Bike(name: "B", person: null);
      final adj = NumericalAdjustment(name: "Pressure", notes: null, unit: psi, min: 0, max: 300);
      final component = Component(
        name: "Fork",
        componentType: ComponentType.fork,
        adjustments: [adj],
        installations: [Installation.sinceBeginning(parent: bike.id)],
      );
      final setup = buildSetup(bike.id, bikeValues: {adj.id: 65.0});

      await repository.addBike(bike);
      await repository.addComponent(component);
      await repository.addSetup(setup);
      await pumpEventQueue();

      // Age the setup so the lastModified bump is unambiguous despite
      // second-resolution timestamps (add + edit fall in the same second).
      await (database.update(database.setups)..where((t) => t.id.equals(setup.id)))
          .write(SetupsCompanion(lastModified: Value(DateTime(2000).toUtc())));
      await pumpEventQueue();
      final before = repository.setups[setup.id]!.lastModified;

      // Bounds are left as typed; only stored setup values convert.
      final convertedComponent = component.copyWith(adjustments: [adj.copyWith(unit: bar)]);
      await repository.editComponent(
        convertedComponent,
        conversions: [ValueUnitConversion(adjustmentId: adj.id, from: psi, to: bar)],
      );
      await pumpEventQueue();

      final value = repository.setups[setup.id]!.bikeAdjustmentValues[adj.id] as double;
      expect(value, closeTo(convertUnit(65.0, psi, bar), 1e-9));
      expect(repository.setups[setup.id]!.lastModified.isAfter(before), isTrue);
    });

    test("editComponent without conversions leaves setup values and lastModified untouched", () async {
      final bike = Bike(name: "B", person: null);
      final adj = NumericalAdjustment(name: "Pressure", notes: null, unit: psi);
      final component = Component(
        name: "Fork",
        componentType: ComponentType.fork,
        adjustments: [adj],
        installations: [Installation.sinceBeginning(parent: bike.id)],
      );
      final setup = buildSetup(bike.id, bikeValues: {adj.id: 65.0});

      await repository.addBike(bike);
      await repository.addComponent(component);
      await repository.addSetup(setup);
      await pumpEventQueue();

      final before = repository.setups[setup.id]!.lastModified;

      // "Keep numbers": unit changes but no conversion staged.
      await repository.editComponent(component.copyWith(adjustments: [adj.copyWith(unit: bar)]));
      await pumpEventQueue();

      expect(repository.setups[setup.id]!.bikeAdjustmentValues[adj.id], 65.0);
      expect(repository.setups[setup.id]!.lastModified, before);
    });

    test("editPerson with Convert rewrites person adjustment values in setups", () async {
      final bike = Bike(name: "B", person: null);
      final padj = NumericalAdjustment(name: "Weight", notes: null, unit: kg, min: 0);
      final person = Person(name: "P", adjustments: [padj]);
      final setup = buildSetup(bike.id, personId: person.id, personValues: {padj.id: 70.0});

      await repository.addBike(bike);
      await repository.addPerson(person);
      await repository.addSetup(setup);
      await pumpEventQueue();

      await repository.editPerson(
        person.copyWith(adjustments: [padj.copyWith(unit: lb)]),
        conversions: [ValueUnitConversion(adjustmentId: padj.id, from: kg, to: lb)],
      );
      await pumpEventQueue();

      final value = repository.setups[setup.id]!.personAdjustmentValues[padj.id] as double;
      expect(value, closeTo(convertUnit(70.0, kg, lb), 1e-9));
    });

    test("editRating with Convert rewrites rating-entry values and bumps lastModified", () async {
      final metricAdj = NumericalAdjustment(name: "Pressure", notes: null, unit: psi, min: 0, max: 300);
      final rating = Rating(
        name: "R",
        filterType: FilterType.global,
        filter: null,
        metrics: [RatingMetric(adjustment: metricAdj)],
      );
      final entry = RatingEntry(
        bike: "b",
        setupId: "s",
        dateTimeUTC: DateTime(2020).toUtc(),
        dateTimeLocal: DateTime(2020),
        metricValues: {metricAdj.id: 65.0},
      );

      await repository.addRating(rating);
      await repository.addRatingEntry(entry);
      await pumpEventQueue();

      // Age the entry so the lastModified bump is unambiguous despite
      // second-resolution timestamps (add + edit fall in the same second).
      await (database.update(database.ratingEntries)..where((t) => t.id.equals(entry.id)))
          .write(RatingEntriesCompanion(lastModified: Value(DateTime(2000).toUtc())));
      await pumpEventQueue();
      final before = repository.ratingEntries[entry.id]!.lastModified;

      final convertedRating = rating.copyWith(metrics: [
        RatingMetric(adjustment: metricAdj.copyWith(unit: bar)),
      ]);
      await repository.editRating(
        convertedRating,
        conversions: [ValueUnitConversion(adjustmentId: metricAdj.id, from: psi, to: bar)],
      );
      await pumpEventQueue();

      final value = repository.ratingEntries[entry.id]!.metricValues[metricAdj.id] as double;
      expect(value, closeTo(convertUnit(65.0, psi, bar), 1e-9));
      expect(repository.ratingEntries[entry.id]!.lastModified.isAfter(before), isTrue);
    });

    test("convertAdjustmentValues converts numeric rows and leaves unparseable rows untouched", () async {
      const adjId = 'adj-x';
      await database.into(database.setupAdjustmentValues).insert(
        SetupAdjustmentValuesCompanion.insert(setupId: 's1', adjustmentId: adjId, value: encodeAdjustmentValue(10.0)));
      await database.into(database.setupAdjustmentValues).insert(
        SetupAdjustmentValuesCompanion.insert(setupId: 's2', adjustmentId: adjId, value: '"n/a"'));

      await database.setupsDao.convertAdjustmentValues(adjId, (v) => v * 2);

      final rows = await database.select(database.setupAdjustmentValues).get();
      final byId = {for (final r in rows) r.setupId: r.value};
      expect(byId['s1'], encodeAdjustmentValue(20.0));
      expect(byId['s2'], '"n/a"'); // unparseable — left untouched
    });

    test("ValueUnitConversion composes to a single from->to and detects no-ops", () {
      const kpa = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'kiloPascal');
      const first = ValueUnitConversion(adjustmentId: 'a', from: psi, to: bar);
      final composed = first.composeWith(const ValueUnitConversion(adjustmentId: 'a', from: bar, to: kpa));
      expect(composed.from, psi);
      expect(composed.to, kpa);
      expect(composed.isNoOp, isFalse);

      final roundTrip = first.composeWith(const ValueUnitConversion(adjustmentId: 'a', from: bar, to: psi));
      expect(roundTrip.isNoOp, isTrue);
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

    test("filteredInstallations includes uninstallations for selectedBike", () async {
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
      rule1 = TaskRule(name: "Rule 1", componentId: component1.id, tags: const {});
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
      final rule2 = TaskRule(name: "Rule 2", componentId: component2.id, tags: const {});

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

    test("toDoTaskRules sorts by status, then priority, then progress", () async {
      final ruleLow = TaskRule(name: "Low", priority: TaskPriority.low, tags: const {});
      final ruleHigh = TaskRule(name: "High", priority: TaskPriority.high, tags: const {});
      final ruleMedium = TaskRule(name: "Medium", priority: TaskPriority.medium, tags: const {});
      final ruleCritical = TaskRule(name: "Critical", priority: TaskPriority.critical, tags: const {});

      await repository.addTaskRule(ruleLow);
      await repository.addTaskRule(ruleHigh);
      await repository.addTaskRule(ruleMedium);
      await repository.addTaskRule(ruleCritical);
      await pumpEventQueue();

      final toDo = repository.openTaskRules;
      expect(toDo.length, 4);

      // Since all have the same status (Due, because interval is null) and progress (0.0),
      // they should be sorted by priority (Critical > High > Medium > Low)
      expect(toDo[0].rule.name, "Critical");
      expect(toDo[1].rule.name, "High");
      expect(toDo[2].rule.name, "Medium");
      expect(toDo[3].rule.name, "Low");
    });

    test("toDoTaskRules prioritizes severity over fine-grained urgency within a status bucket", () async {
      // Regression test: Critical trigger-less task (due, progress 0.0) should rank above
      // Low-priority task that's genuinely due (progress >= 1.0)
      final ruleCriticalNoTrigger = TaskRule(
        name: "Critical (no trigger)",
        priority: TaskPriority.critical,
        tags: const {},
      );
      final ruleLowDue = TaskRule(
        name: "Low (due)",
        priority: TaskPriority.low,
        tags: const {},
        interval: DateTimeThreshold(DateTime.now().subtract(const Duration(hours: 1))),
      );

      await repository.addTaskRule(ruleCriticalNoTrigger);
      await repository.addTaskRule(ruleLowDue);
      await pumpEventQueue();

      final toDo = repository.openTaskRules;
      expect(toDo.length, 2);

      // Both should be in the "due" bucket; Critical should sort first despite having lower progress
      expect(toDo[0].rule.name, "Critical (no trigger)");
      expect(toDo[0].status.type, TaskStatusType.due);
      expect(toDo[0].status.progress, 0.0);
      expect(toDo[1].rule.name, "Low (due)");
      expect(toDo[1].status.type, TaskStatusType.due);
      expect(toDo[1].status.progress > 1.0, true); // Progress > 1.0 for the interval-based due task
    });

    test("openTaskRulesStatusType returns the aggregated highest priority status", () async {
      // 1. Initially empty: should be completed
      expect(repository.openTaskRulesStatusType, TaskStatusType.completed);

      // 2. Add an upcoming task
      final upcomingRule = TaskRule(
        name: "Upcoming",
        tags: const {},
        interval: const DurationThreshold(Duration(days: 30000)), // ~82 years
      );
      await repository.addTaskRule(upcomingRule);
      await pumpEventQueue();
      expect(repository.openTaskRulesStatusType, TaskStatusType.upcoming);

      // 3. Add a due task (due > upcoming)
      final dueRule = TaskRule(
        name: "Due",
        tags: const {},
      );
      await repository.addTaskRule(dueRule);
      await pumpEventQueue();
      expect(repository.openTaskRulesStatusType, TaskStatusType.due);

      // 4. Add an overdue task (overdue > due > upcoming)
      final overdueRule = TaskRule(
        name: "Overdue",
        tags: const {},
        interval: const DurationThreshold(Duration(days: 10)),
      );
      await repository.addTaskRule(overdueRule);
      await pumpEventQueue();
      expect(repository.openTaskRulesStatusType, TaskStatusType.overdue);

      // 5. Complete/remove uncompleted tasks and verify we go back down
      await repository.removeTaskRules([overdueRule, dueRule]);
      await pumpEventQueue();
      expect(repository.openTaskRulesStatusType, TaskStatusType.upcoming);
    });
  });

  group("AppRepository - Archive", () {
    late AppDatabase database;
    late AppRepository repository;
    final bike1 = Bike(name: "Bike #1", person: null);
    late Component component1;

    setUp(() async {
      database = AppDatabase.memory();
      repository = AppRepository(database);
      await pumpEventQueue();
      component1 = Component(
        name: "C1",
        installations: [Installation.sinceBeginning(parent: bike1.id)],
        componentType: ComponentType.fork,
        adjustments: [],
      );
    });

    tearDown(() async {
      await database.close();
    });

    test("archiveComponent removes from filteredComponents and adds to archivedComponents", () async {
      await repository.addBike(bike1);
      await repository.addComponent(component1);
      await pumpEventQueue();

      expect(repository.filteredComponents.containsKey(component1.id), isTrue);
      expect(repository.archivedComponents.containsKey(component1.id), isFalse);

      final comp = repository.components[component1.id]!;
      await repository.archiveComponent(comp);
      await pumpEventQueue();

      expect(repository.filteredComponents.containsKey(component1.id), isFalse);
      expect(repository.archivedComponents.containsKey(component1.id), isTrue);
      expect(repository.archivedComponents[component1.id]!.isArchived, isTrue);
    });

    test("unarchiveComponent removes the Archival event and restores prior state", () async {
      await repository.addBike(bike1);
      await repository.addComponent(component1);
      await pumpEventQueue();

      final comp = repository.components[component1.id]!;
      await repository.archiveComponent(comp);
      await pumpEventQueue();

      expect(repository.archivedComponents.containsKey(component1.id), isTrue);

      final archived = repository.archivedComponents[component1.id]!;
      await repository.unarchiveComponent(archived);
      await pumpEventQueue();

      // No longer archived.
      expect(repository.archivedComponents.containsKey(component1.id), isFalse);

      // Archival event has been removed — state is restored to before archiving.
      final unarchived = repository.components[component1.id]!;
      expect(unarchived.isArchived, isFalse);
      expect(unarchived.installations.whereType<Archival>(), isEmpty);

      // component1 started with sinceBeginning(bike1) → restored to on-bike.
      expect(unarchived.bike, bike1.id);
    });

    test("task rule for archived component is hidden from filteredOpenTaskRules", () async {
      final rule = TaskRule(
        name: "Rule 1",
        componentId: component1.id,
        tags: const {},
      );

      await repository.addBike(bike1);
      await repository.addComponent(component1);
      await repository.addTaskRule(rule);
      await pumpEventQueue();

      expect(repository.filteredOpenTaskRules.containsKey(rule.id), isTrue);

      final comp = repository.components[component1.id]!;
      await repository.archiveComponent(comp);
      await pumpEventQueue();

      expect(repository.filteredOpenTaskRules.containsKey(rule.id), isFalse);
    });
  });
}
