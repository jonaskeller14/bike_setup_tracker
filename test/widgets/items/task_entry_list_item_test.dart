import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/attachment_strip.dart';
import 'package:bike_setup_tracker/widgets/attachment_viewer.dart';
import 'package:bike_setup_tracker/widgets/items/task_entry_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../overflow_data_generator.dart' show loremIpsum;

class MockSubscriptionService extends Mock implements SubscriptionService {
  @override
  bool get hasStravaEntitlement => false;
}

void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
    appSettings.enableAttachments = true;
  });

  tearDown(() async {
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await appRepository.disposeAndAwaitCancellation();
    appSettings.dispose();
    await database.close();
  });

  final taskRule = TaskRule(name: 'Lower leg service', tags: const {});
  final invoice = Attachment(id: 'invoice', extension: '.pdf', name: 'Workshop Invoice');
  final photo = Attachment(id: 'photo', extension: '.pdf', name: 'Seal Photo');

  /// Seeds one entry with [attachments] and pumps its list item.
  Future<void> pumpItem(
    WidgetTester tester, {
    List<Attachment>? attachments,
    bool showAttachments = false,
    String? attachmentsDir,
    bool selectionMode = false,
    VoidCallback? onTap,
    ThemeData? theme,
  }) async {
    final taskEntry = TaskEntry(
      id: 'e1',
      name: taskRule.name,
      notes: 'Fresh seals',
      dateTimeUTC: DateTime(2026, 5, 1, 10).toUtc(),
      dateTimeLocal: DateTime(2026, 5, 1, 10),
      taskRule: taskRule.id,
      attachments: attachments ?? [invoice, photo],
    );
    await tester.runAsync(() async {
      await database.into(database.taskRules).insert(taskRule.toCompanion());
      await database.into(database.taskEntries).insert(taskEntry.toCompanion());
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appRepository),
          ChangeNotifierProvider<SubscriptionService>(create: (_) => MockSubscriptionService()),
        ],
        child: MaterialApp(
          theme: theme ?? materialAppTheme,
          home: Scaffold(
            body: TaskEntryListItem(
              taskEntryId: taskEntry.id,
              showAttachments: showAttachments,
              attachmentsDir: attachmentsDir,
              selectionMode: selectionMode,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
    // The database streams deliver with real I/O, which only completes outside the fake clock.
    for (var attempts = 0; appRepository.taskEntries.isEmpty && attempts < 100; attempts++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('Fresh seals'), findsOneWidget);
  }

  Finder count(String text) => find.descendant(
    of: find.ancestor(of: find.byIcon(Icons.attach_file), matching: find.byType(Row)).first,
    matching: find.text(text),
  );

  group('TaskEntryListItem attachments', () {
    testWidgets('shows a paperclip and count without showAttachments', (tester) async {
      await pumpItem(tester);

      expect(count('2'), findsOneWidget);
      expect(find.byType(AttachmentStrip), findsNothing);
    });

    testWidgets('falls back to the count while the directory is unknown', (tester) async {
      await pumpItem(tester, showAttachments: true);

      expect(count('2'), findsOneWidget);
      expect(find.byType(AttachmentStrip), findsNothing);
    });

    testWidgets('shows the strip instead of the count with showAttachments', (tester) async {
      await pumpItem(tester, showAttachments: true, attachmentsDir: 'missing-dir');

      expect(find.byType(AttachmentStrip), findsOneWidget);
      expect(find.text('Workshop Invoice'), findsOneWidget);
      expect(find.text('Seal Photo'), findsOneWidget);
      expect(find.byIcon(Icons.attach_file), findsNothing);
    });

    testWidgets('shows nothing for an entry without attachments', (tester) async {
      await pumpItem(tester, attachments: const [], showAttachments: true, attachmentsDir: 'missing-dir');

      expect(find.byIcon(Icons.attach_file), findsNothing);
      expect(find.byType(AttachmentStrip), findsNothing);
    });

    for (final showAttachments in [false, true]) {
      testWidgets('shows nothing with attachments disabled (showAttachments: $showAttachments)', (tester) async {
        appSettings.enableAttachments = false;
        await pumpItem(tester, showAttachments: showAttachments, attachmentsDir: 'missing-dir');

        expect(find.byIcon(Icons.attach_file), findsNothing);
        expect(find.byType(AttachmentStrip), findsNothing);
      });
    }

    for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
      testWidgets('a very long file name stays inside its tile on a narrow screen ($label)', (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpItem(
          tester,
          attachments: [
            Attachment(extension: '.pdf', name: loremIpsum),
            invoice,
            photo,
          ],
          showAttachments: true,
          attachmentsDir: 'missing-dir',
          theme: theme,
        );

        expect(tester.takeException(), isNull);
        final nameSize = tester.getSize(find.text(loremIpsum));
        expect(nameSize.width, lessThanOrEqualTo(80));
        expect(nameSize.height, lessThanOrEqualTo(80));
      });
    }

    testWidgets('a tap on a thumbnail opens the viewer', (tester) async {
      var taps = 0;
      await pumpItem(tester, showAttachments: true, attachmentsDir: 'missing-dir', onTap: () => taps++);

      await tester.tapAt(tester.getCenter(find.text('Workshop Invoice')));
      await tester.pumpAndSettle();

      expect(find.byType(AttachmentViewer), findsOneWidget);
      expect(taps, 0);
    });

    testWidgets('in selection mode a tap on a thumbnail calls onTap', (tester) async {
      var taps = 0;
      await pumpItem(
        tester,
        showAttachments: true,
        attachmentsDir: 'missing-dir',
        selectionMode: true,
        onTap: () => taps++,
      );

      await tester.tapAt(tester.getCenter(find.text('Workshop Invoice')));
      await tester.pumpAndSettle();

      expect(find.byType(AttachmentViewer), findsNothing);
      expect(taps, 1);
    });
  });
}
