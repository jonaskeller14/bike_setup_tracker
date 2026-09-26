import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/component_ancestor.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/services/component_hierarchy_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

Component component(String id, List<Installation> installations) => Component(
      id: id,
      name: id,
      installations: installations,
      componentType: ComponentType.other,
    );

Installation onBike(String componentId, String bikeId, int day) => BikeInstallation(
      componentId: componentId,
      bikeId: bikeId,
      dateTimeUTC: DateTime.utc(2026, 1, day),
      dateTimeLocal: DateTime(2026, 1, day),
    );

Installation onComponent(String componentId, String parentId, int day) => ComponentInstallation(
      componentId: componentId,
      parentComponentId: parentId,
      dateTimeUTC: DateTime.utc(2026, 1, day),
      dateTimeLocal: DateTime(2026, 1, day),
    );

Installation uninstalled(String componentId, int day) => Uninstallation(
  componentId: componentId,
  dateTimeUTC: DateTime.utc(2026, 1, day),
  dateTimeLocal: DateTime(2026, 1, day),
);

void main() {
  test('resolves arbitrary depth and latest effective installation date', () {
    final resolver = ComponentHierarchyResolver({
      'wheel': component('wheel', [onBike('wheel', 'bike', 3)]),
      'tire': component('tire', [onComponent('tire', 'wheel', 2)]),
      'insert': component('insert', [onComponent('insert', 'tire', 1)]),
    });

    final placement = resolver.resolveAt('insert', DateTime.utc(2026, 1, 10));
    expect(placement.bikeId, 'bike');
    expect(placement.effectiveSinceUTC, DateTime.utc(2026, 1, 3));
    expect(resolver.descendantsOf('wheel'), {'tire', 'insert'});
  });

  test('parent deinstallation implicitly takes descendants off-bike', () {
    final resolver = ComponentHierarchyResolver({
      'wheel': component('wheel', [
        onBike('wheel', 'bike', 1),
        Uninstallation(
          componentId: 'wheel',
          dateTimeUTC: DateTime.utc(2026, 1, 5),
          dateTimeLocal: DateTime(2026, 1, 5),
        ),
      ]),
      'tire': component('tire', [onComponent('tire', 'wheel', 1)]),
    });

    expect(resolver.bikeAt('tire', DateTime.utc(2026, 1, 4)), 'bike');
    expect(resolver.bikeAt('tire', DateTime.utc(2026, 1, 6)), isNull);
  });

  test('dangling parent is preserved and resolves off-bike', () {
    final resolver = ComponentHierarchyResolver({
      'tire': component('tire', [onComponent('tire', 'missing-wheel', 1)]),
    });

    final placement = resolver.resolveAt('tire', DateTime.utc(2026, 1, 2));
    expect(placement.bikeId, isNull);
    expect(placement.isDangling, isTrue);
  });

  group('ancestorsAt', () {
    final at = DateTime.utc(2026, 1, 10);

    test('lists parents nearest first and ends at the bike', () {
      final resolver = ComponentHierarchyResolver({
        'wheel': component('wheel', [onBike('wheel', 'bike', 3)]),
        'tire': component('tire', [onComponent('tire', 'wheel', 2)]),
        'insert': component('insert', [onComponent('insert', 'tire', 1)]),
      });

      final ancestors = resolver.ancestorsAt('insert', at);
      expect(ancestors, hasLength(3));
      expect((ancestors[0] as ParentComponentAncestor).component.id, 'tire');
      expect((ancestors[1] as ParentComponentAncestor).component.id, 'wheel');
      expect((ancestors[2] as BikeAncestor).bikeId, 'bike');
    });

    test('ends at archived or uninstalled state', () {
      final resolver = ComponentHierarchyResolver({
        'archived': component('archived', [
          Archival(componentId: 'archived', dateTimeUTC: DateTime.utc(2026, 1, 1), dateTimeLocal: DateTime(2026, 1, 1)),
        ]),
        'loose': component('loose', []),
        'child': component('child', [onComponent('child', 'archived', 2)]),
      });

      expect(resolver.ancestorsAt('loose', at).single, isA<UninstalledAncestor>());
      final ancestors = resolver.ancestorsAt('child', at);
      expect((ancestors[0] as ParentComponentAncestor).component.id, 'archived');
      expect(ancestors[1], isA<ArchivedAncestor>());
    });

    test('ends at a missing parent and stops on cycles', () {
      final resolver = ComponentHierarchyResolver({
        'tire': component('tire', [onComponent('tire', 'missing-wheel', 1)]),
        'a': component('a', [onComponent('a', 'b', 1)]),
        'b': component('b', [onComponent('b', 'a', 1)]),
      });

      expect((resolver.ancestorsAt('tire', at).single as MissingParentAncestor).componentId, 'missing-wheel');
      expect(resolver.ancestorsAt('a', at).map((a) => (a as ParentComponentAncestor).component.id), ['b']);
      expect(resolver.ancestorsAt('unknown', at), isEmpty);
    });
  });

  test('rejects temporal cycles', () {
    final resolver = ComponentHierarchyResolver({
      'a': component('a', [onComponent('a', 'b', 1)]),
      'b': component('b', [onComponent('b', 'a', 1)]),
    });

    expect(resolver.validate, throwsA(isA<ComponentHierarchyValidationException>()));
  });

  test('rejects duplicate installation timestamps', () {
    final when = DateTime.utc(2026, 1, 1);
    final resolver = ComponentHierarchyResolver({
      'a': component('a', [
        BikeInstallation(
          componentId: 'a',
          bikeId: 'bike-1',
          dateTimeUTC: when,
          dateTimeLocal: DateTime(2026, 1, 1),
        ),
        BikeInstallation(
          componentId: 'a',
          bikeId: 'bike-2',
          dateTimeUTC: when,
          dateTimeLocal: DateTime(2026, 1, 1),
        ),
      ]),
    });

    expect(resolver.validate, throwsA(isA<ComponentHierarchyValidationException>()));
  });

  group('inheritedRootChanges', () {
    test('emits a change each time the parent moves the child to a new root', () {
      final fork = component('fork', [onBike('fork', 'a', 1), onBike('fork', 'b', 5), uninstalled('fork', 9)]);
      final damper = component('damper', [onComponent('damper', 'fork', 2)]);
      final resolver = ComponentHierarchyResolver({'fork': fork, 'damper': damper});

      final changes = resolver.inheritedRootChanges('damper');

      expect(changes.map((c) => c.cause.dateTimeUTC), [DateTime.utc(2026, 1, 5), DateTime.utc(2026, 1, 9)]);
      expect((changes[0].root as BikeAncestor).bikeId, 'b');
      expect(changes[1].root, isA<UninstalledAncestor>());
      expect(changes.every((c) => c.viaParentId == 'fork'), isTrue);
    });

    test('ignores parent moves before the child is installed on it', () {
      final fork = component('fork', [onBike('fork', 'a', 1), onBike('fork', 'b', 2)]);
      final damper = component('damper', [onComponent('damper', 'fork', 3)]);
      final resolver = ComponentHierarchyResolver({'fork': fork, 'damper': damper});

      expect(resolver.inheritedRootChanges('damper'), isEmpty);
    });

    test('ignores parent moves after the child left it', () {
      final fork = component('fork', [onBike('fork', 'a', 1), onBike('fork', 'b', 5)]);
      final damper = component('damper', [onComponent('damper', 'fork', 2), uninstalled('damper', 3)]);
      final resolver = ComponentHierarchyResolver({'fork': fork, 'damper': damper});

      expect(resolver.inheritedRootChanges('damper'), isEmpty);
    });

    test('ignores parent events that keep the same root', () {
      final fork = component('fork', [onBike('fork', 'a', 1), onBike('fork', 'a', 5)]);
      final damper = component('damper', [onComponent('damper', 'fork', 2)]);
      final resolver = ComponentHierarchyResolver({'fork': fork, 'damper': damper});

      expect(resolver.inheritedRootChanges('damper'), isEmpty);
    });

    test('follows moves of a grandparent', () {
      final wheel = component('wheel', [onBike('wheel', 'a', 1), onBike('wheel', 'b', 6)]);
      final tire = component('tire', [onComponent('tire', 'wheel', 1)]);
      final insert = component('insert', [onComponent('insert', 'tire', 2)]);
      final resolver = ComponentHierarchyResolver({'wheel': wheel, 'tire': tire, 'insert': insert});

      final changes = resolver.inheritedRootChanges('insert');

      expect(changes, hasLength(1));
      expect((changes.single.root as BikeAncestor).bikeId, 'b');
      expect(changes.single.viaParentId, 'tire');
    });

    test('missing parent yields no changes and does not throw', () {
      final damper = component('damper', [onComponent('damper', 'gone', 2)]);
      final resolver = ComponentHierarchyResolver({'damper': damper});

      expect(resolver.inheritedRootChanges('damper'), isEmpty);
      expect(resolver.rootAt('damper', DateTime.utc(2026, 1, 3)), isA<MissingParentAncestor>());
    });
  });
}
