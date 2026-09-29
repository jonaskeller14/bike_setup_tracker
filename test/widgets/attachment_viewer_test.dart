import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/services/file_save_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/attachment_viewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../overflow_data_generator.dart' show loremIpsum;

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('attachment_viewer_test'));

  tearDown(() => dir.deleteSync(recursive: true));

  Attachment stored(Attachment attachment, {List<int> bytes = const [1, 2, 3]}) {
    File('${dir.path}${Platform.pathSeparator}${attachment.filename}').writeAsBytesSync(bytes);
    return attachment;
  }

  Future<void> pumpViewer(
    WidgetTester tester, {
    required List<Attachment> attachments,
    void Function(int index, String name)? onRename,
    AttachmentOwner? Function(Attachment attachment)? ownerForAttachment,
    FileSaveService? fileSaveService,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? materialAppTheme,
        home: AttachmentViewer(
          attachments: attachments,
          attachmentsDir: dir.path,
          onRename: onRename,
          ownerForAttachment: ownerForAttachment,
          fileSaveService: fileSaveService,
        ),
      ),
    );
  }

  ButtonStyleButton button(WidgetTester tester, String label) => tester.widget<ButtonStyleButton>(
    find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)),
  );

  PopupMenuButton<Object?> shareMenu(WidgetTester tester) =>
      tester.widget<PopupMenuButton<Object?>>(find.byWidgetPredicate((w) => w is PopupMenuButton));

  group('AttachmentViewer', () {
    testWidgets('shows a file card with size and actions for a PDF', (tester) async {
      await pumpViewer(
        tester,
        attachments: [stored(Attachment(extension: '.pdf', name: 'Fox 38 Service Manual'))],
      );

      expect(find.byType(InteractiveViewer), findsNothing);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      expect(find.text('3 B'), findsOneWidget);
      expect(button(tester, 'Share').enabled, isTrue);
      expect(button(tester, 'Save to Files').enabled, isTrue);
      expect(shareMenu(tester).enabled, isTrue);
    });

    testWidgets('shows an image page for a JPG', (tester) async {
      await pumpViewer(
        tester,
        attachments: [Attachment(extension: '.jpg', name: 'IMG_1234.jpg')],
      );

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Save to Files'), findsNothing);
    });

    testWidgets('offers rename only when onRename is given', (tester) async {
      final attachments = [stored(Attachment(extension: '.pdf', name: 'manual.pdf'))];

      await pumpViewer(tester, attachments: attachments);
      expect(find.byTooltip('Rename'), findsNothing);

      await pumpViewer(tester, attachments: attachments, onRename: (_, _) {});
      expect(find.byTooltip('Rename'), findsOneWidget);
    });

    testWidgets('passes the new name to onRename and shows it in the app bar', (tester) async {
      final renamed = <(int, String)>[];
      await pumpViewer(
        tester,
        attachments: [stored(Attachment(extension: '.pdf', name: 'fox38_manual.pdf'))],
        onRename: (index, name) => renamed.add((index, name)),
      );

      await tester.tap(find.byTooltip('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  Fox 38 Service Manual ');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(renamed, [(0, 'Fox 38 Service Manual')]);
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Fox 38 Service Manual')),
        findsOneWidget,
      );
    });

    testWidgets('keeps the old name when the new one is blank', (tester) async {
      var renameCalls = 0;
      await pumpViewer(
        tester,
        attachments: [stored(Attachment(extension: '.pdf', name: 'manual.pdf'))],
        onRename: (_, _) => renameCalls++,
      );

      await tester.tap(find.byTooltip('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(renameCalls, 0);
      expect(find.descendant(of: find.byType(AppBar), matching: find.text('manual.pdf')), findsOneWidget);
    });

    for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
      testWidgets('a very long name stays on one line in the app bar ($label)', (tester) async {
        await pumpViewer(
          tester,
          attachments: [
            stored(Attachment(extension: '.pdf', name: loremIpsum)),
            stored(Attachment(extension: '.pdf', name: 'second.pdf')),
          ],
          onRename: (_, _) {},
          ownerForAttachment: (_) => (type: AttachmentOwnerType.component, id: 'c1'),
          theme: theme,
        );

        expect(tester.takeException(), isNull);
        final title = find.descendant(of: find.byType(AppBar), matching: find.text(loremIpsum));
        final text = tester.widget<Text>(title);
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
        expect(
          tester.getRect(title).right,
          lessThanOrEqualTo(tester.view.physicalSize.width / tester.view.devicePixelRatio),
        );
        expect(find.text('1 / 2'), findsOneWidget);
        expect(find.byTooltip('Show Component'), findsOneWidget);
      });
    }

    testWidgets('a missing file disables share and save', (tester) async {
      await pumpViewer(
        tester,
        attachments: [Attachment(extension: '.pdf', name: 'gone.pdf')],
      );

      expect(find.text('File not found'), findsOneWidget);
      expect(button(tester, 'Share').enabled, isFalse);
      expect(button(tester, 'Save to Files').enabled, isFalse);
      expect(shareMenu(tester).enabled, isFalse);
    });

    testWidgets('Save to Files uses the export file name and extension', (tester) async {
      final saved = Completer<(String, FileType, List<String>?, Uint8List)>();
      final service = FileSaveService(({
        required String fileName,
        required FileType type,
        List<String>? allowedExtensions,
        required Uint8List bytes,
      }) async {
        saved.complete((fileName, type, allowedExtensions, bytes));
        return Uri.file('/saved/$fileName');
      });
      await pumpViewer(
        tester,
        attachments: [stored(Attachment(extension: '.pdf', name: 'Fox 38 Service Manual'))],
        fileSaveService: service,
      );

      await tester.tap(find.text('Save to Files'));
      // The file is read with real I/O, which only completes outside the fake clock.
      for (var i = 0; i < 50 && !saved.isCompleted; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
      await tester.pump();

      final (fileName, type, extensions, bytes) = await saved.future;
      expect(fileName, 'Fox 38 Service Manual.pdf');
      expect(type, FileType.custom);
      expect(extensions, ['pdf']);
      expect(bytes, [1, 2, 3]);
      expect(find.text('File saved'), findsOneWidget);
    });
  });
}
