import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/pages/forms/task_entry_page.dart';
import 'package:bike_setup_tracker/pages/forms/task_rule_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/task_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
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
  late Directory documentsDirectory;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
    documentsDirectory = Directory.systemTemp.createTempSync('task_actions_docs_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => call.method == 'getApplicationDocumentsDirectory' ? documentsDirectory.path : null,
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
    documentsDirectory.deleteSync(recursive: true);
  });

  File file(Attachment attachment) => File(p.join(documentsDirectory.path, 'attachments', attachment.filename));

  Attachment stored(String name) {
    final attachment = Attachment(extension: '.pdf', name: name);
    file(attachment)
      ..createSync(recursive: true)
      ..writeAsStringSync(name);
    return attachment;
  }

  // Seeded with an old `lastModified`, which the database keeps to the second,
  // so a later edit is always visible as a change.
  final seededAt = DateTime.utc(2026);

  TaskRule rule(List<Attachment> attachments) =>
      TaskRule(name: 'Lower leg service', tags: const {}, lastModified: seededAt, attachments: attachments);

  TaskEntry entry(TaskRule rule, List<Attachment> attachments) => TaskEntry(
    name: rule.name,
    notes: 'Fresh seals',
    dateTimeUTC: DateTime(2026, 5, 1, 10).toUtc(),
    dateTimeLocal: DateTime(2026, 5, 1, 10),
    taskRule: rule.id,
    lastModified: seededAt,
    attachments: attachments,
  );

  /// Database writes and file operations are real I/O, which only completes
  /// outside the fake clock.
  Future<void> settle(WidgetTester tester, bool Function() until) async {
    for (var attempts = 0; !until() && attempts < 100; attempts++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  /// Seeds the database and opens the form of [action] with a tap.
  Future<void> runAction(
    WidgetTester tester,
    Future<void> Function(BuildContext context) action, {
    required Type form,
    List<TaskRule> rules = const [],
    List<TaskEntry> entries = const [],
  }) async {
    await tester.runAsync(() async {
      for (final rule in rules) {
        await database.into(database.taskRules).insert(rule.toCompanion());
      }
      for (final entry in entries) {
        await database.into(database.taskEntries).insert(entry.toCompanion());
      }
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appRepository),
          ChangeNotifierProvider<SubscriptionService>(create: (_) => MockSubscriptionService()),
        ],
        child: MaterialApp(
          theme: materialAppTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(onPressed: () => action(context), child: const Text('run')),
            ),
          ),
        ),
      ),
    );
    await settle(
      tester,
      () => appRepository.taskRules.length == rules.length && appRepository.taskEntries.length == entries.length,
    );

    await tester.tap(find.text('run'));
    await settle(tester, () => find.byType(form).evaluate().isNotEmpty);
    expect(find.byType(form), findsOneWidget);
  }

  void popForm(WidgetTester tester, Object? result) => tester.state<NavigatorState>(find.byType(Navigator)).pop(result);

  group('TaskActions.editTaskRule', () {
    testWidgets('keeps the attachments and files of a rule saved unchanged', (tester) async {
      final manual = stored('Service Manual');
      final taskRule = rule([manual]);
      await runAction(
        tester,
        (context) => TaskActions.editTaskRule(context, taskRule: taskRule),
        form: TaskRulePage,
        rules: [taskRule],
      );

      await tester.tap(find.byIcon(Icons.check));
      await settle(tester, () => appRepository.taskRules[taskRule.id]!.lastModified != seededAt);
      expect(appRepository.taskRules[taskRule.id]!.lastModified, isNot(seededAt));

      expect(find.byType(TaskRulePage), findsNothing);
      expect(appRepository.taskRules[taskRule.id]!.attachments, [manual]);
      expect(file(manual).existsSync(), isTrue);
    });

    testWidgets('deletes the files of attachments removed in the form', (tester) async {
      final manual = stored('Service Manual');
      final chart = stored('Torque Chart');
      final taskRule = rule([manual, chart]);
      await runAction(
        tester,
        (context) => TaskActions.editTaskRule(context, taskRule: taskRule),
        form: TaskRulePage,
        rules: [taskRule],
      );

      popForm(tester, taskRule.copyWith(attachments: [chart]));
      await settle(tester, () => !file(manual).existsSync());

      expect(file(manual).existsSync(), isFalse);
      expect(file(chart).existsSync(), isTrue);
      expect(appRepository.taskRules[taskRule.id]!.attachments, [chart]);
    });
  });

  group('TaskActions.duplicateTaskRule', () {
    testWidgets('hands copied files to the form and deletes them when it is discarded', (tester) async {
      final manual = stored('Service Manual');
      final taskRule = rule([manual]);
      await runAction(
        tester,
        (context) => TaskActions.duplicateTaskRule(context, taskRule: taskRule),
        form: TaskRulePage,
        rules: [taskRule],
      );

      final copy = tester.widget<TaskRulePage>(find.byType(TaskRulePage)).taskRule!.attachments.single;
      expect(copy.id, isNot(manual.id));
      expect(copy.name, manual.name);
      expect(file(copy).readAsStringSync(), 'Service Manual');

      await tester.pageBack();
      await settle(tester, () => !file(copy).existsSync());

      expect(file(copy).existsSync(), isFalse);
      expect(file(manual).existsSync(), isTrue);
      expect(appRepository.taskRules.keys, [taskRule.id]);
    });

    testWidgets('a saved duplicate owns the copied files', (tester) async {
      final manual = stored('Service Manual');
      final taskRule = rule([manual]);
      await runAction(
        tester,
        (context) => TaskActions.duplicateTaskRule(context, taskRule: taskRule),
        form: TaskRulePage,
        rules: [taskRule],
      );
      final copy = tester.widget<TaskRulePage>(find.byType(TaskRulePage)).taskRule!.attachments.single;

      await tester.tap(find.byIcon(Icons.check));
      await settle(tester, () => appRepository.taskRules.length == 2);

      final duplicate = appRepository.taskRules.values.singleWhere((r) => r.id != taskRule.id);
      expect(duplicate.attachments, [copy]);
      expect(file(copy).existsSync(), isTrue);
      expect(file(manual).existsSync(), isTrue);
      expect(appRepository.taskRules[taskRule.id]!.attachments, [manual]);
    });
  });

  group('TaskActions.editTaskEntry', () {
    testWidgets('keeps the attachments and files of an entry saved unchanged', (tester) async {
      final invoice = stored('Invoice');
      final taskRule = rule(const []);
      final taskEntry = entry(taskRule, [invoice]);
      await runAction(
        tester,
        (context) => TaskActions.editTaskEntry(context, taskEntry: taskEntry),
        form: TaskEntryPage,
        rules: [taskRule],
        entries: [taskEntry],
      );

      await tester.tap(find.byIcon(Icons.check));
      await settle(tester, () => appRepository.taskEntries[taskEntry.id]!.lastModified != seededAt);
      expect(appRepository.taskEntries[taskEntry.id]!.lastModified, isNot(seededAt));

      expect(find.byType(TaskEntryPage), findsNothing);
      expect(appRepository.taskEntries[taskEntry.id]!.attachments, [invoice]);
      expect(file(invoice).existsSync(), isTrue);
    });

    testWidgets('deletes the files of attachments removed in the form', (tester) async {
      final invoice = stored('Invoice');
      final photo = stored('Photo');
      final taskRule = rule(const []);
      final taskEntry = entry(taskRule, [invoice, photo]);
      await runAction(
        tester,
        (context) => TaskActions.editTaskEntry(context, taskEntry: taskEntry),
        form: TaskEntryPage,
        rules: [taskRule],
        entries: [taskEntry],
      );

      popForm(tester, taskEntry.copyWith(attachments: [photo]));
      await settle(tester, () => !file(invoice).existsSync());

      expect(file(invoice).existsSync(), isFalse);
      expect(file(photo).existsSync(), isTrue);
      expect(appRepository.taskEntries[taskEntry.id]!.attachments, [photo]);
    });
  });

  group('TaskActions.duplicateTaskEntry', () {
    testWidgets('opens the form without attachments and saves none', (tester) async {
      final invoice = stored('Invoice');
      final taskRule = rule(const []);
      final taskEntry = entry(taskRule, [invoice]);
      await runAction(
        tester,
        (context) => TaskActions.duplicateTaskEntry(context, taskEntry: taskEntry),
        form: TaskEntryPage,
        rules: [taskRule],
        entries: [taskEntry],
      );

      final formEntry = tester.widget<TaskEntryPage>(find.byType(TaskEntryPage)).taskEntry!;
      expect(formEntry.attachments, isEmpty);
      expect(formEntry.notes, 'Fresh seals');

      await tester.tap(find.byIcon(Icons.check));
      await settle(tester, () => appRepository.taskEntries.length == 2);

      final duplicate = appRepository.taskEntries.values.singleWhere((e) => e.id != taskEntry.id);
      expect(duplicate.attachments, isEmpty);
      expect(appRepository.taskEntries[taskEntry.id]!.attachments, [invoice]);
      expect(file(invoice).existsSync(), isTrue);
    });
  });
}
