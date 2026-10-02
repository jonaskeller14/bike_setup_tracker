import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/attachment.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/task_rule_display_card.dart';
import 'package:bike_setup_tracker/widgets/task_priority_badge.dart';
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
  group('TaskRuleDisplayCard attachments', () {
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

    final attachments = [
      Attachment(extension: '.pdf', name: 'Service Manual'),
      Attachment(extension: '.pdf', name: 'Torque Chart'),
    ];

    Future<void> pumpCard(WidgetTester tester, TaskRule taskRule, {ThemeData? theme}) {
      return tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appSettings),
            ChangeNotifierProvider.value(value: appRepository),
            ChangeNotifierProvider<SubscriptionService>(create: (_) => MockSubscriptionService()),
          ],
          child: MaterialApp(
            theme: theme ?? materialAppTheme,
            home: Scaffold(body: TaskRuleDisplayCard(taskRule: taskRule, showStatus: true)),
          ),
        ),
      );
    }

    testWidgets('shows a paperclip and count for a rule with attachments', (tester) async {
      await pumpCard(tester, TaskRule(name: 'Lower leg service', tags: const {}, attachments: attachments));

      expect(find.byIcon(Icons.attach_file), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('hides the count with attachments disabled', (tester) async {
      appSettings.enableAttachments = false;
      await pumpCard(tester, TaskRule(name: 'Lower leg service', tags: const {}, attachments: attachments));

      expect(find.byIcon(Icons.attach_file), findsNothing);
      expect(find.text('2'), findsNothing);
    });

    testWidgets('hides the count for a rule without attachments', (tester) async {
      await pumpCard(tester, TaskRule(name: 'Lower leg service', tags: const {}));

      expect(find.byIcon(Icons.attach_file), findsNothing);
    });

    for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
      testWidgets('a long name with priority badge and count fits a narrow screen ($label)', (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpCard(
          tester,
          TaskRule(name: loremIpsum, notes: loremIpsum, tags: const {}, attachments: attachments),
          theme: theme,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(TaskPriorityBadge), findsOneWidget);
        expect(find.byIcon(Icons.attach_file), findsOneWidget);
      });
    }
  });

  group('taskForecastDueLabel', () {
    final now = DateTime(2026, 9, 9, 14, 30);

    String label(DateTime due) => taskForecastDueLabel(due, now, 'yyyy-MM-dd');

    test('reads as today for the rest of the current day', () {
      expect(label(DateTime(2026, 9, 9, 23, 59)), 'today');
    });

    test('reads as tomorrow across the day boundary, not "in 0 days"', () {
      expect(label(DateTime(2026, 9, 10, 0, 5)), 'tomorrow');
    });

    test('counts days while the estimate is close enough to plan around', () {
      expect(label(DateTime(2026, 9, 12)), 'in 3 days');
      expect(label(DateTime(2026, 9, 22)), 'in 13 days');
    });

    test('switches to whole weeks past the two-week mark', () {
      expect(label(DateTime(2026, 9, 23)), 'in 2 weeks');
      expect(label(DateTime(2026, 11, 3)), 'in 7 weeks');
    });

    test('switches to an absolute date once counting stops helping', () {
      expect(label(DateTime(2026, 11, 4)), '2026-11-04');
    });

    test('honours the configured date format', () {
      expect(
        taskForecastDueLabel(DateTime(2026, 11, 4), now, 'dd.MM.yyyy'),
        '04.11.2026',
      );
    });

    test('never counts backwards for a date that slipped into the past', () {
      expect(label(DateTime(2026, 9, 8)), 'today');
    });
  });
}
