import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/timeline_entry.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/feedback_list_tile.dart';
import 'package:bike_setup_tracker/widgets/items/setup_group_header.dart';
import 'package:bike_setup_tracker/widgets/items/setup_options_menu.dart';
import 'package:bike_setup_tracker/widgets/items/test_session_options_menu.dart';
import 'package:bike_setup_tracker/widgets/items/test_session_timeline_item.dart';
import 'package:bike_setup_tracker/widgets/running_badge.dart';
import 'package:bike_setup_tracker/widgets/sheets/test_session_sheet.dart';
import 'package:bike_setup_tracker/widgets/test_session_next_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => Directory.systemTemp.path,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      null,
    );
  });

  TestSession session({String? name, bool ended = false}) {
    final started = DateTime(2026, 5, 2, 9);
    return TestSession(
      id: 'ts',
      bike: 'bike',
      name: name,
      adjustmentIds: const [],
      startedAtUTC: started.toUtc(),
      startedAtLocal: started,
      endedAtUTC: ended ? started.add(const Duration(hours: 3)).toUtc() : null,
      endedAtLocal: ended ? started.add(const Duration(hours: 3)) : null,
    );
  }

  Setup run(int number) {
    final local = DateTime(2026, 5, 2, 9 + number);
    return Setup(
      id: 'r$number',
      name: 'Run $number',
      datetime: local.toUtc(),
      datetimeLocal: local,
      tags: const {},
      bike: 'bike',
      person: null,
      bikeAdjustmentValues: const {},
      personAdjustmentValues: const {},
      testSessionId: 'ts',
    );
  }

  RideFeedback feedbackOn(Setup run) {
    final local = run.datetimeLocal.add(const Duration(minutes: 30));
    return RideFeedback(
      id: 'fb-${run.id}',
      bike: 'bike',
      setupId: run.id,
      dateTimeUTC: local.toUtc(),
      dateTimeLocal: local,
      notes: 'Notes on ${run.name}',
      observations: const {},
      comparisons: const {},
    );
  }

  /// [runs] runs, each with a feedback when [rated].
  Future<TestSessionTimelineEntry> seed(
    WidgetTester tester,
    TestSession session, {
    required int runs,
    bool rated = true,
  }) async {
    final setups = [for (var i = 1; i <= runs; i++) run(i)];
    final feedbacks = [if (rated) ...setups.map(feedbackOn)];
    await tester.runAsync(() async {
      database = AppDatabase.memory();
      appRepository = AppRepository(database);
      appSettings = AppSettings()..showOnboarding = false;
      await appRepository.addBikes([Bike(id: 'bike', name: 'Test Bike', person: null)]);
      await appRepository.addTestSessions([session]);
      await appRepository.addSetups(setups);
      await appRepository.addFeedbacks(feedbacks);
      for (var attempt = 0; attempt < 100; attempt++) {
        if (appRepository.testSessions.isNotEmpty &&
            appRepository.setups.length == setups.length &&
            appRepository.feedbacks.length == feedbacks.length) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    addTearDown(() async {
      await tester.runAsync(() async {
        await appRepository.disposeAndAwaitCancellation();
        appSettings.dispose();
        await database.close();
      });
    });
    return TestSessionTimelineEntry(
      appRepository.testSessions['ts']!,
      runs: setups,
      feedbacksByRun: {
        for (final feedback in feedbacks) feedback.setupId: [feedback],
      },
    );
  }

  /// The running badge pulses forever, so these tests never pumpAndSettle.
  Future<void> pump(WidgetTester tester, Widget child, {double width = 800, ThemeData? theme}) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appRepository),
        ],
        child: MaterialApp(
          theme: theme ?? materialAppTheme,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a running session: badge beside the name, the latest two items and the next step', (tester) async {
    final entry = await seed(tester, session(name: 'Rebound sweep'), runs: 2);
    await pump(tester, TestSessionTimelineItem(entry: entry));

    final header = find.byType(SetupGroupHeader);
    expect(find.descendant(of: header, matching: find.text('Rebound sweep')), findsOneWidget);
    expect(find.descendant(of: header, matching: find.byType(RunningBadge)), findsOneWidget);
    expect(find.text('2 runs'), findsOneWidget);
    expect(find.text('Fine-tune'), findsNothing, reason: 'a free session');
    expect(find.text('Free'), findsOneWidget);

    // Run 1, its feedback, Run 2, its feedback: only the last two show.
    expect(find.text('Run 1'), findsNothing);
    expect(find.text('Notes on Run 1'), findsNothing);
    expect(find.text('Run 2'), findsWidgets);
    expect(find.text('Notes on Run 2'), findsOneWidget);
    expect(find.text('Show 2 earlier'), findsOneWidget);
    expect(find.byType(TestSessionNextStep), findsOneWidget);
  });

  testWidgets('Show earlier opens the sheet with every run and its feedback', (tester) async {
    final entry = await seed(tester, session(), runs: 2);
    await pump(tester, TestSessionTimelineItem(entry: entry));

    await tester.tap(find.text('Show 2 earlier'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final sheet = find.byType(TestSessionSheetContent);
    expect(sheet, findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text('Run 1')), findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.byType(FeedbackListTile)), findsNWidgets(2));
  });

  testWidgets('two items or fewer show without a Show earlier button; an ended session has no next step', (
    tester,
  ) async {
    final entry = await seed(tester, session(ended: true), runs: 1);
    await pump(tester, TestSessionTimelineItem(entry: entry));

    expect(find.text('Run 1'), findsWidgets);
    expect(find.text('Notes on Run 1'), findsOneWidget);
    expect(find.textContaining('earlier'), findsNothing);
    expect(find.byType(RunningBadge), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('a long press selects the session, and selection mode disables the menus', (tester) async {
    final entry = await seed(tester, session(), runs: 1);
    var toggled = 0;
    await pump(tester, TestSessionTimelineItem(entry: entry, onSelectionChanged: () => toggled++));

    expect(find.byType(TestSessionOptionsMenu), findsOneWidget);
    expect(find.byType(SetupOptionsMenu), findsOneWidget);
    await tester.longPress(find.text('Notes on Run 1'));
    expect(toggled, 1, reason: 'a nested feedback selects the session too');

    await pump(
      tester,
      TestSessionTimelineItem(entry: entry, selectionMode: true, selected: true, onSelectionChanged: () => toggled++),
    );
    for (final menu in [find.byType(TestSessionOptionsMenu), find.byType(SetupOptionsMenu)]) {
      final button = find.descendant(of: menu, matching: find.byWidgetPredicate((widget) => widget is PopupMenuButton));
      expect((tester.widget(button) as PopupMenuButton).enabled, isFalse);
    }
    await tester.tap(find.byType(SetupGroupHeader));
    expect(toggled, 2);
    await tester.tap(find.byType(TestSessionOptionsMenu));
    expect(toggled, 3, reason: 'a tap on the disabled menu still toggles the session');
  });

  for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
    testWidgets('fits a narrow screen with long names and many runs ($label)', (tester) async {
      final entry = await seed(tester, session(name: 'A very long session name ' * 6), runs: 6);
      await pump(tester, TestSessionTimelineItem(entry: entry), width: 320, theme: theme);

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('follows the timeline order: newest first by default, oldest first when ascending', (tester) async {
    final entry = await seed(tester, session(), runs: 2);
    await pump(tester, TestSessionTimelineItem(entry: entry));
    double top(Finder finder) => tester.getTopLeft(finder.first).dy;

    // Descending: Run 2's feedback above Run 2, the earlier items behind a button at the bottom.
    expect(top(find.text('Notes on Run 2')), lessThan(top(find.text('Run 2'))));
    expect(top(find.text('Show 2 earlier')), greaterThan(top(find.text('Run 2'))));

    await tester.runAsync(() => appRepository.setStravaSortOrder(true));
    await tester.pump();
    expect(top(find.text('Run 2')), lessThan(top(find.text('Notes on Run 2'))));
    expect(top(find.text('Show 2 earlier')), lessThan(top(find.text('Run 2'))));
  });
}
