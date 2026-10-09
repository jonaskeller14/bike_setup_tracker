import 'dart:convert';

import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/component_preset.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Component Installation Logic', () {
    test('bike returns null when no installations', () {
      final component = Component(
        name: 'Test Component',
        componentType: ComponentType.other,
        installations: const [],
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
    final preset = ComponentPreset(const {
      'brand': 'fox',
      'component_type': 'fork',
      'model': '36',
      'generation': '2025',
      'trim': 'factory',
      'damper': 'grip_x2',
      'travel_mm': 160,
    });

    Component fork() => Component(
          name: 'FOX 36 Factory',
          componentType: ComponentType.fork,
          installations: const [],
          preset: preset,
        );

    test('defaults to null for a hand-built component', () {
      final component = Component(
        name: 'Hand built',
        componentType: ComponentType.fork,
        installations: const [],
      );
      expect(component.preset, isNull);
    });

    test('deepCopy keeps it — a duplicate is still that preset', () {
      expect(fork().deepCopy().preset, preset);
    });

    test('copyWith leaves it alone, overwrites it, or clears it', () {
      final other = ComponentPreset({...preset.toJson(), 'damper': 'grip_x'});
      expect(fork().copyWith(name: 'Renamed').preset, preset);
      expect(fork().copyWith(preset: other).preset, other);
      expect(fork().copyWith(preset: null).preset, isNull);
    });

    test('survives a json round trip, numbers included', () {
      final restored = Component.fromJson(json: jsonDecode(jsonEncode(fork().toJson())) as Map<String, dynamic>);
      expect(restored.preset, preset);
    });

    test('a backup written before the preset existed reads as null', () {
      final legacy = fork().toJson()..remove('preset');
      expect(Component.fromJson(json: legacy).preset, isNull);
    });

    test('a v1.6.0 backup with presetKey / presetDamperKey imports without a preset', () {
      final legacy = fork().toJson()
        ..remove('preset')
        ..['presetKey'] = 'fork-fox-36-factory-2025'
        ..['presetDamperKey'] = 'grip_x2';
      expect(Component.fromJson(json: legacy).preset, isNull);
    });

    test('a malformed preset reads as null', () {
      final json = fork().toJson()..['preset'] = 'fox';
      expect(Component.fromJson(json: json).preset, isNull);
    });

    test('distinguishes two otherwise identical components', () {
      final a = fork();
      final b = a.copyWith(preset: ComponentPreset({...preset.toJson(), 'damper': 'grip_x'}));
      expect(a == b, isFalse);
      expect(a.hashCode == b.hashCode, isFalse);
    });
  });

  group('attachments', () {
    Component fork() => Component(
          name: 'FOX 36 Factory',
          componentType: ComponentType.fork,
          installations: const [],
          attachments: [
            Attachment(id: 'm', extension: '.pdf', name: 'Service Manual'),
            Attachment(id: 'p', extension: '.jpg', name: 'IMG_1.jpg'),
          ],
        );

    test('default to an empty list', () {
      final component = Component(name: 'Fork', componentType: ComponentType.fork, installations: const []);
      expect(component.attachments, isEmpty);
    });

    test('survive a json round trip in order', () {
      final json = fork().toJson();
      expect(json['version'], 6);
      final restored = Component.fromJson(json: json);
      expect(restored.attachments, fork().attachments);
      expect(restored.attachments.map((a) => a.id), ['m', 'p']);
    });

    test('a backup written before attachments existed reads as empty', () {
      final legacy = fork().toJson()
        ..['version'] = 5
        ..remove('attachments');
      expect(Component.fromJson(json: legacy).attachments, isEmpty);
    });

    test('deepCopy copies the list', () {
      final original = fork();
      final copy = original.deepCopy();
      expect(copy.attachments, original.attachments);
      expect(identical(copy.attachments, original.attachments), isFalse);
    });

    test('take part in equality', () {
      final a = fork();
      final b = a.copyWith(attachments: a.attachments.reversed.toList());
      expect(a == b, isFalse);
      expect(a.hashCode == b.hashCode, isFalse);
      expect(a.copyWith(attachments: List.of(a.attachments)), a);
    });
  });
}
