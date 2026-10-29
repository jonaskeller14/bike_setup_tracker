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
import 'package:bike_setup_tracker/pages/forms/feedback_page.dart';
import 'package:bike_setup_tracker/pages/forms/setup_page.dart';
import 'package:bike_setup_tracker/pages/forms/test_session_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/services/test_session_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/setup_actions.dart';
import 'package:bike_setup_tracker/utils/test_session_actions.dart';
import 'package:bike_setup_tracker/widgets/display_adjustment/display_step_adjustment.dart';
import 'package:bike_setup_tracker/widgets/items/setup_tile.dart';
import 'package:bike_setup_tracker/widgets/lists/adjustment_compact_display/adjustment_cell_view.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_step_adjustment.dart';
import 'package:bike_setup_tracker/widgets/setup_page_tab_bike.dart';
import 'package:bike_setup_tracker/widgets/sheets/test_session_sheet.dart';
import 'package:bike_setup_tracker/widgets/test_session_suggestion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSubscriptionService extends Mock implements SubscriptionService {}

const _bikeId = 'bike';
const _reboundId = 'rebound';
const _compressionId = 'compression';

StepAdjustment _step(String id, String name) => StepAdjustment(
  id: id,
  name: name,
  notes: '',
  unit: AdjustmentUnit.fromLegacy('clicks'),
  min: 0,
  max: 20,
  step: 1,
  visualization: StepAdjustmentVisualization.slider,
);

/// The location chip keeps spinning on pages that fetch it, so they never settle.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

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

  Setup baseSetup() {
    final local = DateTime(2026, 5, 1, 10);
    return Setup(
      id: 's1',
      name: 'Base',
      datetime: local.toUtc(),
      datetimeLocal: local,
      tags: const {},
      bike: _bikeId,
      person: null,
      bikeAdjustmentValues: const {_reboundId: StepValue(5), _compressionId: StepValue(8)},
      personAdjustmentValues: const {},
    );
  }

  /// Waits for the database streams, which only progress in real time.
  Future<void> awaitData(WidgetTester tester, bool Function() done) async {
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 100 && !done(); attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
  }

  /// [rated]: the latest run of the session already has a feedback.
  Future<void> seed(
    WidgetTester tester, {
    TestSession? session,
    List<Setup> runs = const [],
    bool rated = true,
    List<RideFeedback> moreFeedbacks = const [],
  }) async {
    final sessionRuns = runs.where((run) => run.testSessionId != null).toList();
    final feedbacks = [
      if (rated && sessionRuns.isNotEmpty)
        RideFeedback(
          id: 'fb',
          bike: _bikeId,
          setupId: sessionRuns.last.id,
          dateTimeUTC: sessionRuns.last.datetime.add(const Duration(minutes: 30)),
          dateTimeLocal: sessionRuns.last.datetimeLocal.add(const Duration(minutes: 30)),
          observations: const {},
          comparisons: const {},
        ),
      ...moreFeedbacks,
    ];
    await tester.runAsync(() async {
      database = AppDatabase.memory();
      appRepository = AppRepository(database);
      appSettings = AppSettings()..showOnboarding = false;
      await appRepository.addBikes([Bike(id: _bikeId, name: 'Test Bike', person: null)]);
      await appRepository.addComponents([
        Component(
          id: 'fork',
          name: 'Fork',
          componentType: ComponentType.fork,
          installations: [Installation.sinceBeginning(parent: _bikeId)],
          adjustments: [_step(_reboundId, 'Rebound'), _step(_compressionId, 'Compression')],
        ),
      ]);
      await appRepository.addSetups([baseSetup(), ...runs]);
      if (session != null) await appRepository.addTestSessions([session]);
      await appRepository.addFeedbacks(feedbacks);
    });
    await awaitData(
      tester,
      () =>
          appRepository.setups.length == 1 + runs.length &&
          appRepository.components.isNotEmpty &&
          appRepository.testSessions.length == (session == null ? 0 : 1) &&
          appRepository.feedbacks.length == feedbacks.length,
    );
    addTearDown(() async {
      await tester.runAsync(() async {
        await appRepository.disposeAndAwaitCancellation();
        appSettings.dispose();
        await database.close();
      });
    });
  }

  TestSession session({Map<String, AdjustmentValue> locks = const {}, bool ended = false, TestSessionMethod? method}) {
    final started = DateTime(2026, 5, 2, 9);
    return TestSession(
      id: 'ts',
      bike: _bikeId,
      method: method ?? const PatternSearch(),
      adjustmentIds: const [_reboundId],
      locks: locks,
      startedAtUTC: started.toUtc(),
      startedAtLocal: started,
      endedAtUTC: ended ? started.add(const Duration(hours: 2)).toUtc() : null,
      endedAtLocal: ended ? started.add(const Duration(hours: 2)) : null,
    );
  }

  Setup run(int number, {int rebound = 5}) {
    final local = DateTime(2026, 5, 2, 9 + number);
    return Setup(
      id: 'r$number',
      name: 'Run $number',
      datetime: local.toUtc(),
      datetimeLocal: local,
      tags: const {},
      bike: _bikeId,
      person: null,
      bikeAdjustmentValues: {_reboundId: StepValue(rebound), _compressionId: const StepValue(8)},
      personAdjustmentValues: const {},
      testSessionId: 'ts',
    );
  }

  Future<void> pumpButton(WidgetTester tester, Future<void> Function(BuildContext) onPressed) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appRepository),
          ChangeNotifierProvider<SubscriptionService>.value(value: _MockSubscriptionService()),
        ],
        child: MaterialApp(
          theme: materialAppTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(onPressed: () => onPressed(context), child: const Text('go')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await settle(tester);
  }

  Future<void> saveForm(WidgetTester tester, {required bool Function() saved}) async {
    await tester.tap(find.byIcon(Icons.check));
    await settle(tester);
    await awaitData(tester, saved);
  }

  group('startSession', () {
    testWidgets('records the session with run 1, a copy of the current setup stamped now', (tester) async {
      await seed(tester);
      // The database keeps whole seconds.
      final before = DateTime.now().toUtc().copyWith(millisecond: 0, microsecond: 0);
      await pumpButton(tester, (context) => TestSessionActions.startSession(context));
      expect(find.byType(TestSessionPage), findsOneWidget);

      expect(find.text('No adjustments yet'), findsOneWidget);
      await tester.tap(find.text('No adjustments yet'));
      await settle(tester);
      expect(find.text('Fork'), findsOneWidget, reason: 'adjustments are grouped by component');
      await tester.tap(find.widgetWithText(FilterChip, 'Rebound'));
      await settle(tester);
      await tester.tapAt(const Offset(10, 10)); // closing the sheet keeps the selection
      await settle(tester);
      expect(find.text('No adjustments yet'), findsNothing);
      await tester.enterText(find.widgetWithText(TextField, 'Name (optional)'), 'Fork rebound');
      await tester.tap(find.byIcon(Icons.check));
      await settle(tester);

      expect(find.byType(SetupPage), findsOneWidget, reason: 'run 1 is set up before the session starts');
      expect(find.text('First Run'), findsOneWidget);
      expect(find.textContaining('This is the base setup'), findsOneWidget);
      expect(appRepository.testSessions, isEmpty);
      await saveForm(tester, saved: () => appRepository.testSessions.isNotEmpty && appRepository.setups.length == 2);

      final started = appRepository.testSessions.values.single;
      expect(started.bike, _bikeId);
      expect(started.name, 'Fork rebound');
      expect(started.method, const PatternSearch());
      expect(started.adjustmentIds, [_reboundId]);
      expect(started.isRunning, isTrue);

      final runs = appRepository.setupsInSession(started.id);
      expect(runs, hasLength(1));
      expect(runs.single.name, 'Run 1');
      expect(runs.single.testSessionId, started.id);
      expect(runs.single.datetime.isBefore(before), isFalse);
      expect(runs.single.bikeAdjustmentValues, baseSetup().bikeAdjustmentValues);
      expect(runs.single.sourceSetupId, 's1');
      expect(runs.single.sourceKind, SetupSourceKind.testSessionRun);
      expect(runs.single.notes, "Copy of 'Base' (2026-05-01)");
      expect(appRepository.runningSessionFor(_bikeId)?.id, started.id);
    });

    testWidgets('backing out of the first run starts no session', (tester) async {
      await seed(tester);
      await pumpButton(tester, (context) => TestSessionActions.startSession(context));
      await tester.tap(find.text('No adjustments yet'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilterChip, 'Rebound'));
      await settle(tester);
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);
      await tester.tap(find.byIcon(Icons.check));
      await settle(tester);
      expect(find.byType(SetupPage), findsOneWidget);

      await tester.pageBack();
      await settle(tester);

      expect(find.byType(SetupPage), findsNothing);
      expect(appRepository.testSessions, isEmpty);
      expect(appRepository.setups, hasLength(1));
    });

    testWidgets('does not start a second session on a bike', (tester) async {
      await seed(tester, session: session(), runs: [run(1)]);
      await pumpButton(tester, (context) => TestSessionActions.startSession(context));

      await tester.tap(find.text('No adjustments yet'));
      await settle(tester);
      await tester.tap(find.widgetWithText(FilterChip, 'Rebound'));
      await settle(tester);
      await tester.tapAt(const Offset(10, 10));
      await settle(tester);
      await tester.tap(find.byIcon(Icons.check));
      await settle(tester);

      expect(find.text('A test session is already running on this bike.'), findsOneWidget);
      expect(appRepository.testSessions, hasLength(1));
    });
  });

  for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
    testWidgets('the create form fits a narrow screen with a long name and every method ($label)', (tester) async {
      await seed(tester);
      tester.view.physicalSize = const Size(320, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appSettings),
            ChangeNotifierProvider.value(value: appRepository),
          ],
          child: MaterialApp(theme: theme, home: const TestSessionPage()),
        ),
      );
      await tester.enterText(find.widgetWithText(TextField, 'Name (optional)'), 'A very long session name ' * 8);

      for (final method in ['Explore', 'Compare', 'Free', 'Fine-tune']) {
        await tester.tap(find.widgetWithText(ChoiceChip, method));
        await tester.pump();
      }

      expect(tester.takeException(), isNull);
    });
  }

  group('addRun', () {
    testWidgets('copies the previous run and lets only the session knobs change', (tester) async {
      await seed(tester, session: session(), runs: [run(1, rebound: 7)]);
      await pumpButton(
        tester,
        (context) => TestSessionActions.addRun(context, session: appRepository.testSessions['ts']!),
      );

      expect(find.byType(SetupPage), findsOneWidget);
      expect(find.byType(SetStepAdjustmentWidget), findsOneWidget, reason: 'only the knob');
      expect(find.textContaining('Rebound'), findsWidgets);
      expect(find.textContaining('Compression'), findsNothing);
      expect(find.text('Next Run'), findsOneWidget);

      await saveForm(tester, saved: () => appRepository.setupsInSession('ts').length == 2);

      final runs = appRepository.setupsInSession('ts');
      expect(runs.map((r) => r.name), ['Run 1', 'Run 2']);
      final next = runs.last;
      expect(next.testSessionId, 'ts');
      expect(next.bike, _bikeId);
      expect(next.bikeAdjustmentValues[_reboundId], const StepValue(10), reason: "Fine-tune's proposal: +3");
      expect(next.bikeAdjustmentValues[_compressionId], const StepValue(8), reason: 'not a knob: copied');
      expect(next.datetime.isAfter(runs.first.datetime), isTrue);
    });

    testWidgets('prefills the strategy proposal and stores it on the session', (tester) async {
      await seed(tester, session: session(), runs: [run(1, rebound: 7)]);
      await pumpButton(
        tester,
        (context) => TestSessionActions.addRun(context, session: appRepository.testSessions['ts']!),
      );
      await saveForm(tester, saved: () => appRepository.testSessions['ts']!.proposals.isNotEmpty);

      final next = appRepository.setupsInSession('ts').last;
      expect(next.bikeAdjustmentValues[_reboundId], const StepValue(10));
      expect(appRepository.testSessions['ts']!.proposals, {
        next.id: {_reboundId: const StepValue(10)},
      });
    });

    testWidgets('a free session proposes nothing and copies the previous run', (tester) async {
      final free = TestSession(
        id: 'ts',
        bike: _bikeId,
        adjustmentIds: const [_reboundId],
        startedAtUTC: DateTime(2026, 5, 2, 9).toUtc(),
        startedAtLocal: DateTime(2026, 5, 2, 9),
      );
      await seed(tester, session: free, runs: [run(1, rebound: 7)]);
      await pumpButton(
        tester,
        (context) => TestSessionActions.addRun(context, session: appRepository.testSessions['ts']!),
      );
      await saveForm(tester, saved: () => appRepository.setupsInSession('ts').length == 2);

      expect(appRepository.setupsInSession('ts').last.bikeAdjustmentValues[_reboundId], const StepValue(7));
      expect(appRepository.testSessions['ts']!.proposals, isEmpty);
    });

    testWidgets('with every run removed, the next run starts again from the current setup', (tester) async {
      await seed(tester, session: session());
      await pumpButton(
        tester,
        (context) => TestSessionActions.addRun(context, session: appRepository.testSessions['ts']!),
      );

      expect(find.byType(SetupPage), findsOneWidget);
      await saveForm(tester, saved: () => appRepository.setupsInSession('ts').length == 1);

      final run = appRepository.setupsInSession('ts').single;
      expect(run.name, 'Run 1');
      expect(run.bikeAdjustmentValues, baseSetup().bikeAdjustmentValues);
    });

    testWidgets('a locked knob is not editable and holds its locked value', (tester) async {
      await seed(tester, session: session(locks: {_reboundId: const StepValue(4)}), runs: [run(1, rebound: 9)]);
      await pumpButton(
        tester,
        (context) => TestSessionActions.addRun(context, session: appRepository.testSessions['ts']!),
      );

      expect(find.byType(SetStepAdjustmentWidget), findsNothing);
      expect(find.byType(DisplayStepAdjustmentWidget), findsOneWidget, reason: 'shown, but read-only');

      await saveForm(tester, saved: () => appRepository.setupsInSession('ts').length == 2);

      expect(appRepository.setupsInSession('ts').last.bikeAdjustmentValues[_reboundId], const StepValue(4));
    });

    testWidgets('offers no adding and no rider tab when the session tunes no rider attribute', (tester) async {
      await seed(tester, session: session(), runs: [run(1)]);
      appSettings.enablePerson = true;
      await pumpButton(
        tester,
        (context) => TestSessionActions.addRun(context, session: appRepository.testSessions['ts']!),
      );

      expect(find.text('Add Component'), findsNothing);
      expect(find.descendant(of: find.byType(SetupBikeTab), matching: find.byIcon(Icons.add)), findsNothing);
      expect(find.byType(TabBar), findsNothing);
    });

    testWidgets('refuses a run that is not after the previous run', (tester) async {
      await seed(tester, session: session(), runs: [run(1)]);
      final early = TestSessionService.run(
        source: run(1),
        session: appRepository.testSessions['ts']!,
        number: 2,
        now: DateTime(2026, 5, 2, 9, 30),
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appSettings),
            ChangeNotifierProvider.value(value: appRepository),
            ChangeNotifierProvider<SubscriptionService>.value(value: _MockSubscriptionService()),
          ],
          child: MaterialApp(
            theme: materialAppTheme,
            home: SetupPage.nextRun(run: early, session: appRepository.testSessions['ts']!),
          ),
        ),
      );
      await settle(tester);

      await tester.tap(find.byIcon(Icons.check));
      await settle(tester);

      expect(find.text('A run must be after the previous run of its test session.'), findsOneWidget);
      expect(find.byType(SetupPage), findsOneWidget);
    });

    testWidgets('an ended session takes no more runs', (tester) async {
      await seed(tester, session: session(ended: true), runs: [run(1)]);
      Setup? added = baseSetup();
      await pumpButton(tester, (context) async {
        added = await TestSessionActions.addRun(context, session: appRepository.testSessions['ts']!);
      });

      expect(added, isNull);
      expect(find.byType(SetupPage), findsNothing);
    });

    testWidgets('a Compare session copies the picked candidate with every adjustment locked', (tester) async {
      final other = baseSetup().copyWith(
        id: 's2',
        name: 'Other',
        datetime: DateTime(2026, 5, 1, 12).toUtc(),
        datetimeLocal: DateTime(2026, 5, 1, 12),
        bikeAdjustmentValues: {_reboundId: const StepValue(12), _compressionId: const StepValue(8)},
      );
      await seed(
        tester,
        session: session(method: const Tournament(candidateSetupIds: ['s1', 's2'])),
        runs: [other],
      );
      await pumpButton(
        tester,
        (context) => TestSessionActions.addRun(context, session: appRepository.testSessions['ts']!),
      );

      await tester.tap(find.text('Other'));
      await settle(tester);

      expect(find.byType(SetupPage), findsOneWidget);
      expect(find.byType(SetStepAdjustmentWidget), findsNothing);
      expect(find.byType(DisplayStepAdjustmentWidget), findsNWidgets(2), reason: 'every adjustment, read-only');
      expect(find.textContaining("rides 'Other'"), findsOneWidget);
      await saveForm(tester, saved: () => appRepository.setupsInSession('ts').isNotEmpty);

      final recorded = appRepository.setupsInSession('ts').single;
      expect(recorded.bikeAdjustmentValues[_reboundId], const StepValue(12));
      expect(recorded.sourceSetupId, 's2');
      expect(find.byType(SetupPage), findsNothing);
    });
  });

  group('duplicateSetup', () {
    testWidgets('restoring a run of a running session is another run', (tester) async {
      await seed(tester, session: session(), runs: [run(1, rebound: 7), run(2, rebound: 9)]);
      await pumpButton(
        tester,
        (context) => SetupActions.duplicateSetup(context, setup: appRepository.setups['r1']!),
      );

      expect(find.text('Next Run'), findsOneWidget);
      await saveForm(tester, saved: () => appRepository.setupsInSession('ts').length == 3);

      final runs = appRepository.setupsInSession('ts');
      expect(runs, hasLength(3));
      expect(runs.last.name, 'Run 3');
      expect(runs.last.bikeAdjustmentValues[_reboundId], const StepValue(7), reason: 'the earlier run is ridden again');
      expect(runs.last.sourceSetupId, 'r1');
      expect(runs.last.notes, "Copy of 'Run 1' (2026-05-02)", reason: 'notes of a run describe its ride');
    });

    testWidgets('after the session ended it is a normal setup without a session', (tester) async {
      await seed(tester, session: session(ended: true), runs: [run(1)]);
      await pumpButton(
        tester,
        (context) => SetupActions.duplicateSetup(context, setup: appRepository.setups['r1']!),
      );

      expect(find.text('Add Setup'), findsOneWidget);
      await saveForm(tester, saved: () => appRepository.setups.length == 3);

      final copy = appRepository.setups.values.firstWhere((s) => s.id != 's1' && s.id != 'r1');
      expect(copy.testSessionId, isNull);
      expect(copy.sourceSetupId, 'r1');
      expect(copy.sourceKind, SetupSourceKind.restore);
    });
  });

  group('while a session runs on the bike', () {
    testWidgets('adding a setup asks to end the session first instead of opening a run', (tester) async {
      await seed(tester, session: session(), runs: [run(1)]);
      await pumpButton(tester, (context) => SetupActions.addSetup(context));

      expect(find.text('End the session first?'), findsOneWidget);
      expect(find.text('Next Run'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect(find.byType(SetupPage), findsNothing);
      expect(appRepository.runningSessionFor(_bikeId), isNotNull);
    });

    testWidgets('the next step is the next run once the latest run is rated', (tester) async {
      await seed(tester, session: session(), runs: [run(1)]);

      final step = TestSessionActions.nextStepFor(appRepository)!;
      expect(step.label, 'Next run');

      await pumpButton(tester, step.run);
      expect(find.text('Next Run'), findsOneWidget);
    });

    testWidgets('the next step is feedback while the latest run is unrated', (tester) async {
      await seed(tester, session: session(), runs: [run(1)], rated: false);

      final step = TestSessionActions.nextStepFor(appRepository)!;
      expect(step.label, 'Add Feedback');

      await pumpButton(tester, step.run);
      expect(find.byType(FeedbackPage), findsOneWidget);
    });

    testWidgets('there is no next step without a running session', (tester) async {
      await seed(tester, session: session(ended: true), runs: [run(1)]);

      expect(TestSessionActions.nextStepFor(appRepository), isNull);
    });

    testWidgets('an unrated latest run is rated first, even with an empty feedback', (tester) async {
      await seed(tester, session: session(), runs: [run(1)], rated: false);
      await pumpButton(tester, (context) => TestSessionActions.addRun(context, session: session()));

      expect(find.byType(FeedbackPage), findsOneWidget);
      await tester.tap(find.byIcon(Icons.check));
      await settle(tester);
      await awaitData(tester, () => appRepository.feedbacks.isNotEmpty);
      await tester.pump(const Duration(milliseconds: 500));

      expect(appRepository.feedbacksForSetup('r1'), hasLength(1));
      expect(find.text('Next Run'), findsOneWidget);
    });

    testWidgets('backing out of the feedback keeps the session where it was', (tester) async {
      await seed(tester, session: session(), runs: [run(1)], rated: false);
      await pumpButton(tester, (context) => TestSessionActions.addRun(context, session: session()));

      await tester.pageBack();
      await settle(tester);

      expect(find.byType(SetupPage), findsNothing);
      expect(appRepository.setupsInSession('ts'), hasLength(1));
    });

    testWidgets('restoring another setup asks to end the session first, and Cancel keeps it running', (tester) async {
      await seed(tester, session: session(), runs: [run(1)]);
      await pumpButton(tester, (context) => SetupActions.duplicateSetup(context, setup: appRepository.setups['s1']!));

      expect(find.text('End the session first?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect(find.byType(SetupPage), findsNothing);
      expect(appRepository.runningSessionFor(_bikeId), isNotNull);
    });

    testWidgets('ending it from the dialog opens the setup form', (tester) async {
      await seed(tester, session: session(), runs: [run(1)]);
      await pumpButton(tester, (context) => SetupActions.duplicateSetup(context, setup: appRepository.setups['s1']!));

      await tester.tap(find.text('End session'));
      await settle(tester);
      await awaitData(tester, () => appRepository.runningSessionFor(_bikeId) == null);
      await tester.pump(const Duration(milliseconds: 500));

      expect(appRepository.testSessions['ts']!.isRunning, isFalse);
      expect(find.byType(SetupPage), findsOneWidget);
    });

    testWidgets('the setup form says so on the bike field before anything is entered, and refuses to save', (tester) async {
      await seed(tester, session: session(), runs: [run(1)]);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appSettings),
            ChangeNotifierProvider.value(value: appRepository),
            ChangeNotifierProvider<SubscriptionService>.value(value: _MockSubscriptionService()),
          ],
          child: MaterialApp(theme: materialAppTheme, home: SetupPage.add(initialBike: appRepository.bikes[_bikeId])),
        ),
      );
      await settle(tester);
      const error = 'A test session is running on this bike. End it before recording a setup.';
      expect(find.text(error), findsOneWidget, reason: 'shown on open, not after saving');

      await tester.tap(find.byIcon(Icons.check));
      await settle(tester);

      expect(find.text(error), findsOneWidget);
      expect(find.byType(SetupPage), findsOneWidget);
    });

    Future<void> openEdit(WidgetTester tester, String setupId) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appSettings),
            ChangeNotifierProvider.value(value: appRepository),
            ChangeNotifierProvider<SubscriptionService>.value(value: _MockSubscriptionService()),
          ],
          child: MaterialApp(theme: materialAppTheme, home: SetupPage.edit(setup: appRepository.setups[setupId]!)),
        ),
      );
      await settle(tester);
    }

    const editError = 'A test session is running on this bike. End it before editing its setups.';

    testWidgets('editing another setup of the bike is refused too', (tester) async {
      await seed(tester, session: session(), runs: [run(1)]);
      await openEdit(tester, 's1');

      expect(find.text(editError), findsOneWidget);
    });

    testWidgets("editing a run of the running session isn't", (tester) async {
      await seed(tester, session: session(), runs: [run(1)]);
      await openEdit(tester, 'r1');

      expect(find.text(editError), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsWidgets, reason: 'the run keeps its bike');
    });
  });

  group('lock and end', () {
    testWidgets('lock stores the latest run’s value, unlock releases it', (tester) async {
      await seed(tester, session: session(), runs: [run(1, rebound: 6)]);
      await pumpButton(
        tester,
        (context) => TestSessionActions.toggleLock(
          context,
          session: appRepository.testSessions['ts']!,
          adjustmentId: _reboundId,
        ),
      );
      await awaitData(tester, () => appRepository.testSessions['ts']!.locks.isNotEmpty);
      expect(appRepository.testSessions['ts']!.locks, {_reboundId: const StepValue(6)});
      expect(TestSessionService.editableIds(appRepository.testSessions['ts']!), isEmpty);

      await tester.tap(find.text('go'));
      await settle(tester);
      await awaitData(tester, () => appRepository.testSessions['ts']!.locks.isEmpty);
      expect(appRepository.testSessions['ts']!.locks, isEmpty);
    });

    testWidgets('a Compare session takes no lock', (tester) async {
      await seed(
        tester,
        session: session(method: const Tournament(candidateSetupIds: ['s1', 's2'])),
        runs: [run(1, rebound: 6)],
      );
      await pumpButton(
        tester,
        (context) => TestSessionActions.toggleLock(
          context,
          session: appRepository.testSessions['ts']!,
          adjustmentId: _reboundId,
        ),
      );
      await awaitData(tester, () => false);

      expect(appRepository.testSessions['ts']!.locks, isEmpty);
    });

    testWidgets('End session stamps the end without asking, and UNDO resumes it', (tester) async {
      await seed(tester, session: session(), runs: [run(1)]);
      await pumpButton(
        tester,
        (context) => TestSessionActions.endSession(context, session: appRepository.testSessions['ts']!),
      );
      await awaitData(tester, () => !appRepository.testSessions['ts']!.isRunning);

      final ended = appRepository.testSessions['ts']!;
      expect(ended.isRunning, isFalse);
      expect(ended.endedAtLocal, isNotNull);
      expect(appRepository.runningSessionFor(_bikeId), isNull);
      expect(find.text("Test session 'Test session' ended."), findsOneWidget);

      await tester.tap(find.text('UNDO'));
      await settle(tester);
      await awaitData(tester, () => appRepository.testSessions['ts']!.isRunning);
      expect(appRepository.runningSessionFor(_bikeId)?.id, 'ts');
    });
  });

  group('edit and remove', () {
    RideFeedback feedbackOn(Setup setup, String id) => RideFeedback(
      id: id,
      bike: _bikeId,
      setupId: setup.id,
      dateTimeUTC: setup.datetime.add(const Duration(minutes: 10)),
      dateTimeLocal: setup.datetimeLocal.add(const Duration(minutes: 10)),
      observations: const {},
      comparisons: const {},
    );

    /// Run 1 rated by 'fb1', run 2 by 'fb' (from [seed]), and a feedback on the
    /// base setup that is not part of the session.
    Future<void> seedSession(WidgetTester tester) => seed(
      tester,
      session: session(),
      runs: [run(1), run(2)],
      moreFeedbacks: [feedbackOn(run(1), 'fb1'), feedbackOn(baseSetup(), 'outside')],
    );

    bool sessionInTrash() =>
        appRepository.testSessions.isEmpty &&
        appRepository.deletedTestSessions.length == 1 &&
        appRepository.deletedSetups.length == 2 &&
        appRepository.deletedFeedbacks.length == 2;

    void expectSessionBack() {
      expect(appRepository.testSessions.keys, ['ts']);
      expect(appRepository.setupsInSession('ts').map((run) => run.id), ['r1', 'r2']);
      expect(appRepository.feedbacks.keys, unorderedEquals(['fb', 'fb1', 'outside']));
      expect(appRepository.deletedSetups, isEmpty);
      expect(appRepository.deletedFeedbacks, isEmpty);
    }

    testWidgets('remove takes the runs and their feedbacks to the trash, and UNDO brings them back', (tester) async {
      await seedSession(tester);
      await pumpButton(
        tester,
        (context) => TestSessionActions.removeSession(context, session: appRepository.testSessions['ts']!),
      );
      await awaitData(tester, sessionInTrash);

      expect(appRepository.setups.keys, ['s1']);
      expect(appRepository.feedbacks.keys, ['outside']);
      expect(find.text("Test session 'Test session' moved to trash."), findsOneWidget);

      await tester.tap(find.text('UNDO'));
      await settle(tester);
      await awaitData(tester, () => appRepository.testSessions.isNotEmpty && appRepository.feedbacks.length == 3);
      expectSessionBack();
    });

    testWidgets('restoring the session from the trash leaves its runs and feedbacks there', (tester) async {
      await seedSession(tester);
      await tester.runAsync(() => appRepository.removeTestSessions([appRepository.testSessions['ts']!]));
      await awaitData(tester, sessionInTrash);

      await tester.runAsync(() => appRepository.restoreTestSessions(appRepository.deletedTestSessions));
      await awaitData(tester, () => appRepository.testSessions.isNotEmpty);
      expect(appRepository.testSessions.keys, ['ts']);
      expect(appRepository.setupsInSession('ts'), isEmpty);
      expect(appRepository.deletedSetups, hasLength(2));
      expect(appRepository.deletedFeedbacks, hasLength(2));
      expect(appRepository.feedbacks.keys, ['outside']);
    });

    testWidgets('edit saves the new name and keeps everything else', (tester) async {
      await seed(tester, session: session(), runs: [run(1)]);
      final original = appRepository.testSessions['ts']!;
      await pumpButton(tester, (context) => TestSessionActions.editSession(context, session: original));

      expect(find.byType(TestSessionPage), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Rebound sweep');
      await saveForm(tester, saved: () => appRepository.testSessions['ts']!.name == 'Rebound sweep');

      final edited = appRepository.testSessions['ts']!;
      expect(edited.copyWith(name: null, lastModified: original.lastModified), original);
      expect(appRepository.setupsInSession('ts'), hasLength(1));
    });
  });

  group('session sheet', () {
    testWidgets('lists every run as a setup tile, oldest first, and locks an adjustment from its chip', (tester) async {
      await seed(tester, session: session(), runs: [run(1), run(2, rebound: 7)]);
      await pumpButton(tester, (context) => showTestSessionSheet(context: context, sessionId: 'ts'));

      final tiles = find.byType(SetupTile);
      expect(tiles, findsNWidgets(2));
      expect(tester.widget<SetupTile>(tiles.first).setupId, 'r1');
      for (final tile in tester.widgetList<SetupTile>(tiles)) {
        final cells = find.descendant(
          of: find.byKey(ValueKey(tile.setupId)),
          matching: find.byType(AdjustmentCellView),
        );
        expect(
          tester.widgetList<AdjustmentCellView>(cells).map((cell) => cell.cell.adjustment.id),
          [_reboundId],
          reason: 'collapsed, every run shows the session adjustments, changed or not',
        );
      }

      final chip = find.widgetWithText(FilterChip, 'Rebound');
      expect(find.descendant(of: chip, matching: find.byIcon(Icons.swap_vert)), findsOneWidget);
      await tester.tap(chip);
      await settle(tester);
      await awaitData(tester, () => appRepository.testSessions['ts']!.locks.isNotEmpty);

      expect(appRepository.testSessions['ts']!.locks, {_reboundId: const StepValue(7)});
      expect(find.descendant(of: chip, matching: find.byIcon(Icons.lock)), findsOneWidget);
    });

    testWidgets('shows the suggested next run as a ghost item with its changes', (tester) async {
      await seed(tester, session: session(), runs: [run(1, rebound: 7)]);
      await pumpButton(tester, (context) => showTestSessionSheet(context: context, sessionId: 'ts'));

      expect(find.text('Run 2 · Suggested'), findsOneWidget);
      expect(find.textContaining('Try Rebound +3'), findsOneWidget);
      final ghost = find.byType(TestSessionSuggestion);
      expect(find.descendant(of: ghost, matching: find.byType(AdjustmentCellView)), findsOneWidget);
    });

    testWidgets('no ghost item while the latest run waits for feedback', (tester) async {
      await seed(tester, session: session(), runs: [run(1, rebound: 7)], rated: false);
      await pumpButton(tester, (context) => showTestSessionSheet(context: context, sessionId: 'ts'));

      expect(find.textContaining('Suggested'), findsNothing);
    });

    testWidgets('a running session opens scrolled to its next step', (tester) async {
      await seed(tester, session: session(), runs: [for (var number = 1; number <= 20; number++) run(number)]);
      await pumpButton(tester, (context) => showTestSessionSheet(context: context, sessionId: 'ts'));

      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: find.byType(TestSessionSheetContent), matching: find.byType(Scrollable)).first,
      );
      expect(scrollable.position.pixels, greaterThan(0));
      final nextRun = tester.getRect(find.text('Next run'));
      final viewport = tester.getRect(find.byWidget(scrollable.widget));
      expect(viewport.contains(nextRun.topLeft) && viewport.contains(nextRun.bottomRight), isTrue);
    });

    testWidgets('an ended session shows its adjustments without lock actions', (tester) async {
      await seed(tester, session: session(ended: true), runs: [run(1)]);
      await pumpButton(tester, (context) => showTestSessionSheet(context: context, sessionId: 'ts'));

      expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Rebound')).onSelected, isNull);
      expect(find.text('Ended'), findsOneWidget);
    });

    testWidgets('a Compare session lists the adjustments its setups differ in, with nothing to lock', (tester) async {
      await seed(tester, session: session(method: const Tournament(candidateSetupIds: ['s1', 's2'])), runs: [run(1)]);
      await pumpButton(tester, (context) => showTestSessionSheet(context: context, sessionId: 'ts'));

      expect(find.text('The adjustments your setups differ in:'), findsOneWidget);
      expect(find.text('•  Rebound · Fork'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Rebound'), findsNothing);
    });
  });
}
