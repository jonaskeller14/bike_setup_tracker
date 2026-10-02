import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/pages/forms/task_entry_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/attachment_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSubscriptionService extends Mock implements SubscriptionService {
  @override
  bool get hasStravaEntitlement => false;
}

void main() {
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => Directory.systemTemp.path,
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      null,
    );
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await appRepository.disposeAndAwaitCancellation();
    appSettings.dispose();
    await database.close();
  });

  final taskRule = TaskRule(name: 'Lower leg service', tags: const {});
  final invoice = Attachment(id: 'invoice', extension: '.pdf', name: 'Workshop Invoice.pdf');
  final photo = Attachment(id: 'photo', extension: '.pdf', name: 'Seal Photo.pdf');

  TaskEntry entry({List<Attachment>? attachments}) => TaskEntry(
    id: 'e1',
    name: taskRule.name,
    notes: 'Fresh seals',
    dateTimeUTC: DateTime(2026, 5, 1, 10).toUtc(),
    dateTimeLocal: DateTime(2026, 5, 1, 10),
    taskRule: taskRule.id,
    attachments: attachments ?? [invoice, photo],
  );

  Object? result;

  /// Opens [page] on top of a home route, so the saved entry can be read from [result].
  Future<void> openForm(WidgetTester tester, TaskEntryPage Function() page, {ThemeData? theme}) async {
    result = null;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appRepository),
          ChangeNotifierProvider<SubscriptionService>(create: (_) => MockSubscriptionService()),
        ],
        child: MaterialApp(
          theme: theme ?? materialAppTheme,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await Navigator.push(context, MaterialPageRoute<TaskEntry>(builder: (_) => page())),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder attachChip() => find.widgetWithIcon(ActionChip, Icons.attach_file);

  group('TaskEntryPage attachments', () {
    testWidgets('hides the Attach chip and the strip when attachments are disabled', (tester) async {
      await openForm(tester, () => TaskEntryPage.edit(taskEntry: entry(), taskRule: taskRule));

      expect(attachChip(), findsNothing);
      expect(find.byType(AttachmentStrip), findsNothing);
    });

    testWidgets('shows the Attach chip after the time chip and the strip below', (tester) async {
      appSettings.enableAttachments = true;
      await openForm(tester, () => TaskEntryPage.edit(taskEntry: entry(), taskRule: taskRule));

      final wrap = find.ancestor(of: attachChip(), matching: find.byType(Wrap));
      expect(wrap, findsOneWidget);
      expect(
        tester.widget<Wrap>(wrap).children.last,
        isA<ActionChip>().having((c) => c.tooltip, 'tooltip', 'Add Attachment'),
      );
      expect(find.descendant(of: wrap, matching: find.byIcon(Icons.access_time)), findsOneWidget);
      expect(find.byType(AttachmentStrip), findsOneWidget);
      expect(find.text('Workshop Invoice.pdf'), findsOneWidget);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
    });

    testWidgets('add mode offers the chip without a strip', (tester) async {
      appSettings.enableAttachments = true;
      await openForm(tester, () => TaskEntryPage.add(taskRule: taskRule));

      expect(attachChip(), findsOneWidget);
      expect(find.byType(AttachmentStrip), findsNothing);
    });

    for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
      testWidgets('the chips and a long attachment name fit a narrow screen ($label)', (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        appSettings.enableAttachments = true;
        final longName = '${'Very long workshop invoice name ' * 6}.pdf';
        await openForm(
          tester,
          () => TaskEntryPage.edit(
            taskEntry: entry(
              attachments: [
                Attachment(extension: '.pdf', name: longName),
                photo,
              ],
            ),
            taskRule: taskRule,
          ),
          theme: theme,
        );

        expect(attachChip(), findsOneWidget);
        expect(find.text(longName), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('removing an attachment marks the form changed and saving returns the rest', (tester) async {
      appSettings.enableAttachments = true;
      await openForm(tester, () => TaskEntryPage.edit(taskEntry: entry(), taskRule: taskRule));

      Color? chipColor() => tester.widget<ActionChip>(attachChip()).backgroundColor;
      expect(chipColor(), isNull);

      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('Workshop Invoice.pdf'), findsNothing);
      final changedFill = Theme.of(tester.element(attachChip())).extension<ValueHighlightColors>()!.changedFill;
      expect(chipColor(), changedFill);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(result, isA<TaskEntry>());
      final saved = result! as TaskEntry;
      expect(saved.id, 'e1');
      expect(saved.attachments, [photo]);
    });

    testWidgets('saving with attachments disabled keeps the list', (tester) async {
      await openForm(tester, () => TaskEntryPage.edit(taskEntry: entry(), taskRule: taskRule));

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect((result! as TaskEntry).attachments, [invoice, photo]);
    });

    testWidgets('duplicate mode starts without attachments', (tester) async {
      appSettings.enableAttachments = true;
      await openForm(
        tester,
        () => TaskEntryPage.duplicate(
          taskEntry: entry().copyWith(attachments: const <Attachment>[]),
          taskRule: taskRule,
        ),
      );

      expect(attachChip(), findsOneWidget);
      expect(find.byType(AttachmentStrip), findsNothing);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);
    });
  });
}
