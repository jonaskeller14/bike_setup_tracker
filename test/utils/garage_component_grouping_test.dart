import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/services/component_hierarchy_resolver.dart';
import 'package:bike_setup_tracker/utils/garage_component_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime now = DateTime.utc(2026, 2, 1);

Component component(String id, List<Installation> installations, {int orderIndex = 0}) => Component(
  id: id,
  name: id,
  installations: installations,
  componentType: ComponentType.other,
  orderIndex: orderIndex,
);

Installation onBike(String componentId, String bikeId) => BikeInstallation(
  componentId: componentId,
  bikeId: bikeId,
  dateTimeUTC: DateTime.utc(2026, 1, 1),
  dateTimeLocal: DateTime(2026, 1, 1),
);

Installation onComponent(String componentId, String parentId) => ComponentInstallation(
  componentId: componentId,
  parentComponentId: parentId,
  dateTimeUTC: DateTime.utc(2026, 1, 1),
  dateTimeLocal: DateTime(2026, 1, 1),
);

Installation archived(String componentId) => Archival(
  componentId: componentId,
  dateTimeUTC: DateTime.utc(2026, 1, 1),
  dateTimeLocal: DateTime(2026, 1, 1),
);

ComponentHierarchyResolver resolverOf(List<Component> components) => ComponentHierarchyResolver(
  {for (final component in components) component.id: component},
  currentTimeUTC: now,
);

List<String> idsOf(Iterable<Component> components) => components.map((c) => c.id).toList();

void main() {
  test('returns every component as its own entry when nothing is mounted on a component', () {
    final components = [
      component('frame', [onBike('frame', 'bike')], orderIndex: 0),
      component('fork', [onBike('fork', 'bike')], orderIndex: 1),
    ];

    final groups = garageGroupsFor(components, hierarchy: resolverOf(components));

    expect(idsOf(groups.map((g) => g.parent)), ['frame', 'fork']);
    expect(groups.any((g) => g.isGroup), isFalse);
  });

  test('empty section yields no groups', () {
    expect(garageGroupsFor(const [], hierarchy: resolverOf(const [])), isEmpty);
  });

  test('groups two children under their parent', () {
    final components = [
      component('wheel', [onBike('wheel', 'bike')], orderIndex: 0),
      component('tire', [onComponent('tire', 'wheel')], orderIndex: 1),
      component('rotor', [onComponent('rotor', 'wheel')], orderIndex: 2),
    ];

    final groups = garageGroupsFor(components, hierarchy: resolverOf(components));

    expect(groups, hasLength(1));
    expect(groups.single.parent.id, 'wheel');
    expect(groups.single.isGroup, isTrue);
    expect(idsOf(groups.single.children), ['tire', 'rotor']);
    expect(idsOf(groups.single.components), ['wheel', 'tire', 'rotor']);
  });

  test('flattens a three-level chain into one group, depth-first', () {
    final components = [
      component('wheel', [onBike('wheel', 'bike')], orderIndex: 0),
      component('tire', [onComponent('tire', 'wheel')], orderIndex: 1),
      component('insert', [onComponent('insert', 'tire')], orderIndex: 2),
      component('valve', [onComponent('valve', 'wheel')], orderIndex: 3),
    ];

    final groups = garageGroupsFor(components, hierarchy: resolverOf(components));

    expect(groups, hasLength(1));
    expect(idsOf(groups.single.children), ['tire', 'insert', 'valve']);
  });

  test('a child whose parent lives in another section roots its own group', () {
    final all = [
      component('wheel', [onBike('wheel', 'bike')], orderIndex: 0),
      component('tire', [onComponent('tire', 'wheel')], orderIndex: 1),
      component('insert', [onComponent('insert', 'tire')], orderIndex: 2),
    ];
    // The section holds the tire and its insert, but not the wheel they hang off.
    final section = all.where((c) => c.id != 'wheel');

    final groups = garageGroupsFor(section, hierarchy: resolverOf(all));

    expect(groups, hasLength(1));
    expect(groups.single.parent.id, 'tire');
    expect(idsOf(groups.single.children), ['insert']);
  });

  test('an archived parent still carries its children', () {
    final components = [
      component('wheel', [archived('wheel')], orderIndex: 0),
      component('tire', [onComponent('tire', 'wheel')], orderIndex: 1),
    ];

    final groups = garageGroupsFor(components, hierarchy: resolverOf(components));

    expect(groups, hasLength(1));
    expect(groups.single.parent.id, 'wheel');
    expect(idsOf(groups.single.children), ['tire']);
  });

  test('orders roots and direct children by orderIndex', () {
    final components = [
      component('tire-b', [onComponent('tire-b', 'wheel')], orderIndex: 5),
      component('frame', [onBike('frame', 'bike')], orderIndex: 9),
      component('tire-a', [onComponent('tire-a', 'wheel')], orderIndex: 3),
      component('wheel', [onBike('wheel', 'bike')], orderIndex: 1),
    ];

    final groups = garageGroupsFor(components, hierarchy: resolverOf(components));

    expect(idsOf(groups.map((g) => g.parent)), ['wheel', 'frame']);
    expect(idsOf(groups.first.children), ['tire-a', 'tire-b']);
  });

  test('a cyclic pair renders as plain entries instead of looping', () {
    final components = [
      component('a', [onComponent('a', 'b')], orderIndex: 0),
      component('b', [onComponent('b', 'a')], orderIndex: 1),
    ];

    final groups = garageGroupsFor(components, hierarchy: resolverOf(components));

    expect(idsOf(groups.map((g) => g.parent)), ['a', 'b']);
    expect(groups.any((g) => g.isGroup), isFalse);
  });

  test('a component below a cycle roots its own group', () {
    final components = [
      component('a', [onComponent('a', 'b')], orderIndex: 0),
      component('b', [onComponent('b', 'a')], orderIndex: 1),
      component('tire', [onComponent('tire', 'a')], orderIndex: 2),
    ];

    final groups = garageGroupsFor(components, hierarchy: resolverOf(components));

    expect(idsOf(groups.map((g) => g.parent)), ['a', 'b', 'tire']);
    expect(groups.any((g) => g.isGroup), isFalse);
  });

  test('a component whose parent id does not exist roots its own group', () {
    final components = [
      component('tire', [onComponent('tire', 'ghost-wheel')], orderIndex: 0),
    ];

    final groups = garageGroupsFor(components, hierarchy: resolverOf(components));

    expect(groups, hasLength(1));
    expect(groups.single.parent.id, 'tire');
    expect(groups.single.children, isEmpty);
  });

  test('each component appears exactly once across all groups', () {
    final components = [
      component('wheel', [onBike('wheel', 'bike')], orderIndex: 0),
      component('tire', [onComponent('tire', 'wheel')], orderIndex: 1),
      component('frame', [onBike('frame', 'bike')], orderIndex: 2),
    ];

    final groups = garageGroupsFor(components, hierarchy: resolverOf(components));

    expect(idsOf(groups.expand((g) => g.components)), ['wheel', 'tire', 'frame']);
  });

  group('garageGroupOf', () {
    final components = [
      component('frame', [onBike('frame', 'bike')], orderIndex: 0),
      component('wheel', [onComponent('wheel', 'frame')], orderIndex: 1),
      component('tire', [onComponent('tire', 'wheel')], orderIndex: 2),
      component('fork', [onBike('fork', 'bike')], orderIndex: 3),
    ];
    final byId = {for (final c in components) c.id: c};

    test('a root includes all its descendants', () {
      final group = garageGroupOf(byId['frame']!, components, hierarchy: resolverOf(components));

      expect(idsOf(group.components), ['frame', 'wheel', 'tire']);
    });

    test('a mounted component roots a group of only its own descendants', () {
      final group = garageGroupOf(byId['wheel']!, components, hierarchy: resolverOf(components));

      expect(idsOf(group.components), ['wheel', 'tire']);
    });

    test('a component without descendants is a single cell', () {
      final group = garageGroupOf(byId['fork']!, components, hierarchy: resolverOf(components));

      expect(group.parent.id, 'fork');
      expect(group.isGroup, isFalse);
    });

    test('descendants outside the section are left out', () {
      final section = components.where((c) => c.id != 'tire');

      final group = garageGroupOf(byId['frame']!, section, hierarchy: resolverOf(components));

      expect(idsOf(group.components), ['frame', 'wheel']);
    });
  });
}
