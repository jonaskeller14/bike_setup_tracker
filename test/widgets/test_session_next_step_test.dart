import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/test_session_tile.dart';
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
      endedAtUTC: ended ? started.toUtc() : null,
      endedAtLocal: ended ? started : null,
    );
  }

  /// One run at 10:00; [rated] adds a feedback on it.
  Future<void> seed(WidgetTester tester, TestSession session, {required bool rated}) async {
    await tester.runAsync(() async {
      database = AppDatabase.memory();
      appRepository = AppRepository(database);
      appSettings = AppSettings()..showOnboarding = false;
      await appRepository.addBikes([Bike(id: 'bike', name: 'Test Bike', person: null)]);
      await appRepository.addTestSessions([session]);
      await appRepository.addSetups([
        Setup(
          id: 'run1',
          name: 'Run 1',
          datetime: DateTime(2026, 5, 2, 10).toUtc(),
          datetimeLocal: DateTime(2026, 5, 2, 10),
          tags: const {},
          bike: 'bike',
          person: null,
          bikeAdjustmentValues: const {},
          personAdjustmentValues: const {},
          testSessionId: session.id,
        ),
      ]);
      if (rated) {
        await appRepository.addFeedbacks([
          RideFeedback(
            id: 'fb',
            bike: 'bike',
            setupId: 'run1',
            dateTimeUTC: DateTime(2026, 5, 2, 11).toUtc(),
            dateTimeLocal: DateTime(2026, 5, 2, 11),
            observations: const {},
            comparisons: const {},
          ),
        ]);
      }
      for (var attempt = 0; attempt < 100; attempt++) {
        if (appRepository.testSessions.isNotEmpty &&
            appRepository.setups.isNotEmpty &&
            appRepository.feedbacks.length == (rated ? 1 : 0)) {
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
  }

  /// The running badge pulses forever, so these tests never pumpAndSettle.
  Future<void> pump(WidgetTester tester, Widget child, {double width = 800, ThemeData? theme}) async {
    tester.view.physicalSize = Size(width, 1600);
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

  group('TestSessionNextStep', () {
    testWidgets('asks for the feedback first: one primary step, no next run', (tester) async {
      await seed(tester, session(), rated: false);
      await pump(tester, TestSessionNextStep(session: appRepository.testSessions['ts']!));

      expect(find.textContaining('Ride Run 1'), findsOneWidget);
      expect(find.text('Add feedback'), findsOneWidget);
      expect(find.text('Next run'), findsNothing);
      expect(find.text('End session'), findsOneWidget);
    });

    testWidgets('offers the next run once the latest run is rated', (tester) async {
      await seed(tester, session(), rated: true);
      await pump(tester, TestSessionNextStep(session: appRepository.testSessions['ts']!));

      expect(find.textContaining('Run 1 is rated'), findsOneWidget);
      expect(find.text('Next run'), findsOneWidget);
      expect(find.text('Add feedback'), findsNothing);
    });

    testWidgets('shows nothing for an ended session', (tester) async {
      await seed(tester, session(ended: true), rated: false);
      await pump(tester, TestSessionNextStep(session: appRepository.testSessions['ts']!));

      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('End session'), findsNothing);
    });

    for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
      testWidgets('fits a narrow screen ($label)', (tester) async {
        await seed(tester, session(name: 'A very long session name ' * 6), rated: false);
        await pump(tester, TestSessionNextStep(session: appRepository.testSessions['ts']!), width: 320, theme: theme);

        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('a running session shows the pulsing badge, an ended one does not', (tester) async {
    await seed(tester, session(), rated: false);
    await pump(tester, TestSessionTile(session: appRepository.testSessions['ts']!));
    expect(find.byType(RunningBadge), findsOneWidget);
    expect(find.text('1 run'), findsOneWidget);

    final now = DateTime.now();
    final ended = appRepository.testSessions['ts']!.copyWith(endedAtUTC: now.toUtc(), endedAtLocal: now);
    await pump(tester, TestSessionTile(session: ended));
    expect(find.byType(RunningBadge), findsNothing);
  });

  testWidgets('the session sheet lists the runs and carries the next step', (tester) async {
    await seed(tester, session(name: 'Fork rebound'), rated: false);
    await pump(tester, const TestSessionSheetContent(sessionId: 'ts'));

    expect(find.text('Fork rebound'), findsOneWidget);
    expect(find.text('Run 1'), findsWidgets);
    expect(find.text('Add feedback'), findsOneWidget);
  });
}
