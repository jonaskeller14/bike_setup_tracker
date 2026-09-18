import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
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
}
