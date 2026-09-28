import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/services/component_hierarchy_resolver.dart';
import 'package:bike_setup_tracker/services/component_slot.dart';
import 'package:flutter_test/flutter_test.dart';

Component component(String id, ComponentType type, List<Installation> installations) => Component(
  id: id,
  name: id,
  componentType: type,
  installations: installations,
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

ComponentHierarchyResolver resolver(List<Component> components) =>
    ComponentHierarchyResolver({for (final c in components) c.id: c});

void main() {
  group('ComponentSlot', () {
    test('uses type and parent type for equality and label', () {
      const front = ComponentSlot(type: ComponentType.tire, parentType: ComponentType.wheelFront);
      const rear = ComponentSlot(type: ComponentType.tire, parentType: ComponentType.wheelRear);
      const fork = ComponentSlot(type: ComponentType.fork);

      expect(front, const ComponentSlot(type: ComponentType.tire, parentType: ComponentType.wheelFront));
      expect(
        front.hashCode,
        const ComponentSlot(type: ComponentType.tire, parentType: ComponentType.wheelFront).hashCode,
      );
      expect(front, isNot(rear));
      expect(front.label, 'Tire (Front Wheel)');
      expect(fork.label, 'Fork');
    });
  });

  group('slotAt', () {
    late Component frontWheel;
    late Component rearWheel;

    setUp(() {
      frontWheel = component('front-wheel', ComponentType.wheelFront, [onBike('front-wheel', 'bike', 1)]);
      rearWheel = component('rear-wheel', ComponentType.wheelRear, [onBike('rear-wheel', 'bike', 1)]);
    });

    test('has no parent type for a component mounted directly on the bike', () {
      final fork = component('fork', ComponentType.fork, [onBike('fork', 'bike', 1)]);

      expect(slotAt(resolver([fork]), fork, DateTime.utc(2026, 1, 2)), const ComponentSlot(type: ComponentType.fork));
    });

    test('uses the direct parent type for a nested component', () {
      final tire = component('tire', ComponentType.tire, [onComponent('tire', 'front-wheel', 1)]);

      expect(
        slotAt(resolver([frontWheel, tire]), tire, DateTime.utc(2026, 1, 2)),
        const ComponentSlot(type: ComponentType.tire, parentType: ComponentType.wheelFront),
      );
    });

    test('follows the parent at the given time after a rotation', () {
      final tire = component('tire', ComponentType.tire, [
        onComponent('tire', 'front-wheel', 1),
        onComponent('tire', 'rear-wheel', 5),
      ]);
      final hierarchy = resolver([frontWheel, rearWheel, tire]);

      expect(slotAt(hierarchy, tire, DateTime.utc(2026, 1, 3))?.parentType, ComponentType.wheelFront);
      expect(slotAt(hierarchy, tire, DateTime.utc(2026, 1, 6))?.parentType, ComponentType.wheelRear);
    });

    test('falls back to no parent type when the parent is missing', () {
      final tire = component('tire', ComponentType.tire, [onComponent('tire', 'deleted-wheel', 1)]);

      expect(slotAt(resolver([tire]), tire, DateTime.utc(2026, 1, 2)), const ComponentSlot(type: ComponentType.tire));
    });

    test('is null while the component is uninstalled', () {
      final tire = component('tire', ComponentType.tire, [
        onComponent('tire', 'front-wheel', 1),
        uninstalled('tire', 5),
      ]);

      expect(slotAt(resolver([frontWheel, tire]), tire, DateTime.utc(2026, 1, 6)), isNull);
    });
  });
}
