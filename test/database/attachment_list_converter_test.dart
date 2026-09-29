import 'dart:convert';

import 'package:bike_setup_tracker/database/converters/attachment_list_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const converter = AttachmentListConverter();

  group('AttachmentListConverter', () {
    test('empty list', () {
      expect(converter.fromSql(''), isEmpty);
      expect(converter.fromSql('[]'), isEmpty);
      expect(converter.toSql([]), '[]');
    });

    test('round trip preserves order', () {
      final attachments = [
        Attachment(id: 'c', extension: '.pdf', name: 'Manual'),
        Attachment(id: 'a', extension: '.jpg', name: 'IMG_1.jpg'),
        Attachment(id: 'b', extension: '.png', name: 'Screenshot'),
      ];

      expect(converter.fromSql(converter.toSql(attachments)), attachments);
    });

    test('skips malformed entries', () {
      final sql = jsonEncode([
        {'id': 'a', 'extension': '.jpg', 'name': 'A'},
        'legacy-image.jpg',
        {'id': 'b', 'extension': '.pdf'},
        null,
        {'id': 'c', 'extension': '.pdf', 'name': 'C'},
      ]);

      expect(converter.fromSql(sql), [
        Attachment(id: 'a', extension: '.jpg', name: 'A'),
        Attachment(id: 'c', extension: '.pdf', name: 'C'),
      ]);
    });

    test('non-list JSON yields an empty list', () {
      expect(converter.fromSql('{"id": "a"}'), isEmpty);
    });
  });
}
