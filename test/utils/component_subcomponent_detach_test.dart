import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/component/subcomponent_detach.dart';
import 'package:bike_setup_tracker/utils/component_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime(2026, 3, 1, 12, 30);
  final child = Component(
    id: 'damper',
    name: 'Damper',
    componentType: ComponentType.other,
    installations: [Installation.componentSinceBeginning(parentComponentId: 'fork')],
  );

  group('ComponentActions.detachSubcomponents', () {
    test('uninstall appends an uninstallation at the given time', () {
      final [edited] = ComponentActions.detachSubcomponents(
        [child],
        mode: SubcomponentDetach.uninstall,
        bikeId: 'b1',
        at: at,
      );

      expect(edited.installations, hasLength(2));
      expect(edited.installations.first, child.installations.first);
      expect(edited.installations.last, isA<Uninstallation>());
      expect(edited.installations.last.dateTimeUTC, at.toUtc());
      expect(edited.installations.last.dateTimeLocal, at);
    });

    test('install on bike appends a bike installation', () {
      final [edited] = ComponentActions.detachSubcomponents(
        [child],
        mode: SubcomponentDetach.installOnBike,
        bikeId: 'b1',
        at: at,
      );

      expect(edited.installations.last, isA<BikeInstallation>());
      expect(edited.installations.last.parent, 'b1');
      expect(edited.parentIdAt(at.toUtc()), 'b1');
    });

    test('keep linked edits nothing', () {
      expect(
        ComponentActions.detachSubcomponents([child], mode: SubcomponentDetach.keepLinked, bikeId: 'b1', at: at),
        isEmpty,
      );
    });

    test('moves the event to the next free minute on a collision', () {
      final busy = child.copyWith(
        installations: [
          ComponentInstallation(parentComponentId: 'fork', dateTimeUTC: at.toUtc(), dateTimeLocal: at),
        ],
      );

      final [edited] = ComponentActions.detachSubcomponents(
        [busy],
        mode: SubcomponentDetach.uninstall,
        bikeId: null,
        at: at,
      );

      expect(edited.installations.last.dateTimeUTC, at.toUtc().add(const Duration(minutes: 1)));
    });
  });
}
