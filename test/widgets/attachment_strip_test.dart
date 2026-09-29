import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/attachment_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../overflow_data_generator.dart' show loremIpsum;

void main() {
  Future<void> pumpStrip(
    WidgetTester tester, {
    required List<Attachment> attachments,
    AttachmentStripMode mode = AttachmentStripMode.view,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? materialAppTheme,
        home: Scaffold(
          body: AttachmentStrip(
            attachments: attachments,
            attachmentsDir: 'missing-dir',
            mode: mode,
            onRemove: mode == AttachmentStripMode.edit ? (_) {} : null,
          ),
        ),
      ),
    );
  }

  group('AttachmentStrip', () {
    testWidgets('renders images as thumbnails and other files as icon and name', (tester) async {
      await pumpStrip(
        tester,
        attachments: [
          Attachment(extension: '.jpg', name: 'IMG_1234.jpg'),
          Attachment(extension: '.pdf', name: 'Fox 38 Service Manual'),
        ],
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      expect(find.text('Fox 38 Service Manual'), findsOneWidget);
      expect(find.text('IMG_1234.jpg'), findsNothing);
    });

    for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
      testWidgets('a very long file name stays inside its tile ($label)', (tester) async {
        await pumpStrip(
          tester,
          attachments: [Attachment(extension: '.pdf', name: loremIpsum)],
          theme: theme,
        );

        expect(tester.takeException(), isNull);
        final nameSize = tester.getSize(find.text(loremIpsum));
        expect(nameSize.width, lessThanOrEqualTo(80));
        expect(nameSize.height, lessThanOrEqualTo(80));
      });
    }

    testWidgets('edit mode shows a remove badge per attachment', (tester) async {
      await pumpStrip(
        tester,
        attachments: [
          Attachment(extension: '.jpg', name: 'a.jpg'),
          Attachment(extension: '', name: 'notes'),
        ],
        mode: AttachmentStripMode.edit,
      );

      expect(find.byIcon(Icons.close_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.insert_drive_file_outlined), findsOneWidget);
    });

    testWidgets('view mode shows no remove badges', (tester) async {
      await pumpStrip(
        tester,
        attachments: [Attachment(extension: '.jpg', name: 'a.jpg')],
      );

      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('view mode hides the strip when there are no attachments', (tester) async {
      await pumpStrip(tester, attachments: const []);

      expect(find.byType(ListView), findsNothing);
      expect(tester.getSize(find.byType(AttachmentStrip)), Size.zero);
    });
  });
}
