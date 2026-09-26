import 'package:collection/collection.dart';

import '../models/adjustment/adjustment.dart';
import '../models/component/component.dart';
import '../models/person.dart';
import '../models/setup.dart';
import 'component_hierarchy_resolver.dart';

class DanglingComponentGroup {
  final Component component;
  final List<Adjustment> adjustments;

  DanglingComponentGroup({required this.component, required this.adjustments});
}

class DanglingPersonGroup {
  final Person person;
  final List<Adjustment> adjustments;

  DanglingPersonGroup({required this.person, required this.adjustments});
}

class DanglingComponentSplit {
  final List<DanglingComponentGroup> groups;
  final Map<String, dynamic> deletedValues;

  const DanglingComponentSplit({required this.groups, required this.deletedValues});
}

class DanglingPersonSplit {
  final List<DanglingPersonGroup> groups;
  final Map<String, dynamic> deletedValues;

  const DanglingPersonSplit({required this.groups, required this.deletedValues});
}

class SetupAdjustmentBreakdown {
  final List<Component> components;
  final DanglingComponentSplit componentSplit;
  final Person? person;
  final DanglingPersonSplit personSplit;

  const SetupAdjustmentBreakdown({
    required this.components,
    required this.componentSplit,
    required this.person,
    required this.personSplit,
  });

  List<Component> get danglingComponents => componentSplit.groups.map((g) => g.component).toList();
  List<Person> get danglingPersons => personSplit.groups.map((g) => g.person).toList();
}

class DanglingAdjustmentService {
  static bool isInstalledAtSetup(ComponentHierarchyResolver hierarchy, Component component, Setup setup) =>
      hierarchy.bikeAt(component.id, setup.datetimeLocal.toUtc()) == setup.bike;

  static SetupAdjustmentBreakdown analyzeSetup({
    required Setup setup,
    required Iterable<Component> components,
    required Iterable<Person> persons,
  }) {
    final componentList = components.toList();
    final hierarchy = ComponentHierarchyResolver({
      for (final component in componentList) component.id: component,
    });
    final List<Component> bikeComponents = componentList
        .where((c) => hierarchy.bikeAt(c.id, setup.datetimeLocal.toUtc()) == setup.bike)
        .toList();

    final Map<String, dynamic> danglingBikeValues = Map.from(setup.bikeAdjustmentValues);
    for (final component in bikeComponents) {
      for (final adjustment in component.adjustments) {
        danglingBikeValues.remove(adjustment.id);
      }
    }
    final componentSplit = splitComponents(
      danglingValues: danglingBikeValues,
      components: componentList,
    );

    final person = persons.firstWhereOrNull((p) => p.id == setup.person);

    final Map<String, dynamic> danglingPersonValues = Map.from(setup.personAdjustmentValues);
    for (final adjustment in person?.adjustments ?? const <Adjustment>[]) {
      danglingPersonValues.remove(adjustment.id);
    }
    final personSplit = splitPersons(
      danglingValues: danglingPersonValues,
      persons: persons,
    );

    return SetupAdjustmentBreakdown(
      components: bikeComponents,
      componentSplit: componentSplit,
      person: person,
      personSplit: personSplit,
    );
  }

  static DanglingComponentSplit splitComponents({
    required Map<String, dynamic> danglingValues,
    required Iterable<Component> components,
  }) {
    final Map<String, (Component, Adjustment)> componentAndAdjustmentById = {};
    for (final component in components) {
      for (final adjustment in component.adjustments) {
        componentAndAdjustmentById[adjustment.id] = (component, adjustment);
      }
    }

    final Map<String, DanglingComponentGroup> groupsByComponentId = {};
    final Map<String, dynamic> deletedValues = {};
    for (final entry in danglingValues.entries) {
      final match = componentAndAdjustmentById[entry.key];
      if (match == null) {
        deletedValues[entry.key] = entry.value;
        continue;
      }
      final (component, adjustment) = match;
      groupsByComponentId
          .putIfAbsent(component.id, () => DanglingComponentGroup(component: component, adjustments: []))
          .adjustments
          .add(adjustment);
    }

    return DanglingComponentSplit(groups: groupsByComponentId.values.toList(), deletedValues: deletedValues);
  }

  static DanglingPersonSplit splitPersons({
    required Map<String, dynamic> danglingValues,
    required Iterable<Person> persons,
  }) {
    final Map<String, (Person, Adjustment)> personAndAdjustmentById = {};
    for (final person in persons) {
      for (final adjustment in person.adjustments) {
        personAndAdjustmentById[adjustment.id] = (person, adjustment);
      }
    }

    final Map<String, DanglingPersonGroup> groupsByPersonId = {};
    final Map<String, dynamic> deletedValues = {};
    for (final entry in danglingValues.entries) {
      final match = personAndAdjustmentById[entry.key];
      if (match == null) {
        deletedValues[entry.key] = entry.value;
        continue;
      }
      final (person, adjustment) = match;
      groupsByPersonId
          .putIfAbsent(person.id, () => DanglingPersonGroup(person: person, adjustments: []))
          .adjustments
          .add(adjustment);
    }

    return DanglingPersonSplit(groups: groupsByPersonId.values.toList(), deletedValues: deletedValues);
  }
}
