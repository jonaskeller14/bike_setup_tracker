import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/pages/details/task_rule_details_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/attachment_strip.dart';
import 'package:bike_setup_tracker/widgets/attachment_viewer.dart';
import 'package:bike_setup_tracker/widgets/items/task_entry_list_item.dart';
import 'package:bike_setup_tracker/widgets/items/task_rule_display_card.dart';
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

  void mockPathProvider(Future<Object?> Function(MethodCall call)? handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      handler,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
    appSettings.enableAttachments = true;
    mockPathProvider((call) async => Directory.systemTemp.path);
  });

  tearDown(() async {
    mockPathProvider(null);
    // Closing the database right after dispose() races its fire-and-forget
    // subscription cancellation and can hang; wait for cancellation first.
    await appRepository.disposeAndAwaitCancellation();
    appSettings.dispose();
    await database.close();
  });

  final manual = Attachment(id: 'manual', extension: '.pdf', name: 'Service Manual');
  final invoice = Attachment(id: 'invoice', extension: '.pdf', name: 'Workshop Invoice');
  final receipt = Attachment(id: 'receipt', extension: '.pdf', name: 'Oil Receipt');

  final taskRule = TaskRule(id: 'r1', name: 'Lower leg service', tags: const {}, attachments: [manual]);

  TaskEntry entry(String id, int day, List<Attachment> attachments) => TaskEntry(
    id: id,
    name: '${taskRule.name} $id',
    notes: null,
    dateTimeUTC: DateTime(2026, 5, day, 10).toUtc(),
    dateTimeLocal: DateTime(2026, 5, day, 10),
    taskRule: taskRule.id,
    attachments: attachments,
  );

  /// Seeds the rule with one entry per list in [entryAttachments] and pumps its details page.
  Future<void> pumpPage(WidgetTester tester, {required List<List<Attachment>> entryAttachments}) async {
    await tester.runAsync(() async {
      await database.into(database.taskRules).insert(taskRule.toCompanion());
      for (final (index, attachments) in entryAttachments.indexed) {
        await database.into(database.taskEntries).insert(entry('e$index', index + 1, attachments).toCompanion());
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
          home: TaskRuleDetailsPage(taskRuleId: taskRule.id),
        ),
      ),
    );
    // The database streams deliver with real I/O, which only completes outside the fake clock.
    bool loaded() => appRepository.taskRules.isNotEmpty && appRepository.taskEntries.length == entryAttachments.length;
    for (var attempts = 0; !loaded() && attempts < 100; attempts++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.byType(TaskEntryListItem), findsNWidgets(entryAttachments.length));
  }

  group('TaskRuleDetailsPage attachments', () {
    testWidgets('rule and entry strips share the page and both open the viewer', (tester) async {
      await pumpPage(
        tester,
        entryAttachments: [
          [invoice],
        ],
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AttachmentStrip), findsNWidgets(2));
      // The rule's strip starts at the card's left edge, without a leading icon.
      final ruleStrip = tester.getTopLeft(find.byType(AttachmentStrip).first);
      expect(ruleStrip.dx, tester.getTopLeft(find.byType(TaskRuleDisplayCard)).dx);
      expect(ruleStrip.dy, lessThan(tester.getTopLeft(find.text('ENTRIES')).dy));

      await tester.tap(find.text('Service Manual'));
      await tester.pumpAndSettle();
      expect(find.byType(AttachmentViewer), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(AttachmentViewer), findsNothing);

      await tester.tap(find.text('Workshop Invoice'));
      await tester.pumpAndSettle();
      expect(find.byType(AttachmentViewer), findsOneWidget);
      expect(find.descendant(of: find.byType(AppBar), matching: find.text('Workshop Invoice')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows no strips with attachments disabled', (tester) async {
      appSettings.enableAttachments = false;
      await pumpPage(
        tester,
        entryAttachments: [
          [invoice],
        ],
      );

      expect(find.byType(AttachmentStrip), findsNothing);
      expect(find.byIcon(Icons.attach_file), findsNothing);
    });

    testWidgets('rule and entries fall back to the count when the directory cannot be resolved', (tester) async {
      mockPathProvider((call) async => throw PlatformException(code: 'unavailable'));
      await pumpPage(
        tester,
        entryAttachments: [
          [invoice, receipt],
        ],
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AttachmentStrip), findsNothing);
      expect(
        find.descendant(of: find.byType(TaskEntryListItem), matching: find.byIcon(Icons.attach_file)),
        findsOneWidget,
      );
      expect(find.descendant(of: find.byType(TaskEntryListItem), matching: find.text('2')), findsOneWidget);
    });

    testWidgets('while selecting, a tap on an entry thumbnail toggles the selection', (tester) async {
      await pumpPage(
        tester,
        entryAttachments: [
          [invoice],
          [receipt],
        ],
      );

      await tester.longPress(find.text('Lower leg service e0'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tapAt(tester.getCenter(find.text('Oil Receipt')));
      await tester.pumpAndSettle();

      expect(find.byType(AttachmentViewer), findsNothing);
      expect(find.text('2 selected'), findsOneWidget);
    });
  });
}
