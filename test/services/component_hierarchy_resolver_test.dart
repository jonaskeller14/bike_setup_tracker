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

Installation onBike(String bikeId, int day) => BikeInstallation(
      bikeId: bikeId,
      dateTimeUTC: DateTime.utc(2026, 1, day),
      dateTimeLocal: DateTime(2026, 1, day),
    );

Installation onComponent(String parentId, int day) => ComponentInstallation(
      parentComponentId: parentId,
      dateTimeUTC: DateTime.utc(2026, 1, day),
      dateTimeLocal: DateTime(2026, 1, day),
    );

Installation uninstalled(int day) => Uninstallation(
  dateTimeUTC: DateTime.utc(2026, 1, day),
  dateTimeLocal: DateTime(2026, 1, day),
);

Installation archived(int day) => Archival(
  dateTimeUTC: DateTime.utc(2026, 1, day),
  dateTimeLocal: DateTime(2026, 1, day),
);

DateTime day(int day) => DateTime.utc(2026, 1, day);

List<String> parentIds(List<ComponentAncestor> ancestors) => [
      for (final ancestor in ancestors)
        if (ancestor is ParentComponentAncestor) ancestor.component.id,
    ];

Matcher throwsCycle({required Set<String> componentIds, DateTime? at}) => throwsA(
      isA<ComponentHierarchyValidationException>()
          .having((e) => e.message, 'message', contains('cycle'))
          .having((e) => e.componentIds, 'componentIds', componentIds)
          .having((e) => e.dateTimeUTC, 'dateTimeUTC', at ?? anything),
    );

void main() {
  test('resolves arbitrary depth and latest effective installation date', () {
    final resolver = ComponentHierarchyResolver({
      'wheel': component('wheel', [onBike('bike', 3)]),
      'tire': component('tire', [onComponent('wheel', 2)]),
      'insert': component('insert', [onComponent('tire', 1)]),
    });

    final placement = resolver.resolveAt('insert', DateTime.utc(2026, 1, 10));
    expect(placement.bikeId, 'bike');
    expect(placement.effectiveSinceUTC, DateTime.utc(2026, 1, 3));
    expect(resolver.descendantsOf('wheel'), {'tire', 'insert'});
  });

  test('childrenOf lists only direct children at the given time', () {
    final resolver = ComponentHierarchyResolver({
      'wheel': component('wheel', [onBike('bike', 1)]),
      'tire': component('tire', [onComponent('wheel', 1)]),
      'insert': component('insert', [onComponent('tire', 1)]),
      'valve': component('valve', [onComponent('wheel', 1), uninstalled(5)]),
    });

    expect(resolver.childrenOf('wheel', atUTC: DateTime.utc(2026, 1, 3)), {'tire', 'valve'});
    expect(resolver.childrenOf('wheel', atUTC: DateTime.utc(2026, 1, 6)), {'tire'});
    expect(resolver.childrenOf('insert', atUTC: DateTime.utc(2026, 1, 6)), isEmpty);
  });

  test('parent deinstallation implicitly takes descendants off-bike', () {
    final resolver = ComponentHierarchyResolver({
      'wheel': component('wheel', [
        onBike('bike', 1),
        Uninstallation(
          dateTimeUTC: DateTime.utc(2026, 1, 5),
          dateTimeLocal: DateTime(2026, 1, 5),
        ),
      ]),
      'tire': component('tire', [onComponent('wheel', 1)]),
    });

    expect(resolver.bikeAt('tire', DateTime.utc(2026, 1, 4)), 'bike');
    expect(resolver.bikeAt('tire', DateTime.utc(2026, 1, 6)), isNull);
  });

  test('dangling parent is preserved and resolves off-bike', () {
    final resolver = ComponentHierarchyResolver({
      'tire': component('tire', [onComponent('missing-wheel', 1)]),
    });

    final placement = resolver.resolveAt('tire', DateTime.utc(2026, 1, 2));
    expect(placement.bikeId, isNull);
    expect(placement.isDangling, isTrue);
  });

  group('ancestorsAt', () {
    final at = DateTime.utc(2026, 1, 10);

    test('lists parents nearest first and ends at the bike', () {
      final resolver = ComponentHierarchyResolver({
        'wheel': component('wheel', [onBike('bike', 3)]),
        'tire': component('tire', [onComponent('wheel', 2)]),
        'insert': component('insert', [onComponent('tire', 1)]),
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
          Archival(dateTimeUTC: DateTime.utc(2026, 1, 1), dateTimeLocal: DateTime(2026, 1, 1)),
        ]),
        'loose': component('loose', []),
        'child': component('child', [onComponent('archived', 2)]),
      });

      expect(resolver.ancestorsAt('loose', at).single, isA<UninstalledAncestor>());
      final ancestors = resolver.ancestorsAt('child', at);
      expect((ancestors[0] as ParentComponentAncestor).component.id, 'archived');
      expect(ancestors[1], isA<ArchivedAncestor>());
    });

    test('ends at a missing parent and stops on cycles', () {
      final resolver = ComponentHierarchyResolver({
        'tire': component('tire', [onComponent('missing-wheel', 1)]),
        'a': component('a', [onComponent('b', 1)]),
        'b': component('b', [onComponent('a', 1)]),
      });

      expect((resolver.ancestorsAt('tire', at).single as MissingParentAncestor).componentId, 'missing-wheel');
      expect(resolver.ancestorsAt('a', at).map((a) => (a as ParentComponentAncestor).component.id), ['b']);
      expect(resolver.ancestorsAt('unknown', at), isEmpty);
    });
  });

  test('rejects temporal cycles', () {
    final resolver = ComponentHierarchyResolver({
      'a': component('a', [onComponent('b', 1)]),
      'b': component('b', [onComponent('a', 1)]),
    });

    expect(resolver.validate, throwsA(isA<ComponentHierarchyValidationException>()));
  });

  test('rejects duplicate installation timestamps', () {
    final when = DateTime.utc(2026, 1, 1);
    final resolver = ComponentHierarchyResolver({
      'a': component('a', [
        BikeInstallation(
          bikeId: 'bike-1',
          dateTimeUTC: when,
          dateTimeLocal: DateTime(2026, 1, 1),
        ),
        BikeInstallation(
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
      final fork = component('fork', [onBike('a', 1), onBike('b', 5), uninstalled(9)]);
      final damper = component('damper', [onComponent('fork', 2)]);
      final resolver = ComponentHierarchyResolver({'fork': fork, 'damper': damper});

      final changes = resolver.inheritedRootChanges('damper');

      expect(changes.map((c) => c.cause.dateTimeUTC), [DateTime.utc(2026, 1, 5), DateTime.utc(2026, 1, 9)]);
      expect((changes[0].root as BikeAncestor).bikeId, 'b');
      expect(changes[1].root, isA<UninstalledAncestor>());
      expect(changes.every((c) => c.viaParentId == 'fork'), isTrue);
    });

    test('ignores parent moves before the child is installed on it', () {
      final fork = component('fork', [onBike('a', 1), onBike('b', 2)]);
      final damper = component('damper', [onComponent('fork', 3)]);
      final resolver = ComponentHierarchyResolver({'fork': fork, 'damper': damper});

      expect(resolver.inheritedRootChanges('damper'), isEmpty);
    });

    test('ignores parent moves after the child left it', () {
      final fork = component('fork', [onBike('a', 1), onBike('b', 5)]);
      final damper = component('damper', [onComponent('fork', 2), uninstalled(3)]);
      final resolver = ComponentHierarchyResolver({'fork': fork, 'damper': damper});

      expect(resolver.inheritedRootChanges('damper'), isEmpty);
    });

    test('ignores parent events that keep the same root', () {
      final fork = component('fork', [onBike('a', 1), onBike('a', 5)]);
      final damper = component('damper', [onComponent('fork', 2)]);
      final resolver = ComponentHierarchyResolver({'fork': fork, 'damper': damper});

      expect(resolver.inheritedRootChanges('damper'), isEmpty);
    });

    test('follows moves of a grandparent', () {
      final wheel = component('wheel', [onBike('a', 1), onBike('b', 6)]);
      final tire = component('tire', [onComponent('wheel', 1)]);
      final insert = component('insert', [onComponent('tire', 2)]);
      final resolver = ComponentHierarchyResolver({'wheel': wheel, 'tire': tire, 'insert': insert});

      final changes = resolver.inheritedRootChanges('insert');

      expect(changes, hasLength(1));
      expect((changes.single.root as BikeAncestor).bikeId, 'b');
      expect(changes.single.viaParentId, 'tire');
    });

    test('missing parent yields no changes and does not throw', () {
      final damper = component('damper', [onComponent('gone', 2)]);
      final resolver = ComponentHierarchyResolver({'damper': damper});

      expect(resolver.inheritedRootChanges('damper'), isEmpty);
      expect(resolver.rootAt('damper', DateTime.utc(2026, 1, 3)), isA<MissingParentAncestor>());
    });
  });

  group('cycles', () {
    test('component installed on itself', () {
      final resolver = ComponentHierarchyResolver({
        'a': component('a', [onComponent('a', 1)]),
      });

      final placement = resolver.resolveAt('a', day(2));
      expect(placement.isCyclic, isTrue);
      expect(placement.bikeId, isNull);
      expect(resolver.ancestorsAt('a', day(2)), isEmpty);
      expect(resolver.rootAt('a', day(2)), isA<UninstalledAncestor>());
      expect(resolver.childrenOf('a', atUTC: day(2)), {'a'});
      expect(resolver.descendantsOf('a', atUTC: day(2)), isEmpty);
      expect(resolver.historicalDescendantsOf('a'), isEmpty);
      expect(resolver.inheritedRootChanges('a'), isEmpty);
      expect(resolver.validate, throwsCycle(componentIds: {'a'}, at: day(1)));
    });

    test('three-component loop with a tail hanging off it', () {
      // a -> b -> c -> a, plus d sitting on a.
      final resolver = ComponentHierarchyResolver({
        'd': component('d', [onComponent('a', 1)]),
        'a': component('a', [onComponent('b', 1)]),
        'b': component('b', [onComponent('c', 1)]),
        'c': component('c', [onComponent('a', 1)]),
      });

      for (final id in ['a', 'b', 'c', 'd']) {
        final placement = resolver.resolveAt(id, day(2));
        expect(placement.isCyclic, isTrue, reason: id);
        expect(placement.bikeId, isNull, reason: id);
      }
      expect(parentIds(resolver.ancestorsAt('d', day(2))), ['a', 'b', 'c']);
      expect(parentIds(resolver.ancestorsAt('b', day(2))), ['c', 'a']);
      expect(resolver.descendantsOf('a', atUTC: day(2)), {'b', 'c', 'd'});
      expect(resolver.descendantsOf('d', atUTC: day(2)), isEmpty);
      expect(resolver.historicalDescendantsOf('b'), {'a', 'c', 'd'});
      expect(resolver.inheritedRootChanges('d'), isEmpty);
      // The tail is not part of the reported cycle.
      expect(resolver.validate, throwsCycle(componentIds: {'a', 'b', 'c'}, at: day(1)));
    });

    test('cycle that only exists for a period of time', () {
      // b rides on bike x and carries a; b is then put onto a (cycle) until
      // b is moved to bike y, which breaks the loop.
      final resolver = ComponentHierarchyResolver({
        'a': component('a', [onComponent('b', 2)]),
        'b': component('b', [onBike('x', 1), onComponent('a', 5), onBike('y', 8)]),
      });

      expect(resolver.bikeAt('a', day(3)), 'x');
      expect(resolver.resolveAt('a', day(3)).isCyclic, isFalse);

      expect(resolver.resolveAt('a', day(6)).isCyclic, isTrue);
      expect(resolver.resolveAt('b', day(6)).isCyclic, isTrue);
      expect(resolver.bikeAt('a', day(6)), isNull);
      expect(resolver.descendantsOf('a', atUTC: day(6)), {'b'});

      final afterBreak = resolver.resolveAt('a', day(9));
      expect(afterBreak.isCyclic, isFalse);
      expect(afterBreak.bikeId, 'y');
      expect(afterBreak.effectiveSinceUTC, day(8));
      expect(resolver.descendantsOf('a', atUTC: day(9)), isEmpty);

      final changes = resolver.inheritedRootChanges('a');
      expect(changes.map((c) => c.cause.dateTimeUTC), [day(5), day(8)]);
      expect(changes.first.root, isA<UninstalledAncestor>());
      expect((changes.last.root as BikeAncestor).bikeId, 'y');

      expect(resolver.validate, throwsCycle(componentIds: {'a', 'b'}, at: day(5)));
    });

    test('swapping parent and child at the same instant is valid', () {
      // a sits on b until day 5, then a goes on the bike and b goes on a.
      final resolver = ComponentHierarchyResolver({
        'a': component('a', [onComponent('b', 1), onBike('bike', 5)]),
        'b': component('b', [onBike('bike', 1), onComponent('a', 5)]),
      });

      expect(resolver.validate, returnsNormally);
      expect(resolver.bikeAt('a', day(3)), 'bike');
      expect(resolver.descendantsOf('b', atUTC: day(3)), {'a'});
      expect(resolver.bikeAt('b', day(6)), 'bike');
      expect(resolver.descendantsOf('a', atUTC: day(6)), {'b'});
      expect(parentIds(resolver.ancestorsAt('b', day(6))), ['a']);
      // The union over all time contains the loop, but traversal terminates.
      expect(resolver.historicalDescendantsOf('a'), {'b'});
      expect(resolver.historicalDescendantsOf('b'), {'a'});
    });

    test('swap with an overlap of one day is rejected', () {
      final resolver = ComponentHierarchyResolver({
        'a': component('a', [onComponent('b', 1), onBike('bike', 6)]),
        'b': component('b', [onBike('bike', 1), onComponent('a', 5)]),
      });

      expect(resolver.validate, throwsCycle(componentIds: {'a', 'b'}, at: day(5)));
    });

    test('cycle among other valid hierarchies is reported precisely', () {
      final resolver = ComponentHierarchyResolver({
        'wheel': component('wheel', [onBike('bike', 1)]),
        'tire': component('tire', [onComponent('wheel', 1)]),
        'p': component('p', [onBike('bike', 1), onComponent('q', 4)]),
        'q': component('q', [onComponent('r', 2)]),
        'r': component('r', [onComponent('p', 3)]),
      });

      expect(resolver.bikeAt('tire', day(10)), 'bike');
      expect(resolver.resolveAt('tire', day(10)).isCyclic, isFalse);
      expect(resolver.bikeAt('q', day(3)), 'bike');
      expect(resolver.resolveAt('q', day(10)).isCyclic, isTrue);
      expect(resolver.validate, throwsCycle(componentIds: {'p', 'q', 'r'}, at: day(4)));
    });

    test('cyclic placement does not leak into queries at other times', () {
      final resolver = ComponentHierarchyResolver({
        'a': component('a', [onComponent('b', 1)]),
        'b': component('b', [onComponent('a', 3), onBike('bike', 5)]),
      });

      // Query the cyclic instant first so its result is cached.
      expect(resolver.resolveAt('a', day(4)).isCyclic, isTrue);
      expect(resolver.resolveAt('a', day(2)).isCyclic, isFalse);
      expect(resolver.bikeAt('a', day(6)), 'bike');
      expect(resolver.resolveAt('b', day(4)).isCyclic, isTrue);
    });
  });

  group('missing and deleted parents', () {
    test('missing parent in the middle of a chain', () {
      final resolver = ComponentHierarchyResolver({
        'tire': component('tire', [onComponent('missing-wheel', 1)]),
        'insert': component('insert', [onComponent('tire', 1)]),
      });

      final placement = resolver.resolveAt('insert', day(2));
      expect(placement.isDangling, isTrue);
      expect(placement.bikeId, isNull);
      final ancestors = resolver.ancestorsAt('insert', day(2));
      expect(parentIds(ancestors), ['tire']);
      expect((ancestors.last as MissingParentAncestor).componentId, 'missing-wheel');
      expect(resolver.validate, returnsNormally);
    });

    test('deleted parent takes its descendants with it', () {
      final resolver = ComponentHierarchyResolver(
        {
          'wheel': component('wheel', [onBike('bike', 1)]),
          'tire': component('tire', [onComponent('wheel', 1)]),
          'insert': component('insert', [onComponent('tire', 1)]),
        },
        deletedComponentIds: {'tire'},
        currentTimeUTC: day(10),
      );

      expect(resolver.isEffectivelyDeleted('insert'), isTrue);
      expect(resolver.isEffectivelyDeleted('wheel'), isFalse);
      expect(resolver.currentBike('insert'), isNull);
      expect((resolver.currentRoot('insert') as MissingParentAncestor).componentId, 'tire');
    });

    test('deleted component breaks a cycle during resolution', () {
      final resolver = ComponentHierarchyResolver(
        {
          'a': component('a', [onComponent('b', 1)]),
          'b': component('b', [onComponent('a', 1)]),
        },
        deletedComponentIds: {'b'},
      );

      final placement = resolver.resolveAt('a', day(2));
      expect(placement.isDeleted, isTrue);
      expect(placement.isCyclic, isFalse);
      expect((resolver.rootAt('a', day(2)) as MissingParentAncestor).componentId, 'b');
    });
  });

  group('time handling', () {
    test('child installed before its parent reaches a bike', () {
      final resolver = ComponentHierarchyResolver({
        'fork': component('fork', [onBike('bike', 5)]),
        'damper': component('damper', [onComponent('fork', 2)]),
      });

      expect(resolver.resolveAt('damper', day(1)).bikeId, isNull);
      expect(resolver.bikeAt('damper', day(3)), isNull);
      expect(resolver.rootAt('damper', day(3)), isA<UninstalledAncestor>());
      expect(resolver.bikeAt('damper', day(5)), 'bike');
      expect(resolver.effectiveBikeSinceAt('damper', day(6)), day(5));
    });

    test('events apply from their exact timestamp on', () {
      final resolver = ComponentHierarchyResolver({
        'fork': component('fork', [onBike('a', 1), onBike('b', 5)]),
        'damper': component('damper', [onComponent('fork', 1)]),
      });

      expect(resolver.bikeAt('damper', day(5).subtract(const Duration(minutes: 1))), 'a');
      expect(resolver.bikeAt('damper', day(5)), 'b');
    });

    test('moving a child between parents on different bikes', () {
      final resolver = ComponentHierarchyResolver({
        'front': component('front', [onBike('x', 1)]),
        'rear': component('rear', [onBike('y', 1)]),
        'tire': component('tire', [onComponent('front', 2), onComponent('rear', 5)]),
      });

      expect(resolver.bikeAt('tire', day(4)), 'x');
      expect(resolver.bikeAt('tire', day(6)), 'y');
      expect(resolver.effectiveBikeSinceAt('tire', day(6)), day(5));
      expect(resolver.childrenOf('front', atUTC: day(6)), isEmpty);
      expect(resolver.historicalDescendantsOf('front'), {'tire'});
    });

    test('parent moving bikes resets the effective date of descendants', () {
      final resolver = ComponentHierarchyResolver({
        'wheel': component('wheel', [onBike('a', 1), onBike('b', 7)]),
        'tire': component('tire', [onComponent('wheel', 2)]),
        'insert': component('insert', [onComponent('tire', 3)]),
      });

      expect(resolver.effectiveBikeSinceAt('insert', day(4)), day(3));
      expect(resolver.bikeAt('insert', day(8)), 'b');
      expect(resolver.effectiveBikeSinceAt('insert', day(8)), day(7));
    });

    test('archived ancestor archives descendants only while archived', () {
      final resolver = ComponentHierarchyResolver({
        'wheel': component('wheel', [onBike('bike', 1), archived(4), onBike('bike', 8)]),
        'tire': component('tire', [onComponent('wheel', 1)]),
        'insert': component('insert', [onComponent('tire', 1)]),
      });

      expect(resolver.isEffectivelyArchived('insert', atUTC: day(3)), isFalse);
      expect(resolver.isEffectivelyArchived('insert', atUTC: day(5)), isTrue);
      expect(resolver.rootAt('insert', day(5)), isA<ArchivedAncestor>());
      expect(resolver.isEffectivelyArchived('insert', atUTC: day(9)), isFalse);
      expect(resolver.bikeAt('insert', day(9)), 'bike');
    });

    test('unsorted installation lists resolve like sorted ones', () {
      final resolver = ComponentHierarchyResolver({
        'fork': component('fork', [onBike('b', 5), uninstalled(9), onBike('a', 1)]),
        'damper': component('damper', [onComponent('fork', 2)]),
      });

      expect(resolver.bikeAt('damper', day(3)), 'a');
      expect(resolver.bikeAt('damper', day(6)), 'b');
      expect(resolver.bikeAt('damper', day(10)), isNull);
      expect(resolver.currentInstallation('fork'), isA<Uninstallation>());
      expect(resolver.inheritedRootChanges('damper'), hasLength(2));
    });

    test('local query times are treated as the same instant in UTC', () {
      final resolver = ComponentHierarchyResolver({
        'fork': component('fork', [onBike('a', 1), onBike('b', 5)]),
        'damper': component('damper', [onComponent('fork', 1)]),
      });

      expect(resolver.bikeAt('damper', day(5).toLocal()), 'b');
      expect(resolver.bikeAt('damper', day(5).subtract(const Duration(minutes: 1)).toLocal()), 'a');
    });

    test('rejects events within the same minute', () {
      // Installation timestamps are truncated to the minute.
      final resolver = ComponentHierarchyResolver({
        'a': component('a', [
          BikeInstallation(
            bikeId: 'bike',
            dateTimeUTC: DateTime.utc(2026, 1, 1, 10, 0, 10),
            dateTimeLocal: DateTime(2026, 1, 1, 10, 0, 10),
          ),
          Uninstallation(
            dateTimeUTC: DateTime.utc(2026, 1, 1, 10, 0, 50),
            dateTimeLocal: DateTime(2026, 1, 1, 10, 0, 50),
          ),
        ]),
      });

      expect(
        resolver.validate,
        throwsA(isA<ComponentHierarchyValidationException>()
            .having((e) => e.componentIds, 'componentIds', {'a'})
            .having((e) => e.dateTimeUTC, 'dateTimeUTC', DateTime.utc(2026, 1, 1, 10))),
      );
    });

    test('same timestamp on different components is valid', () {
      final resolver = ComponentHierarchyResolver({
        'wheel': component('wheel', [onBike('bike', 1)]),
        'tire': component('tire', [onComponent('wheel', 1)]),
      });

      expect(resolver.validate, returnsNormally);
    });
  });

  group('deep nesting', () {
    const depth = 200;
    String id(int level) => 'c$level';

    test('resolves a long chain end to end', () {
      final resolver = ComponentHierarchyResolver({
        id(0): component(id(0), [onBike('bike', 1)]),
        for (var level = 1; level < depth; level++)
          id(level): component(id(level), [onComponent(id(level - 1), 1)]),
      });

      final leaf = id(depth - 1);
      expect(resolver.bikeAt(leaf, day(2)), 'bike');
      expect(resolver.ancestorsAt(leaf, day(2)), hasLength(depth));
      expect(resolver.descendantsOf(id(0), atUTC: day(2)), hasLength(depth - 1));
      expect(resolver.validate, returnsNormally);
    });

    test('detects a cycle closing a long chain', () {
      final resolver = ComponentHierarchyResolver({
        id(0): component(id(0), [onBike('bike', 1), onComponent(id(depth - 1), 3)]),
        for (var level = 1; level < depth; level++)
          id(level): component(id(level), [onComponent(id(level - 1), 2)]),
      });

      expect(resolver.bikeAt(id(depth - 1), day(2)), 'bike');
      expect(resolver.resolveAt(id(depth - 1), day(4)).isCyclic, isTrue);
      expect(parentIds(resolver.ancestorsAt(id(0), day(4))), hasLength(depth - 1));
      expect(
        resolver.validate,
        throwsCycle(componentIds: {for (var level = 0; level < depth; level++) id(level)}, at: day(3)),
      );
    });
  });
}
