import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/task/task_entry.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/chips/task_list_filter_widget.dart';
import 'package:bike_setup_tracker/widgets/lists/task_list.dart';
import 'package:bike_setup_tracker/widgets/sticky_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  late AppDatabase database;
  late AppRepository repository;
  late AppSettings settings;

  setUp(() {
    database = AppDatabase.memory();
    repository = AppRepository(database);
    settings = AppSettings();
  });

  tearDown(() async {
    repository.dispose();
    settings.dispose();
    await database.close();
  });

  Widget buildSubject({
    double textScale = 1,
    bool disableAnimations = false,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppRepository>.value(value: repository),
        ChangeNotifierProvider<AppSettings>.value(value: settings),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
        home: const Scaffold(body: TaskList()),
      ),
    );
  }

  Future<void> seedUpcoming(WidgetTester tester, {int count = 5}) async {
    final now = DateTime.now();
    final rules = [
      for (var index = 1; index <= count; index++)
        TaskRule(
          name: 'Upcoming task $index',
          tags: const {},
          interval: DateTimeThreshold(now.add(Duration(days: index))),
        ),
    ];
    await tester.runAsync(() async {
      await repository.addTaskRules(rules);
      await pumpEventQueue();
    });
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (repository.taskRules.length == count) return;
    }
    fail('Repository did not load $count task rules.');
  }

  Future<void> seedDueAndUpcoming(
    WidgetTester tester, {
    required int dueCount,
  }) async {
    await seedUpcoming(tester);
    await tester.runAsync(() async {
      await repository.addTaskRules(
        [
          for (var index = 1; index <= dueCount; index++) TaskRule(name: 'Due task $index', tags: const {}),
        ],
      );
      await pumpEventQueue();
    });
    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (repository.taskRules.length == 5 + dueCount) return;
    }
    fail('Repository did not load $dueCount due tasks.');
  }

  Future<void> completeTask(
    WidgetTester tester,
    TaskRule taskRule,
  ) async {
    final now = DateTime.now();
    await tester.runAsync(() async {
      final snapshot = await repository.getStatsAt(date: now.toUtc());
      await repository.addTaskEntries([
        TaskEntry(
          name: taskRule.name,
          notes: null,
          dateTimeUTC: now.toUtc(),
          dateTimeLocal: now,
          taskRule: taskRule.id,
          componentId: taskRule.componentId,
          bikeId: taskRule.bikeId,
          snapshot: snapshot,
        ),
      ]);
      await pumpEventQueue();
    });
    await tester.pump();
  }

  testWidgets('empty Due fills the viewport through the Upcoming divider', (tester) async {
    await seedUpcoming(tester);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byType(StickySection), findsAtLeastNWidgets(2));
    expect(find.text('Due now (0)'), findsOneWidget);
    expect(find.text('Upcoming (5)').hitTestable(), findsOneWidget);
    expect(find.text('Upcoming task 1').hitTestable(), findsNothing);
    expect(find.text('Completed (0)').hitTestable(), findsNothing);
    expect(tester.getTopLeft(find.text('Filter')).dx, lessThan(100));
    expect(find.widgetWithText(FilledButton, 'Add task'), findsOneWidget);
  });

  testWidgets('hides empty Upcoming and Completed sections', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('No tasks yet'), findsOneWidget);
    expect(find.text('Upcoming (0)'), findsNothing);
    expect(find.text('Completed (0)'), findsNothing);
  });

  testWidgets('caught-up placeholder grows and pushes Upcoming below a short large-text viewport', (tester) async {
    tester.view.physicalSize = const Size(600, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await seedUpcoming(tester);
    await tester.pumpWidget(buildSubject(textScale: 2));
    await tester.pumpAndSettle();

    expect(find.text('All caught up'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add task'), findsOneWidget);
    expect(find.text('Upcoming (5)').hitTestable(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completing the final due task animates and haptics only once', (tester) async {
    final haptics = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await seedDueAndUpcoming(tester, dueCount: 1);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    final dueRule = repository.actionableTaskRules.single.rule;
    final upcomingTopBefore = tester.getTopLeft(find.text('Upcoming (5)')).dy;

    await completeTask(tester, dueRule);
    final upcomingTopDuringTransition = tester.getTopLeft(find.text('Upcoming (5)')).dy;
    expect(upcomingTopDuringTransition, greaterThanOrEqualTo(upcomingTopBefore - 1));
    await tester.pumpAndSettle();

    expect(find.text('All caught up'), findsOneWidget);
    expect(repository.completedTaskRules, hasLength(1));
    expect(haptics, hasLength(1));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    expect(haptics, hasLength(1));
  });

  testWidgets('reduced motion completes without animation or success haptic', (tester) async {
    final haptics = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await seedDueAndUpcoming(tester, dueCount: 1);
    await tester.pumpWidget(buildSubject(disableAnimations: true));
    await tester.pumpAndSettle();

    await completeTask(tester, repository.actionableTaskRules.single.rule);
    await tester.pump();

    expect(find.text('All caught up'), findsOneWidget);
    expect(haptics, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping Upcoming scrolls to its native sticky section', (tester) async {
    await seedUpcoming(tester);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    final scroll = tester.widget<CustomScrollView>(find.byType(CustomScrollView));
    await tester.tap(find.text('Upcoming (5)'));
    await tester.pumpAndSettle();

    expect(scroll.controller!.offset, greaterThan(0));
    expect(find.text('Upcoming task 1').hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(find.text('Upcoming (5)')).dy, lessThan(90));
  });

  testWidgets('short Due content keeps Upcoming at the bottom fold', (tester) async {
    await seedDueAndUpcoming(tester, dueCount: 2);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Due now (2)'), findsOneWidget);
    expect(find.text('Due task 1').hitTestable(), findsOneWidget);
    expect(find.text('Due task 2').hitTestable(), findsOneWidget);
    expect(find.text('Upcoming (5)').hitTestable(), findsOneWidget);
    expect(find.text('Upcoming task 1').hitTestable(), findsNothing);
  });

  testWidgets('tall Due content naturally pushes Upcoming below the fold', (tester) async {
    await seedDueAndUpcoming(tester, dueCount: 8);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Due now (8)'), findsOneWidget);
    expect(find.text('Upcoming (5)').hitTestable(), findsNothing);
    expect(find.text('Upcoming task 1').hitTestable(), findsNothing);
  });

  testWidgets('filter scrolls with the task list', (tester) async {
    await seedUpcoming(tester);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byType(SliverPersistentHeader), findsNothing);
    expect(find.byType(TaskListFilterWidget), findsOneWidget);
  });

  testWidgets('show all and show less relayout the native section', (tester) async {
    await seedUpcoming(tester);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upcoming (5)'));
    await tester.pumpAndSettle();

    final scrollable = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('task-upcoming-toggle')),
      200,
      scrollable: scrollable,
    );
    tester
        .widget<TextButton>(
          find.byKey(const ValueKey('task-upcoming-toggle')),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Upcoming task 5'), findsOneWidget);
    expect(find.text('Show less'), findsOneWidget);

    tester
        .widget<TextButton>(
          find.byKey(const ValueKey('task-upcoming-toggle')),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('Show all (5)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
