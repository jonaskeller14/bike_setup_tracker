import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/services/component_hierarchy_resolver.dart';
import 'package:bike_setup_tracker/utils/installation_timeline_intervals.dart';
import 'package:flutter_test/flutter_test.dart';

Component component(String id, List<Installation> installations) => Component(
  id: id,
  name: id,
  installations: installations,
  componentType: ComponentType.other,
);

DateTime utc(int day) => DateTime.utc(2026, 1, day);

Installation onBike(String bikeId, int day) => BikeInstallation(
  bikeId: bikeId,
  dateTimeUTC: utc(day),
  dateTimeLocal: DateTime(2026, 1, day),
);

Installation onComponent(String parentId, int day) => ComponentInstallation(
  parentComponentId: parentId,
  dateTimeUTC: utc(day),
  dateTimeLocal: DateTime(2026, 1, day),
);

Installation uninstalled(int day) => Uninstallation(
  dateTimeUTC: utc(day),
  dateTimeLocal: DateTime(2026, 1, day),
);

Map<String, List<TimelineInterval>> intervalsFor(
  List<Component> components, {
  String bikeId = 'bike',
}) {
  final resolver = ComponentHierarchyResolver({for (final c in components) c.id: c});
  return effectiveBikeIntervals(resolver, components, bikeId);
}

void main() {
  group('effectiveBikeIntervals', () {
    test('direct install and removal yield one closed interval', () {
      final result = intervalsFor([
        component('fork', [onBike('bike', 1), uninstalled(5)]),
      ]);

      final interval = result['fork']!.single;
      expect(interval.startUTC, utc(1));
      expect(interval.startLocal, DateTime(2026, 1, 1));
      expect(interval.endUTC, utc(5));
      expect(interval.endLocal, DateTime(2026, 1, 5));
      expect(interval.parentComponentId, isNull);
      expect(interval.isNested, isFalse);
    });

    test('current installation is open-ended', () {
      final interval = intervalsFor([
        component('fork', [onBike('bike', 1)]),
      ])['fork']!.single;

      expect(interval.endUTC, isNull);
      expect(interval.endLocal, isNull);
    });

    test('periods on other bikes are skipped and components never on the bike omitted', () {
      final result = intervalsFor([
        component('fork', [onBike('bike', 1), onBike('other', 3), onBike('bike', 5)]),
        component('shock', [onBike('other', 1)]),
      ]);

      expect(result.keys, ['fork']);
      expect(result['fork']!.map((i) => (i.startUTC, i.endUTC)), [
        (utc(1), utc(3)),
        (utc(5), null),
      ]);
    });

    test('child on a parent on the bike carries the parent id', () {
      final result = intervalsFor([
        component('wheel', [onBike('bike', 1)]),
        component('tire', [onComponent('wheel', 2)]),
      ]);

      final tire = result['tire']!.single;
      expect(tire.startUTC, utc(2));
      expect(tire.endUTC, isNull);
      expect(tire.parentComponentId, 'wheel');
      expect(tire.isNested, isTrue);
    });

    test('parent leaving the bike ends the child interval without a child event', () {
      final result = intervalsFor([
        component('wheel', [onBike('bike', 1), uninstalled(4)]),
        component('tire', [onComponent('wheel', 2)]),
      ]);

      final tire = result['tire']!.single;
      expect(tire.startUTC, utc(2));
      expect(tire.endUTC, utc(4));
      expect(tire.endLocal, DateTime(2026, 1, 4));
    });

    test('moving between parents splits the interval (D1)', () {
      final result = intervalsFor([
        component('wheelA', [onBike('bike', 1), uninstalled(5)]),
        component('wheelB', [onBike('bike', 5)]),
        component('tire', [onComponent('wheelA', 2), onComponent('wheelB', 5)]),
      ]);

      expect(result['tire']!.map((i) => (i.startUTC, i.endUTC, i.parentComponentId)), [
        (utc(2), utc(5), 'wheelA'),
        (utc(5), null, 'wheelB'),
      ]);
    });

    test('moving from a parent directly onto the bike splits the interval', () {
      final result = intervalsFor([
        component('wheel', [onBike('bike', 1)]),
        component('tire', [onComponent('wheel', 2), onBike('bike', 4)]),
      ]);

      expect(result['tire']!.map((i) => (i.startUTC, i.endUTC, i.parentComponentId)), [
        (utc(2), utc(4), 'wheel'),
        (utc(4), null, null),
      ]);
    });

    test('an ancestor change that keeps the direct parent and bike does not split', () {
      final result = intervalsFor([
        component('wheel', [onBike('bike', 1), onBike('bike', 3)]),
        component('tire', [onComponent('wheel', 2)]),
      ]);

      expect(result['tire']!.single.startUTC, utc(2));
      expect(result['tire']!.single.endUTC, isNull);
    });

    test('child installed before the parent reaches the bike starts with the parent', () {
      final result = intervalsFor([
        component('wheel', [onBike('bike', 3)]),
        component('tire', [onComponent('wheel', 1)]),
      ]);

      final tire = result['tire']!.single;
      expect(tire.startUTC, utc(3));
      expect(tire.startLocal, DateTime(2026, 1, 3));
    });

    test('resolves depth 2 with the direct parent as caption', () {
      final result = intervalsFor([
        component('wheel', [onBike('bike', 1), uninstalled(6)]),
        component('tire', [onComponent('wheel', 2)]),
        component('insert', [onComponent('tire', 3)]),
      ]);

      final insert = result['insert']!.single;
      expect(insert.startUTC, utc(3));
      expect(insert.endUTC, utc(6));
      expect(insert.parentComponentId, 'tire');
    });

    test('dangling and archived parents yield no interval', () {
      final result = intervalsFor([
        component('archivedWheel', [
          Archival(dateTimeUTC: utc(1), dateTimeLocal: DateTime(2026, 1, 1)),
        ]),
        component('tire', [onComponent('missing-wheel', 1)]),
        component('insert', [onComponent('archivedWheel', 2)]),
      ]);

      expect(result, isEmpty);
    });

    test('parent archived while on the bike ends the child interval', () {
      final result = intervalsFor([
        component('wheel', [
          onBike('bike', 1),
          Archival(dateTimeUTC: utc(4), dateTimeLocal: DateTime(2026, 1, 4)),
        ]),
        component('tire', [onComponent('wheel', 2)]),
      ]);

      expect(result['tire']!.single.endUTC, utc(4));
    });

    test('keeps the epoch-0 start of installations from the beginning', () {
      final result = intervalsFor([
        component('wheel', [Installation.sinceBeginning(parent: 'bike')]),
        component('tire', [Installation.componentSinceBeginning(parentComponentId: 'wheel')]),
      ]);

      for (final id in ['wheel', 'tire']) {
        final interval = result[id]!.single;
        expect(interval.startUTC.millisecondsSinceEpoch, 0);
        expect(interval.startLocal.millisecondsSinceEpoch, 0);
      }
    });

    test('a parent-caused boundary keeps the parent event local time', () {
      final removalUTC = DateTime.utc(2026, 1, 4, 10);
      final removalLocal = DateTime(2026, 1, 4, 12);
      final result = intervalsFor([
        component('wheel', [
          onBike('bike', 1),
          Uninstallation(dateTimeUTC: removalUTC, dateTimeLocal: removalLocal),
        ]),
        component('tire', [onComponent('wheel', 2)]),
      ]);

      final tire = result['tire']!.single;
      expect(tire.endUTC, removalUTC);
      expect(tire.endLocal, removalLocal);
    });
  });
}
