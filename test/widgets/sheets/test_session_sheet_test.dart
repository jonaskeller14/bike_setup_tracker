import 'dart:async';
import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/feedback/test_session_method.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/sheets/test_session_sheet.dart';
import 'package:bike_setup_tracker/widgets/test_session_next_step.dart';
import 'package:bike_setup_tracker/widgets/test_session_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../goldens/support/localized_test_app.dart';

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

  TestSession session({TestSessionMethod? method, bool ended = false, List<String> knobs = const ['dial']}) {
    final started = DateTime(2026, 5, 2, 9);
    return TestSession(
      id: 'ts',
      bike: 'bike',
      name: 'Fork rebound',
      method: method,
      adjustmentIds: knobs,
      startedAtUTC: started.toUtc(),
      startedAtLocal: started,
      endedAtUTC: ended ? started.toUtc() : null,
      endedAtLocal: ended ? started : null,
    );
  }

  /// A fork with one dial and [runs] runs from 10:00 on, the first [rated] of
  /// them with a feedback.
  Future<void> seed(WidgetTester tester, TestSession session, {int runs = 1, int rated = 0}) async {
    await tester.runAsync(() async {
      database = AppDatabase.memory();
      appRepository = AppRepository(database);
      appSettings = AppSettings()..showOnboarding = false;
      await appRepository.addBikes([Bike(id: 'bike', name: 'Test Bike', person: null)]);
      await appRepository.addComponents([
        Component(
          name: 'Fork',
          installations: [Installation.sinceBeginning(parent: 'bike')],
          componentType: ComponentType.fork,
          adjustments: [
            StepAdjustment(
              id: 'dial',
              name: 'Rebound',
              notes: null,
              unit: null,
              min: 0,
              max: 20,
              step: 1,
              visualization: StepAdjustmentVisualization.slider,
            ),
          ],
        ),
      ]);
      await appRepository.addTestSessions([session]);
      await appRepository.addSetups([
        for (var i = 0; i < runs; i++)
          Setup(
            id: 'run$i',
            name: 'Run ${i + 1}',
            datetime: DateTime(2026, 5, 2, 10 + i).toUtc(),
            datetimeLocal: DateTime(2026, 5, 2, 10 + i),
            tags: const {},
            bike: 'bike',
            person: null,
            bikeAdjustmentValues: {'dial': StepValue(10 + i)},
            personAdjustmentValues: const {},
            testSessionId: session.id,
          ),
      ]);
      await appRepository.addFeedbacks([
        for (var i = 0; i < rated; i++)
          RideFeedback(
            id: 'fb$i',
            bike: 'bike',
            setupId: 'run$i',
            dateTimeUTC: DateTime(2026, 5, 2, 10 + i, 30).toUtc(),
            dateTimeLocal: DateTime(2026, 5, 2, 10 + i, 30),
            observations: const {},
            comparisons: const {},
          ),
      ]);
      for (var attempt = 0; attempt < 100; attempt++) {
        if (appRepository.testSessions.isNotEmpty &&
            appRepository.components.isNotEmpty &&
            appRepository.setups.length == runs &&
            appRepository.feedbacks.length == rated) {
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
  Future<void> pumpSheet(WidgetTester tester, {double width = 400, ThemeData? theme}) async {
    tester.view.physicalSize = Size(width, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appRepository),
        ],
        child: localizedTestApp(
          theme: theme ?? materialAppTheme,
          home: const Scaffold(body: TestSessionSheetContent(sessionId: 'ts')),
        ),
      ),
    );
    await tester.pump();
  }

  group('TestSessionSheetContent progress', () {
    testWidgets('a running session shows the runs left above the next step', (tester) async {
      await seed(tester, session(method: const OrthogonalArray()));
      await pumpSheet(tester);

      // One knob: two pattern runs and the confirmation.
      expect(find.text('3 more runs'), findsOneWidget);
      expect(
        tester.getBottomLeft(find.byType(TestSessionProgress)).dy,
        lessThan(tester.getTopLeft(find.byType(TestSessionNextStep)).dy),
      );
      // The run count of the header stays.
      expect(find.text('1 run'), findsOneWidget);
    });

    testWidgets('the count holds while a run waits for its feedback', (tester) async {
      await seed(tester, session(method: const PatternSearch()), runs: 2, rated: 1);
      await pumpSheet(tester);

      // 7 before the run, of which it is one.
      expect(find.text('About 6 more runs'), findsOneWidget);
      expect(find.text('Add feedback'), findsOneWidget);
    });

    testWidgets('a free session has no bar', (tester) async {
      await seed(tester, session());
      await pumpSheet(tester);

      expect(find.byType(TestSessionProgress), findsNothing);
      expect(find.byType(TestSessionNextStep), findsOneWidget);
    });

    testWidgets('an ended session has no bar', (tester) async {
      await seed(tester, session(method: const OrthogonalArray(), ended: true), rated: 1);
      await pumpSheet(tester);

      expect(find.byType(TestSessionProgress), findsNothing);
    });

    testWidgets('a session whose adjustment is gone has no bar', (tester) async {
      await seed(tester, session(method: const OrthogonalArray(), knobs: const ['removed']), rated: 1);
      await pumpSheet(tester);

      expect(find.byType(TestSessionProgress), findsNothing);
      expect(find.byType(TestSessionNextStep), findsOneWidget);
    });

    testWidgets('a run recorded on another page shows once that page has left', (tester) async {
      await seed(tester, session(method: const OrthogonalArray()), rated: 1);
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appSettings),
            ChangeNotifierProvider.value(value: appRepository),
          ],
          child: localizedTestApp(
            theme: materialAppTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showTestSessionSheet(context: context, sessionId: 'ts'),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('3 more runs'), findsOneWidget);

      final navigator = Navigator.of(tester.element(find.byType(TestSessionSheetContent)));
      unawaited(navigator.push(MaterialPageRoute<void>(builder: (context) => const Scaffold(body: Text('next run')))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.runAsync(() async {
        await appRepository.addSetups([
          Setup(
            id: 'run1',
            name: 'Run 2',
            datetime: DateTime(2026, 5, 2, 11).toUtc(),
            datetimeLocal: DateTime(2026, 5, 2, 11),
            tags: const {},
            bike: 'bike',
            person: null,
            bikeAdjustmentValues: const {'dial': StepValue(15)},
            personAdjustmentValues: const {},
            testSessionId: 'ts',
          ),
        ]);
        for (var attempt = 0; attempt < 100 && appRepository.setups.length < 2; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      // Covered by the page: the bar still shows what the rider last saw.
      expect(find.text('3 more runs', skipOffstage: false), findsOneWidget);
      expect(find.text('2 more runs', skipOffstage: false), findsNothing);

      navigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('2 more runs'), findsNothing);

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('2 more runs'), findsOneWidget);
      expect(find.text('3 more runs'), findsNothing);
    });

    for (final (name, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
      testWidgets('fits a narrow screen ($name)', (tester) async {
        await seed(tester, session(method: const PatternSearch()), runs: 3, rated: 2);
        await pumpSheet(tester, width: 320, theme: theme);

        expect(find.byType(TestSessionProgress), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
