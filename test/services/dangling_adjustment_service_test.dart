import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/services/component_hierarchy_resolver.dart';
import 'package:bike_setup_tracker/services/dangling_adjustment_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isInstalledAtSetup', () {
    final parentSince = DateTime.utc(2026, 1, 5);
    final childSince = DateTime.utc(2026, 1, 4);
    final parent = Component(
      id: 'parent',
      name: 'parent',
      componentType: ComponentType.other,
      installations: [
        BikeInstallation(
          bikeId: 'bike',
          dateTimeUTC: parentSince,
          dateTimeLocal: parentSince.toLocal(),
        ),
      ],
    );
    final child = Component(
      id: 'child',
      name: 'child',
      componentType: ComponentType.other,
      installations: [
        ComponentInstallation(
          parentComponentId: 'parent',
          dateTimeUTC: childSince,
          dateTimeLocal: childSince.toLocal(),
        ),
      ],
    );
    final hierarchy = ComponentHierarchyResolver({'parent': parent, 'child': child});

    Setup setupAt(DateTime at) => Setup(
      id: 's',
      name: 's',
      datetime: at,
      datetimeLocal: at,
      bike: 'bike',
      person: null,
      tags: const {},
      personAdjustmentValues: const {},
      bikeAdjustmentValues: const {},
    );

    test('subcomponent counts as installed once its parent is on the bike', () {
      final setup = setupAt(DateTime.utc(2026, 1, 10));
      expect(DanglingAdjustmentService.isInstalledAtSetup(hierarchy, child, setup), isTrue);
    });

    test('subcomponent is not installed while its parent is off the bike', () {
      final setup = setupAt(DateTime.utc(2026, 1, 4, 12));
      expect(DanglingAdjustmentService.isInstalledAtSetup(hierarchy, child, setup), isFalse);
    });
  });

  group('analyzeSetup', () {
    test('an unresolved value lands in the deleted values of the bike split', () {
      final lockout = BooleanAdjustment(name: 'Lockout', notes: null, unit: null);
      final fork = Component(
        id: 'fork',
        name: 'Fork',
        componentType: ComponentType.fork,
        adjustments: [lockout],
        installations: [Installation.sinceBeginning(parent: 'bike')],
      );
      final setup = Setup(
        id: 's',
        datetime: DateTime.utc(2026, 1, 10),
        datetimeLocal: DateTime(2026, 1, 10),
        bike: 'bike',
        person: null,
        tags: const {},
        personAdjustmentValues: const {},
        bikeAdjustmentValues: {lockout.id: const BooleanValue(true), 'removed': const UnresolvedValue('5400000000')},
      );

      final breakdown = DanglingAdjustmentService.analyzeSetup(setup: setup, components: [fork], persons: const []);

      expect(breakdown.components, [fork]);
      expect(breakdown.componentSplit.groups, isEmpty);
      expect(breakdown.componentSplit.deletedValues, {'removed': const UnresolvedValue('5400000000')});
    });
  });
}
