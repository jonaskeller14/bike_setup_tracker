import '../models/adjustment/adjustment.dart';
import '../models/component.dart';
import '../models/person.dart';

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

class DanglingAdjustmentService {
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
