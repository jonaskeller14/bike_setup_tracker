import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/models/task/task_threshold.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/lists/task_list.dart';
import 'package:bike_setup_tracker/widgets/sticky_section.dart';
import 'package:flutter/material.dart';
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

  Widget buildSubject() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppRepository>.value(value: repository),
        ChangeNotifierProvider<AppSettings>.value(value: settings),
      ],
      child: MaterialApp(
        theme: materialAppTheme,
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

  testWidgets('filter uses the same floating sliver behavior as SetupList', (tester) async {
    await seedUpcoming(tester);
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    final filterHeader = tester.widget<SliverPersistentHeader>(
      find.byType(SliverPersistentHeader),
    );
    expect(filterHeader.floating, isTrue);
    expect(filterHeader.pinned, isFalse);
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
