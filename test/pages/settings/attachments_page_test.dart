import 'dart:async';
import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/settings/attachments_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../overflow_data_generator.dart' show loremIpsum;

void main() {
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late AppDatabase database;
  late AppRepository appRepository;
  late Directory documentsDirectory;

  void mockDocumentsDirectory(Future<Object?> Function() handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (_) => handler(),
    );
  }

  setUp(() {
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    documentsDirectory = Directory.systemTemp.createTempSync('attachments_page_');
    mockDocumentsDirectory(() async => documentsDirectory.path);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      null,
    );
    await appRepository.disposeAndAwaitCancellation();
    await database.close();
    documentsDirectory.deleteSync(recursive: true);
  });

  void storeFile(String filename) {
    File(p.join(documentsDirectory.path, 'attachments', filename))
      ..createSync(recursive: true)
      ..writeAsStringSync('content');
  }

  /// Seeds the database, pumps the page and lets the real folder listing finish.
  Future<void> pumpPage(
    WidgetTester tester, {
    Future<void> Function()? writes,
    ThemeData? theme,
  }) async {
    await tester.runAsync(() async {
      await writes?.call();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appRepository,
        child: MaterialApp(theme: theme ?? materialAppTheme, home: const AttachmentsPage()),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
  }

  Setup setup(String bikeId, List<Attachment> attachments) => Setup(
    tags: {},
    datetime: DateTime(2026).toUtc(),
    datetimeLocal: DateTime(2026),
    bike: bikeId,
    person: null,
    bikeAdjustmentValues: {},
    personAdjustmentValues: {},
    attachments: attachments,
  );

  group('AttachmentsPage', () {
    testWidgets('shows a progress indicator while the folder loads', (tester) async {
      final pending = Completer<Object?>();
      mockDocumentsDirectory(() => pending.future);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appRepository,
          child: MaterialApp(theme: materialAppTheme, home: const AttachmentsPage()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows an error state when the folder cannot be opened', (tester) async {
      mockDocumentsDirectory(() async => throw PlatformException(code: 'unavailable'));

      await pumpPage(tester);

      expect(find.text('Attachments unavailable'), findsOneWidget);
      expect(find.text('The attachments folder could not be opened.'), findsOneWidget);
    });

    testWidgets('shows an empty state without attachments', (tester) async {
      await pumpPage(tester);

      expect(find.text('No attachments yet'), findsOneWidget);
    });

    testWidgets('lists images and files of all owners plus unlinked files', (tester) async {
      final bike = Bike(
        name: 'Bike',
        person: null,
        attachments: [Attachment(extension: '.pdf', name: 'Frame Manual')],
      );
      final photo = Attachment(extension: '.jpg', name: 'IMG_1234.jpg');
      storeFile(bike.attachments.single.filename);
      storeFile(photo.filename);
      storeFile('orphan.txt');

      await pumpPage(
        tester,
        writes: () async {
          await appRepository.addBikes([bike]);
          await appRepository.addSetups([
            setup(bike.id, [photo]),
          ]);
        },
      );

      expect(find.text('Attachments'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      expect(find.text('Frame Manual'), findsOneWidget);
      expect(find.text('orphan.txt'), findsOneWidget);
      expect(find.textContaining('1 attachment is no longer linked to a setup, bike or component'), findsOneWidget);
    });

    for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
      testWidgets('a very long file name stays inside its tile ($label)', (tester) async {
        final bike = Bike(
          name: 'Bike',
          person: null,
          attachments: [Attachment(extension: '.pdf', name: loremIpsum)],
        );

        await pumpPage(tester, writes: () => appRepository.addBikes([bike]), theme: theme);

        expect(tester.takeException(), isNull);
        final tileSize = tester.getSize(find.ancestor(of: find.text(loremIpsum), matching: find.byType(Hero)));
        final nameSize = tester.getSize(find.text(loremIpsum));
        expect(nameSize.width, lessThanOrEqualTo(tileSize.width));
        expect(nameSize.height, lessThanOrEqualTo(tileSize.height));
      });
    }
  });
}
