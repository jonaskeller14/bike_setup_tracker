import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/models/component/installation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/feedback/test_session_method.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/forms/test_session_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bikeId = 'bike';

StepAdjustment _step(String id) => StepAdjustment(
  id: id,
  name: 'Adjustment $id',
  notes: '',
  unit: null,
  min: 0,
  max: 20,
  step: 1,
  visualization: StepAdjustmentVisualization.slider,
);

void main() {
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;
  Object? result;

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

  Setup setup(String id, int day, int a) {
    final local = DateTime(2026, 5, day, 10);
    return Setup(
      id: id,
      name: id.toUpperCase(),
      datetime: local.toUtc(),
      datetimeLocal: local,
      tags: const {},
      bike: _bikeId,
      person: null,
      bikeAdjustmentValues: {'a1': StepValue(a), 'a2': const StepValue(3)},
      personAdjustmentValues: const {},
    );
  }

  /// [page] defaults to the create form; [width] and [theme] are for overflow checks.
  Future<void> open(
    WidgetTester tester, {
    TestSessionPage Function()? page,
    double width = 800,
    ThemeData? theme,
  }) async {
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
          adjustments: [for (var i = 1; i <= 4; i++) _step('a$i')],
        ),
        Component(
          id: 'shock',
          name: 'Shock',
          componentType: ComponentType.shock,
          installations: [Installation.sinceBeginning(parent: _bikeId)],
          adjustments: [for (var i = 5; i <= 7; i++) _step('a$i')],
        ),
      ]);
      await appRepository.addSetups([setup('s1', 1, 1), setup('s2', 2, 2), setup('s3', 3, 3), setup('s4', 4, 3), setup('s5', 5, 5)]);
      for (var attempt = 0; attempt < 100; attempt++) {
        if (appRepository.setups.length == 5 && appRepository.components.length == 2) break;
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

    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    result = null;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appRepository),
        ],
        child: MaterialApp(
          theme: theme ?? materialAppTheme,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await Navigator.push(
                context,
                MaterialPageRoute<TestSession>(builder: (_) => page?.call() ?? const TestSessionPage()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> selectInSheet(WidgetTester tester, List<String> names) async {
    for (final name in names) {
      final tile = find.widgetWithText(CheckboxListTile, name);
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pump();
    }
  }

  Future<void> pickAdjustments(WidgetTester tester, List<String> names) async {
    await tester.tap(find.text('No adjustments yet'));
    await tester.pumpAndSettle();
    await selectInSheet(tester, names);
  }

  /// Closing the sheet is what keeps the selection.
  Future<void> closeSheet(WidgetTester tester) async {
    await tester.tapAt(const Offset(10, 10)); // the barrier
    await tester.pumpAndSettle();
  }

  const tooMany = 'More than 5 adjustments make it hard to tell which one helped. 1–3 work best.';

  testWidgets('the adjustment sheet is grouped by component and warns softly above five', (tester) async {
    await open(tester);

    await pickAdjustments(tester, ['Adjustment a1', 'Adjustment a2', 'Adjustment a3', 'Adjustment a4', 'Adjustment a5']);
    expect(find.textContaining('Adjustments to test'), findsOneWidget);
    // The sheet's group titles; the page behind shows the owners as subtitles too.
    expect(find.text('Fork'), findsWidgets);
    expect(find.text('Shock'), findsWidgets);
    expect(find.text(tooMany), findsNothing);

    await selectInSheet(tester, ['Adjustment a6']);
    expect(find.text(tooMany), findsNWidgets(2), reason: 'in the sheet and on the page behind it');

    expect(find.text('Adjustments to test (6)'), findsOneWidget);
    await closeSheet(tester);
    expect(find.text(tooMany), findsOneWidget, reason: 'on the page, which still saves');

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect((result as TestSession).adjustmentIds, hasLength(6));
  });

  testWidgets('the goal is grouped like the feedback form and counts to three', (tester) async {
    await open(tester);

    expect(find.text('GOAL (OPTIONAL)'), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget);
    expect(find.text('Front'), findsOneWidget);
    expect(find.text('Rear'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Calm'), findsNWidgets(2));

    for (final (index, chip) in ['Grip', 'Comfort', 'Support'].indexed) {
      await tester.tap(find.widgetWithText(FilterChip, chip).first);
      await tester.pump();
      expect(find.text('${index + 1} / 3'), findsOneWidget);
    }
    // Full: the other chips are disabled.
    expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Calm').first).onSelected, isNull);

    await pickAdjustments(tester, ['Adjustment a1']);
    await closeSheet(tester);
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect((result as TestSession).goal, [
      const EndAspect(FeedbackEnd.front, FeedbackAttribute.grip),
      const EndAspect(FeedbackEnd.front, FeedbackAttribute.comfort),
      const EndAspect(FeedbackEnd.front, FeedbackAttribute.support),
    ]);
  });

  testWidgets('saving without adjustments turns the placeholder into an error, and picking clears it', (tester) async {
    await open(tester);

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(find.text('Pick at least one adjustment to test.'), findsOneWidget);
    expect(find.text('Tap here to add the first adjustment'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(result, isNull);

    await tester.tap(find.text('Pick at least one adjustment to test.'));
    await tester.pumpAndSettle();
    await selectInSheet(tester, ['Adjustment a1']);
    await closeSheet(tester);

    expect(find.text('Pick at least one adjustment to test.'), findsNothing);
  });

  testWidgets('Compare shows the same error on its placeholder, and for setups that do not differ', (tester) async {
    await open(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Compare'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.text('Pick at least 2 setups to compare.'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.text('Pick at least 2 setups to compare.'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'S3'));
    await tester.tap(find.widgetWithText(CheckboxListTile, 'S4'));
    await tester.pump();
    await closeSheet(tester);

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.text('These setups have the same values. Pick setups that differ.'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('Compare picks several setups at once and derives the adjustments', (tester) async {
    await open(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Compare'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('No setups yet'));
    await tester.pumpAndSettle();
    expect(find.text('Setups to compare'), findsOneWidget);

    for (final name in ['S1', 'S2', 'S3', 'S4']) {
      await tester.tap(find.widgetWithText(CheckboxListTile, name));
      await tester.pump();
    }
    expect(find.text('Setups to compare (4)'), findsOneWidget);
    expect(find.textContaining('take about'), findsNothing);

    await closeSheet(tester);
    expect(find.text('1 adjustment differs between them.'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    final session = result as TestSession;
    expect(session.method, const Tournament(candidateSetupIds: ['s1', 's2', 's3', 's4']));
    expect(session.adjustmentIds, ['a1']);
  });

  testWidgets('more than four setups only warn, they are not refused', (tester) async {
    await open(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Compare'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No setups yet'));
    await tester.pumpAndSettle();

    for (final name in ['S1', 'S2', 'S3', 'S4', 'S5']) {
      await tester.tap(find.widgetWithText(CheckboxListTile, name));
      await tester.pump();
    }
    expect(find.textContaining('5 setups take about 10 comparisons'), findsOneWidget, reason: 'in the sheet');

    await closeSheet(tester);
    expect(find.textContaining('5 setups take about 10 comparisons'), findsOneWidget, reason: 'on the page');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect((result as TestSession).method, const Tournament(candidateSetupIds: ['s1', 's2', 's3', 's4', 's5']));
  });

  group('edit mode', () {
    TestSession session({TestSessionMethod? method = const PatternSearch(), List<String> adjustmentIds = const ['a1', 'a5']}) {
      final started = DateTime(2026, 5, 6, 9);
      return TestSession(
        id: 'ts',
        bike: _bikeId,
        name: 'Rebound sweep',
        method: method,
        adjustmentIds: adjustmentIds,
        goal: const [EndAspect(FeedbackEnd.front, FeedbackAttribute.calm)],
        startedAtUTC: started.toUtc(),
        startedAtLocal: started,
      );
    }

    testWidgets('only the name changes, everything else is shown locked', (tester) async {
      final original = session();
      await open(tester, page: () => TestSessionPage.edit(session: original));

      expect(find.text('Edit Test Session'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(4), reason: 'bike, method, adjustments and goal');
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      for (final chip in tester.widgetList<ChoiceChip>(find.byType(ChoiceChip))) {
        expect(chip.onSelected, isNull);
      }
      expect(find.text('Adjustment a1'), findsOneWidget);
      expect(find.text('Adjustment a5'), findsOneWidget);
      expect(find.text('Add Adjustment'), findsNothing);
      expect(find.byTooltip('Remove adjustment'), findsNothing);
      expect(find.byType(ReorderableListView), findsNothing);
      final goal = tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Front · Calm'));
      expect(goal.selected, isTrue);
      expect(goal.onSelected, isNull);
      expect(find.widgetWithText(FilterChip, 'Grip'), findsNothing);

      await tester.enterText(find.byType(TextField), '  Faster rebound  ');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(result, original.copyWith(name: 'Faster rebound'));
    });

    testWidgets('a Compare session lists its setups without changing them', (tester) async {
      await open(
        tester,
        page: () => TestSessionPage.edit(
          session: session(method: const Tournament(candidateSetupIds: ['s1', 's2']), adjustmentIds: const ['a1']),
        ),
      );

      expect(find.text('S1'), findsOneWidget);
      expect(find.text('S2'), findsOneWidget);
      expect(find.text('Change Setups'), findsNothing);
      expect(find.byTooltip('Remove setup'), findsNothing);
      expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Compare')).selected, isTrue);
    });

    testWidgets('an emptied name falls back to the placeholder', (tester) async {
      await open(tester, page: () => TestSessionPage.edit(session: session()));

      await tester.enterText(find.byType(TextField), ' ');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect((result as TestSession).name, isNull);
    });

    testWidgets('leaving asks to discard only after the name changed', (tester) async {
      await open(tester, page: () => TestSessionPage.edit(session: session()));

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Discard Changes?'), findsNothing);
      expect(find.text('open'), findsOneWidget);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Another name');
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Discard Changes?'), findsOneWidget);
    });

    for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
      testWidgets('fits a narrow screen with long names ($label)', (tester) async {
        final long = session().copyWith(name: 'A very long session name ' * 6);
        await open(tester, page: () => TestSessionPage.edit(session: long), width: 320, theme: theme);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
