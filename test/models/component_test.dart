import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Component Installation Logic', () {
    test('bike returns null when no installations', () {
      final component = Component(
        name: 'Test Component',
        componentType: ComponentType.other,
        installations: [],
      );
      expect(component.parentId, isNull);
    });

    test('bike returns correct bike based on current time', () {
      final now = DateTime.now().toUtc();
      final component = Component(
        name: 'Test Component',
        componentType: ComponentType.other,
        installations: [
          Installation(
            parent: 'bike_1',
            dateTimeUTC: now.subtract(const Duration(days: 2)),
            dateTimeLocal: now.subtract(const Duration(days: 2)).toLocal(),
          ),
          Installation(
            parent: 'bike_2',
            dateTimeUTC: now.subtract(const Duration(days: 1)),
            dateTimeLocal: now.subtract(const Duration(days: 1)).toLocal(),
          ),
        ],
      );
      expect(component.parentId, 'bike_2');
    });

    test('bikeAt returns correct bike for past timestamps', () {
      final now = DateTime(2024, 1, 1).toUtc();
      final t1 = now.add(const Duration(hours: 1));
      final t2 = now.add(const Duration(hours: 2));
      final t3 = now.add(const Duration(hours: 3));

      final component = Component(
        name: 'Test Component',
        componentType: ComponentType.other,
        installations: [
          Installation(
            parent: 'bike_1',
            dateTimeUTC: t1,
            dateTimeLocal: t1.toLocal(),
          ),
          Installation(
            parent: 'bike_2',
            dateTimeUTC: t2,
            dateTimeLocal: t2.toLocal(),
          ),
        ],
      );

      expect(component.parentIdAt(now), isNull, reason: 'Before any installation');
      expect(component.parentIdAt(t1), 'bike_1', reason: 'At t1');
      expect(component.parentIdAt(t1.add(const Duration(minutes: 30))), 'bike_1', reason: 'Between t1 and t2');
      expect(component.parentIdAt(t2), 'bike_2', reason: 'At t2');
      expect(component.parentIdAt(t3), 'bike_2', reason: 'After t2');
    });

    test('isArchived true when latest installation is Archival', () {
      final now = DateTime.now().toUtc();
      final component = Component(
        name: 'Test Component',
        componentType: ComponentType.other,
        installations: [
          Installation.sinceBeginning(parent: 'bike_1'),
          Archival(dateTimeUTC: now, dateTimeLocal: now.toLocal()),
        ],
      );
      expect(component.isArchived, isTrue);
      expect(component.isUninstalled, isFalse);
    });

    test('isUninstalled true when latest installation is Uninstallation', () {
      final now = DateTime.now().toUtc();
      final component = Component(
        name: 'Test Component',
        componentType: ComponentType.other,
        installations: [
          Installation.sinceBeginning(parent: 'bike_1'),
          Uninstallation(dateTimeUTC: now, dateTimeLocal: now.toLocal()),
        ],
      );
      expect(component.isUninstalled, isTrue);
      expect(component.isArchived, isFalse);
    });

    test('isArchived and isUninstalled false when currently installed', () {
      final component = Component(
        name: 'Test Component',
        componentType: ComponentType.other,
        installations: [Installation.sinceBeginning(parent: 'bike_1')],
      );
      expect(component.isArchived, isFalse);
      expect(component.isUninstalled, isFalse);
    });

    test('bikeAt returns null after Archival event', () {
      final t1 = DateTime(2024, 1, 1, 10).toUtc();
      final t2 = DateTime(2024, 1, 1, 12).toUtc();
      final after = DateTime(2024, 1, 1, 14).toUtc();

      final component = Component(
        name: 'Test Component',
        componentType: ComponentType.other,
        installations: [
          Installation(
            parent: 'bike_1',
            dateTimeUTC: t1,
            dateTimeLocal: t1.toLocal(),
          ),
          Archival(dateTimeUTC: t2, dateTimeLocal: t2.toLocal()),
        ],
      );

      expect(component.parentIdAt(t1), 'bike_1');
      expect(
        component.parentIdAt(after),
        isNull,
        reason: 'Archival has no parent — component is not on a bike after archival',
      );
    });

    test('bikeAt handles unsorted installations list', () {
      final t1 = DateTime(2024, 1, 1, 10).toUtc();
      final t2 = DateTime(2024, 1, 1, 12).toUtc();

      final component = Component(
        name: 'Test Component',
        componentType: ComponentType.other,
        installations: [
          Installation(
            parent: 'bike_2',
            dateTimeUTC: t2,
            dateTimeLocal: t2.toLocal(),
          ),
          Installation(
            parent: 'bike_1',
            dateTimeUTC: t1,
            dateTimeLocal: t1.toLocal(),
          ),
        ],
      );

      expect(component.parentIdAt(t1), 'bike_1');
      expect(component.parentIdAt(t2), 'bike_2');
    });
  });

  group('preset provenance', () {
    Component fork() => Component(
          name: 'FOX 36 Factory',
          componentType: ComponentType.fork,
          installations: [],
          presetKey: 'fork-fox-36-factory-2025',
          presetDamperKey: 'grip_x2',
        );

    test('defaults to null for a hand-built component', () {
      final component = Component(
        name: 'Hand built',
        componentType: ComponentType.fork,
        installations: [],
      );
      expect(component.presetKey, isNull);
      expect(component.presetDamperKey, isNull);
    });

    test('deepCopy keeps it — a duplicate is still that preset', () {
      final copy = fork().deepCopy();
      expect(copy.presetKey, 'fork-fox-36-factory-2025');
      expect(copy.presetDamperKey, 'grip_x2');
    });

    test('copyWith leaves it alone, overwrites it, or clears it', () {
      expect(fork().copyWith(name: 'Renamed').presetKey, 'fork-fox-36-factory-2025');
      expect(fork().copyWith(presetKey: 'fork-fox-36-performance-2025').presetKey,
          'fork-fox-36-performance-2025');
      expect(fork().copyWith(presetKey: null).presetKey, isNull);
    });

    test('survives a json round trip', () {
      final restored = Component.fromJson(json: fork().toJson());
      expect(restored.presetKey, 'fork-fox-36-factory-2025');
      expect(restored.presetDamperKey, 'grip_x2');
    });

    test('a backup written before provenance existed reads as null', () {
      final legacy = fork().toJson()
        ..remove('presetKey')
        ..remove('presetDamperKey');
      final restored = Component.fromJson(json: legacy);
      expect(restored.presetKey, isNull);
      expect(restored.presetDamperKey, isNull);
    });

    test('distinguishes two otherwise identical components', () {
      final a = fork();
      final b = a.copyWith(presetDamperKey: 'grip_x');
      expect(a == b, isFalse);
      expect(a.hashCode == b.hashCode, isFalse);
    });
  });
}
