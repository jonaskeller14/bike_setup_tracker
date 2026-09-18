import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskAssociation', () {
    test('fromJson() / toJson() round-trips every variant', () {
      const associations = <TaskAssociation>[
        GeneralTaskAssociation(),
        BikeTaskAssociation('b1'),
        ComponentTaskAssociation('c1'),
      ];
      for (final association in associations) {
        expect(TaskAssociation.fromJson(association.toJson()), association);
      }
    });

    test('fromIds() prefers the component when both ids are present', () {
      expect(
        TaskAssociation.fromIds(componentId: 'c1', bikeId: 'b1'),
        const ComponentTaskAssociation('c1'),
      );
      expect(TaskAssociation.fromIds(bikeId: 'b1'), const BikeTaskAssociation('b1'));
      expect(TaskAssociation.fromIds(), const GeneralTaskAssociation());
    });

    test('fromJson() throws for an unknown type', () {
      expect(() => TaskAssociation.fromJson({'type': 'person', 'id': 'p1'}), throwsArgumentError);
    });
  });

  group('TaskRule association', () {
    final legacyJson = {
      'version': 1,
      'id': 'rule1',
      'isDeleted': false,
      'lastModified': '2026-01-01T00:00:00Z',
      'name': 'Chain wax',
      'tags': <String>[],
      'componentId': 'c1',
      'bikeId': 'b1',
    };

    test('Version 1: flat ids migrate, component preferred over bike', () {
      final rule = TaskRule.fromJson(legacyJson);
      expect(rule.association, const ComponentTaskAssociation('c1'));
    });

    test('Version 2: fromJson() / toJson()', () {
      final ruleA = TaskRule.fromJson(legacyJson);
      final json = ruleA.toJson();
      expect(json['version'], 2);
      expect(json.containsKey('componentId'), false);
      final ruleB = TaskRule.fromJson(json);
      expect(ruleA == ruleB, true);
    });
  });

  group('TaskEntry association', () {
    final legacyJson = {
      'id': 'entry1',
      'isDeleted': false,
      'lastModified': '2026-01-01T00:00:00Z',
      'name': 'Chain wax',
      'dateTimeUTC': '2026-01-01T10:00:00Z',
      'dateTimeLocal': '2026-01-01T11:00:00',
      'taskRule': 'rule1',
      'componentId': 'c1',
      'bikeId': 'b1',
    };

    test('Unversioned: flat ids migrate, component preferred over bike', () {
      final entry = TaskEntry.fromJson(legacyJson);
      expect(entry.association, const ComponentTaskAssociation('c1'));
    });

    test('Version 2: fromJson() / toJson()', () {
      final entryA = TaskEntry.fromJson({...legacyJson, 'componentId': null});
      expect(entryA.association, const BikeTaskAssociation('b1'));
      final json = entryA.toJson();
      expect(json['version'], 2);
      final entryB = TaskEntry.fromJson(json);
      expect(entryA == entryB, true);
    });

    test('Unknown version throws', () {
      expect(() => TaskEntry.fromJson({...legacyJson, 'version': -1}), throwsException);
    });
  });
}
