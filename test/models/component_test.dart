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
      expect(component.bike, isNull);
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
      expect(component.bike, 'bike_2');
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

      expect(component.bikeAt(now), isNull, reason: 'Before any installation');
      expect(component.bikeAt(t1), 'bike_1', reason: 'At t1');
      expect(component.bikeAt(t1.add(const Duration(minutes: 30))), 'bike_1', reason: 'Between t1 and t2');
      expect(component.bikeAt(t2), 'bike_2', reason: 'At t2');
      expect(component.bikeAt(t3), 'bike_2', reason: 'After t2');
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

      expect(component.bikeAt(t1), 'bike_1');
      expect(
        component.bikeAt(after),
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

      expect(component.bikeAt(t1), 'bike_1');
      expect(component.bikeAt(t2), 'bike_2');
    });
  });
}
