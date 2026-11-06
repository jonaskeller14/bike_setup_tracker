import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_comparison.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_observation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/display_data/test_session_run_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../goldens/support/localized_test_app.dart';

StepAdjustment _adjustment(String id, String name) => StepAdjustment(
  id: id,
  name: name,
  notes: '',
  unit: AdjustmentUnit.fromLegacy('clicks'),
  min: 0,
  max: 100,
  step: 1,
  visualization: StepAdjustmentVisualization.slider,
);

Setup _run(String id, int hour, {required int rebound}) => Setup(
  id: id,
  name: id,
  notes: 'Notes of $id',
  datetime: DateTime(2026, 5, 2, hour).toUtc(),
  datetimeLocal: DateTime(2026, 5, 2, hour),
  tags: const {},
  bike: 'bike',
  person: null,
  bikeAdjustmentValues: {'rebound': StepValue(rebound), 'pressure': const StepValue(50)},
  personAdjustmentValues: const {},
  testSessionId: 'ts',
);

RideFeedback _feedback(
  String setupId,
  int hour, {
  String? notes,
  Set<FeedbackObservation> observations = const {},
  Map<String, int> comparisons = const {},
}) => RideFeedback(
  bike: 'bike',
  setupId: setupId,
  dateTimeUTC: DateTime(2026, 5, 2, hour, 30).toUtc(),
  dateTimeLocal: DateTime(2026, 5, 2, hour, 30),
  notes: notes,
  observations: observations,
  comparisons: {
    for (final MapEntry(key: reference, value: outcome) in comparisons.entries)
      FeedbackComparison(referenceSetupId: reference, aspect: const OverallAspect(), outcome: outcome),
  },
);

FeedbackObservation _issue(FeedbackEnd end, FeedbackAttribute attribute) =>
    FeedbackObservation.flag(IssueKey(end, attribute));

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

  TestSession session({List<String> adjustmentIds = const ['rebound']}) => TestSession(
    id: 'ts',
    bike: 'bike',
    adjustmentIds: adjustmentIds,
    startedAtUTC: DateTime(2026, 5, 2, 9).toUtc(),
    startedAtLocal: DateTime(2026, 5, 2, 9),
  );

  Future<void> seed(WidgetTester tester, {required List<Setup> runs, List<RideFeedback> feedbacks = const []}) async {
    await tester.runAsync(() async {
      database = AppDatabase.memory();
      appRepository = AppRepository(database);
      appSettings = AppSettings()
        ..showOnboarding = false
        ..enableRating = true;
      await appRepository.addBikes([Bike(id: 'bike', name: 'Test Bike', person: null)]);
      await appRepository.addComponents([
        Component(
          id: 'fork',
          name: 'Fork',
          componentType: ComponentType.fork,
          installations: [Installation.sinceBeginning(parent: 'bike')],
          adjustments: [_adjustment('rebound', 'Rebound'), _adjustment('pressure', 'Pressure')],
        ),
      ]);
      await appRepository.addTestSessions([session()]);
      await appRepository.addSetups(runs);
      if (feedbacks.isNotEmpty) await appRepository.addFeedbacks(feedbacks);
      for (var attempt = 0; attempt < 100; attempt++) {
        if (appRepository.setups.length == runs.length && appRepository.feedbacks.length == feedbacks.length) break;
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

  Future<void> pump(WidgetTester tester, TestSession session, {double width = 800, ThemeData? theme}) async {
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
          home: Scaffold(
            body: SingleChildScrollView(child: TestSessionRunTable(session: session)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  List<String> columnLabels(WidgetTester tester) => [
    for (final column in tester.widget<DataTable>(find.byType(DataTable)).columns)
      tester
          .widgetList<Text>(find.descendant(of: find.byWidget(column.label), matching: find.byType(Text)))
          .single
          .data!,
  ];

  List<String> rowNames(WidgetTester tester) {
    final names = ['run1', 'run2', 'run3'].where((name) => find.text(name).evaluate().isNotEmpty).toList();
    return names..sort((a, b) => tester.getTopLeft(find.text(a)).dy.compareTo(tester.getTopLeft(find.text(b)).dy));
  }

  testWidgets('preselects the name, the adjustments of the session and the feedback columns', (tester) async {
    await seed(tester, runs: [_run('run1', 10, rebound: 5)]);
    await pump(tester, session());

    final labels = columnLabels(tester);
    expect(labels.first, 'Name');
    expect(labels[1], startsWith('Rebound'));
    expect(labels.sublist(2), ['Issues', 'Evaluation', 'Feedback notes']);
  });

  testWidgets('a Compare session preselects what its candidates differ in', (tester) async {
    await seed(tester, runs: [_run('run1', 10, rebound: 5)]);
    await pump(tester, session(adjustmentIds: const ['rebound', 'pressure']));

    expect(columnLabels(tester).where((label) => label.contains(' · ')), hasLength(2));
  });

  testWidgets('aggregates the feedbacks of a run in its row, line by line', (tester) async {
    await seed(
      tester,
      runs: [_run('run1', 10, rebound: 5), _run('run2', 11, rebound: 7)],
      feedbacks: [
        _feedback(
          'run2',
          11,
          notes: 'Too harsh',
          observations: {
            _issue(FeedbackEnd.front, FeedbackAttribute.comfort),
            _issue(FeedbackEnd.rear, FeedbackAttribute.grip),
          },
          comparisons: {'run1': 2},
        ),
        _feedback(
          'run2',
          12,
          notes: 'Better on roots\nStill loud',
          observations: {const FeedbackObservation.flag(NoIssueKey())},
          comparisons: {'run1': 1},
        ),
      ],
    );
    await pump(tester, session());

    expect(tester.widget<DataTable>(find.byType(DataTable)).rows, hasLength(2));
    expect(find.text('Front: Harsh, Rear: Low grip\nNo issues'), findsOneWidget);
    expect(find.text('Better than run1\nSlightly better than run1'), findsOneWidget);
    // run1 has no feedback.
    expect(find.text('Too harsh\nBetter on roots\nStill loud'), findsOneWidget);
    expect(find.text('-'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sorting by a feedback column puts the best run first, unanswered ones last', (tester) async {
    await seed(
      tester,
      runs: [_run('run1', 10, rebound: 5), _run('run2', 11, rebound: 7), _run('run3', 12, rebound: 9)],
      feedbacks: [
        _feedback('run2', 11, comparisons: {'run1': -1}),
        _feedback('run3', 12, comparisons: {'run1': 2}),
      ],
    );
    await pump(tester, session());
    expect(rowNames(tester), ['run1', 'run2', 'run3']);

    await tester.tap(find.text('Evaluation'));
    await tester.pump();
    expect(rowNames(tester), ['run3', 'run2', 'run1']);

    await tester.tap(find.text('Evaluation'));
    await tester.pump();
    expect(rowNames(tester), ['run1', 'run2', 'run3']);
  });

  testWidgets('sorting by feedback notes is alphabetical, runs without notes last', (tester) async {
    await seed(
      tester,
      runs: [_run('run1', 10, rebound: 5), _run('run2', 11, rebound: 7), _run('run3', 12, rebound: 9)],
      feedbacks: [
        _feedback('run2', 11, notes: 'Zesty'),
        _feedback('run3', 12, notes: 'Calm'),
      ],
    );
    await pump(tester, session());

    await tester.tap(find.text('Feedback notes'));
    await tester.pump();
    expect(rowNames(tester), ['run3', 'run2', 'run1']);
  });

  testWidgets('blank feedback notes leave no empty line', (tester) async {
    await seed(
      tester,
      runs: [_run('run1', 10, rebound: 5)],
      feedbacks: [
        _feedback('run1', 10, notes: 'First'),
        _feedback('run1', 11, notes: '   '),
      ],
    );
    await pump(tester, session());

    expect(find.text('First'), findsOneWidget);
  });

  testWidgets('the column sheet adds a column, long-press removes it', (tester) async {
    await seed(tester, runs: [_run('run1', 10, rebound: 5)]);
    await pump(tester, session());
    expect(find.text('Notes of run1'), findsNothing);

    await tester.tap(find.text('Columns'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Notes'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(400, 10));
    await tester.pumpAndSettle();
    expect(find.text('Notes of run1'), findsOneWidget);

    await tester.longPress(find.text('Notes'));
    await tester.pump();
    expect(find.text('Notes of run1'), findsNothing);
  });

  testWidgets('shows the empty state without columns', (tester) async {
    await seed(tester, runs: [_run('run1', 10, rebound: 5)]);
    await pump(tester, session());

    for (final label in columnLabels(tester)) {
      await tester.longPress(find.text(label));
      await tester.pump();
    }
    expect(find.byType(DataTable), findsNothing);
    expect(find.text('No columns'), findsOneWidget);
  });

  testWidgets('an edited session starts over with its new adjustments', (tester) async {
    await seed(tester, runs: [_run('run1', 10, rebound: 5)]);
    await pump(tester, session());
    expect(find.textContaining('Pressure'), findsNothing);

    await pump(tester, session(adjustmentIds: const ['pressure']));
    expect(find.textContaining('Pressure'), findsOneWidget);
    expect(find.textContaining('Rebound'), findsNothing);
  });

  for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
    testWidgets('fits a narrow screen ($label)', (tester) async {
      await seed(
        tester,
        runs: [_run('run1', 10, rebound: 5), _run('run2', 11, rebound: 7)],
        feedbacks: [
          _feedback(
            'run2',
            11,
            observations: {
              _issue(FeedbackEnd.front, FeedbackAttribute.comfort),
              _issue(FeedbackEnd.rear, FeedbackAttribute.grip),
            },
            comparisons: {'run1': 2},
          ),
        ],
      );
      await pump(tester, session(adjustmentIds: const ['rebound', 'pressure']), width: 320, theme: theme);

      expect(tester.takeException(), isNull);
    });
  }
}
