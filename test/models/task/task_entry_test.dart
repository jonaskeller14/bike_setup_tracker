import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/task/task_association.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskEntry attachments', () {
    final attachments = [
      Attachment(id: 'b', extension: '.pdf', name: 'Invoice'),
      Attachment(id: 'a', extension: '.jpg', name: 'IMG_1234.jpg'),
    ];

    final jsonVersion1 = {
      'version': 1,
      'id': 'entry1',
      'isDeleted': false,
      'lastModified': '2026-01-01T00:00:00Z',
      'name': 'Fork serviced',
      'dateTimeUTC': '2026-01-01T10:00:00Z',
      'dateTimeLocal': '2026-01-01T11:00:00',
      'taskRule': 'rule1',
      'componentId': 'c1',
      'bikeId': null,
    };

    final jsonVersion2 = {
      'version': 2,
      'id': 'entry1',
      'isDeleted': false,
      'lastModified': '2026-01-01T00:00:00Z',
      'name': 'Fork serviced',
      'dateTimeUTC': '2026-01-01T10:00:00Z',
      'dateTimeLocal': '2026-01-01T11:00:00',
      'taskRule': 'rule1',
      'association': const ComponentTaskAssociation('c1').toJson(),
    };

    TaskEntry build({List<Attachment>? attachments}) => TaskEntry(
      id: 'entry1',
      lastModified: DateTime.utc(2026),
      name: 'Fork serviced',
      dateTimeUTC: DateTime.utc(2026, 1, 1, 10),
      dateTimeLocal: DateTime(2026, 1, 1, 11),
      taskRule: 'rule1',
      attachments: attachments,
    );

    test('Version 3: fromJson() / toJson() roundtrips attachments in order', () {
      final entry = build(attachments: attachments);
      final json = entry.toJson();
      expect(json['version'], 3);
      final restored = TaskEntry.fromJson(json);
      expect(restored, entry);
      expect(restored.attachments.map((a) => a.id), ['b', 'a']);
    });

    test('Version 1: fromJson() reads an empty list', () {
      expect(TaskEntry.fromJson(jsonVersion1).attachments, isEmpty);
    });

    test('Version 2: fromJson() reads an empty list', () {
      final entry = TaskEntry.fromJson(jsonVersion2);
      expect(entry.association, const ComponentTaskAssociation('c1'));
      expect(entry.attachments, isEmpty);
    });

    test('attachments take part in equality', () {
      final entry = build();
      final withAttachments = entry.copyWith(attachments: attachments);
      expect(withAttachments.attachments, attachments);
      expect(withAttachments == entry, isFalse);
      expect(withAttachments.hashCode == entry.hashCode, isFalse);
      expect(withAttachments.copyWith(attachments: <Attachment>[]), entry);
    });

    test('copyWith keeps the attachments when they are not passed', () {
      expect(build(attachments: attachments).copyWith(name: 'Shock serviced').attachments, attachments);
    });
  });
}
