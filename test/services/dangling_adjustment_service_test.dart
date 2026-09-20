import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
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
          componentId: 'parent',
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
          componentId: 'child',
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
      tags: {},
      personAdjustmentValues: {},
      bikeAdjustmentValues: {},
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
}
