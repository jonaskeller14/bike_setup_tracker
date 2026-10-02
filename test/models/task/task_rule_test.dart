import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskRule attachments', () {
    final attachments = [
      Attachment(id: 'b', extension: '.pdf', name: 'Service Manual'),
      Attachment(id: 'a', extension: '.jpg', name: 'Torque Chart'),
    ];

    final jsonVersion1 = {
      'version': 1,
      'id': 'rule1',
      'isDeleted': false,
      'lastModified': '2026-01-01T00:00:00Z',
      'name': 'Service fork',
      'tags': <String>[],
      'componentId': 'c1',
      'bikeId': null,
    };

    final jsonVersion2 = {
      'version': 2,
      'id': 'rule1',
      'isDeleted': false,
      'lastModified': '2026-01-01T00:00:00Z',
      'name': 'Service fork',
      'tags': <String>[],
      'association': const ComponentTaskAssociation('c1').toJson(),
    };

    test('Version 3: fromJson() / toJson() roundtrips attachments in order', () {
      final rule = TaskRule(name: 'Service fork', tags: const {}, attachments: attachments);
      final json = rule.toJson();
      expect(json['version'], 3);
      final restored = TaskRule.fromJson(json);
      expect(restored, rule);
      expect(restored.attachments.map((a) => a.id), ['b', 'a']);
    });

    test('Version 1: fromJson() reads an empty list', () {
      expect(TaskRule.fromJson(jsonVersion1).attachments, isEmpty);
    });

    test('Version 2: fromJson() reads an empty list', () {
      final rule = TaskRule.fromJson(jsonVersion2);
      expect(rule.association, const ComponentTaskAssociation('c1'));
      expect(rule.attachments, isEmpty);
    });

    test('Version -1: fromJson() should throw exception for unknown version', () {
      expect(() => TaskRule.fromJson({...jsonVersion2, 'version': -1}), throwsException);
    });

    test('attachments take part in equality', () {
      final rule = TaskRule(id: 'rule1', name: 'Service fork', tags: const {}, lastModified: DateTime.utc(2026));
      final withAttachments = rule.copyWith(attachments: attachments);
      expect(withAttachments.attachments, attachments);
      expect(withAttachments == rule, isFalse);
      expect(withAttachments.hashCode == rule.hashCode, isFalse);
      expect(withAttachments.copyWith(attachments: <Attachment>[]), rule);
    });

    test('copyWith keeps the attachments when they are not passed', () {
      final rule = TaskRule(name: 'Service fork', tags: const {}, attachments: attachments);
      expect(rule.copyWith(name: 'Service shock').attachments, attachments);
    });

    test('deepCopy copies the attachments list', () {
      final copy = TaskRule(name: 'Service fork', tags: const {}, attachments: attachments).deepCopy();
      expect(copy.attachments, attachments);
      expect(identical(copy.attachments, attachments), isFalse);
    });
  });
}
