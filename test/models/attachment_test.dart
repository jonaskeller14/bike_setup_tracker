import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Attachment', () {
    test('defaults id to a unique UUID', () {
      final a = Attachment(extension: '.jpg', name: 'x.jpg');
      final b = Attachment(extension: '.jpg', name: 'x.jpg');

      expect(a.id, isNotEmpty);
      expect(a.id, isNot(b.id));
    });

    test('filename is id plus lower-cased extension', () {
      expect(Attachment(id: 'a1', extension: '.PDF', name: 'm').filename, 'a1.pdf');
      expect(Attachment(id: 'a1', extension: '', name: 'm').filename, 'a1');
    });

    test('JSON round trip', () {
      final attachment = Attachment(
        id: 'a1',
        extension: '.pdf',
        name: 'Fox 38 Service Manual',
      );

      final restored = Attachment.fromJson(attachment.toJson());

      expect(restored, attachment);
      expect(restored.hashCode, attachment.hashCode);
    });

    test('tryFromJson returns null for malformed input', () {
      expect(Attachment.tryFromJson('nope'), isNull);
      expect(Attachment.tryFromJson({'id': 'a', 'extension': '.jpg'}), isNull);
      expect(
        Attachment.tryFromJson({'id': 1, 'extension': '.jpg', 'name': 'n'}),
        isNull,
      );
      expect(
        Attachment.tryFromJson({'id': '', 'extension': '.jpg', 'name': 'n'}),
        isNull,
      );
      expect(
        Attachment.tryFromJson({'id': 'a', 'extension': '', 'name': 'n'}),
        Attachment(id: 'a', extension: '', name: 'n'),
      );
    });

    test('equality compares all fields', () {
      final base = Attachment(id: 'a', extension: '.jpg', name: 'n');

      expect(base, Attachment(id: 'a', extension: '.jpg', name: 'n'));
      expect(base, isNot(base.copyWith(id: 'b')));
      expect(base, isNot(base.copyWith(extension: '.png')));
      expect(base, isNot(base.copyWith(name: 'm')));
    });

    test('copyWith keeps untouched fields', () {
      final base = Attachment(id: 'a', extension: '.jpg', name: 'n');
      final renamed = base.copyWith(name: 'Renamed');

      expect(renamed.id, 'a');
      expect(renamed.extension, '.jpg');
      expect(renamed.name, 'Renamed');
    });

    group('isImage', () {
      test('detects image extensions case-insensitively', () {
        for (final extension in [
          '.jpg',
          '.JPG',
          '.jpeg',
          '.Png',
          '.gif',
          '.webp',
          '.HEIC',
          '.heif',
          '.bmp',
        ]) {
          expect(
            Attachment(extension: extension, name: 'a').isImage,
            isTrue,
            reason: extension,
          );
        }
      });

      test('is false for other and extension-less files', () {
        for (final extension in ['.pdf', '.txt', '']) {
          expect(
            Attachment(extension: extension, name: 'a').isImage,
            isFalse,
            reason: extension,
          );
        }
      });
    });

    test('iconData', () {
      expect(
        Attachment(extension: '.PDF', name: 'a').iconData,
        Icons.picture_as_pdf,
      );
      expect(
        Attachment(extension: '.zip', name: 'a').iconData,
        Icons.insert_drive_file_outlined,
      );
    });

    group('exportFileName', () {
      test('keeps a name that already has the stored extension', () {
        expect(
          Attachment(extension: '.jpg', name: 'IMG_1234.JPG').exportFileName,
          'IMG_1234.JPG',
        );
      });

      test('appends the stored extension when the name has none', () {
        expect(
          Attachment(
            extension: '.pdf',
            name: 'Fox 38 Service Manual',
          ).exportFileName,
          'Fox 38 Service Manual.pdf',
        );
      });

      test('appends the stored extension after a dotted name', () {
        expect(
          Attachment(extension: '.pdf', name: 'Manual v2.1').exportFileName,
          'Manual v2.1.pdf',
        );
      });

      test('leaves the name alone for extension-less files', () {
        expect(
          Attachment(extension: '', name: 'README').exportFileName,
          'README',
        );
      });

      test('replaces path-illegal characters', () {
        expect(
          Attachment(
            extension: '.pdf',
            name: r'a/b\c:d*e?f"g<h>i|j',
          ).exportFileName,
          'a_b_c_d_e_f_g_h_i_j.pdf',
        );
      });

      test('falls back to the filename for a blank name', () {
        expect(
          Attachment(id: 'u', extension: '.pdf', name: '  ').exportFileName,
          'u.pdf',
        );
      });
    });
  });
}
