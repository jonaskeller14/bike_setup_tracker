import 'dart:io';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/feedback/custom_issue.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_comparison.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/feedback/test_session.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/custom_issue_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bikeId = 'bike';
const _wetRoots = CustomIssue('wet roots', 'Wet roots');
const _loose = CustomIssue('loose', 'Loose');
const _frontCalm = EndAspect(FeedbackEnd.front, FeedbackAttribute.calm);

Setup _setup(String id, DateTime local) => Setup(
  id: id,
  name: id.toUpperCase(),
  datetime: local.toUtc(),
  datetimeLocal: local,
  tags: const {},
  bike: _bikeId,
  person: null,
  bikeAdjustmentValues: const {},
  personAdjustmentValues: const {},
);

RideFeedback _feedback(String id, int day, List<CustomIssue> issues, {Set<FeedbackComparison>? comparisons}) {
  final local = DateTime(2026, 5, day, 12);
  return RideFeedback(
    id: id,
    bike: _bikeId,
    setupId: 's2',
    dateTimeUTC: local.toUtc(),
    dateTimeLocal: local,
    observations: {for (final issue in issues) issue.toObservation()},
    comparisons: comparisons,
  );
}

TestSession _session(String id, List<FeedbackAspect> goal) => TestSession(
  id: id,
  bike: _bikeId,
  adjustmentIds: const ['a'],
  goal: goal,
  startedAtUTC: DateTime.utc(2026, 5, 3),
  startedAtLocal: DateTime(2026, 5, 3),
);

Future<void> _waitFor(bool Function() condition) async {
  for (var attempt = 0; attempt < 100 && !condition(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
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

  /// Two live feedbacks, one trashed feedback, a live and a trashed session.
  Future<void> seed(WidgetTester tester) async {
    await tester.runAsync(() async {
      database = AppDatabase.memory();
      appRepository = AppRepository(database);
      appSettings = AppSettings()..showOnboarding = false;
      await appRepository.addBikes([Bike(id: _bikeId, name: 'Test Bike', person: null)]);
      await appRepository.addSetups([_setup('s1', DateTime(2026, 5, 1, 10)), _setup('s2', DateTime(2026, 5, 2, 10))]);
      await appRepository.addFeedbacks([
        _feedback(
          'a',
          3,
          [_wetRoots, _loose],
          comparisons: {
            FeedbackComparison(referenceSetupId: 's1', aspect: _wetRoots.aspect, outcome: 1),
            const FeedbackComparison(referenceSetupId: 's1', aspect: _frontCalm, outcome: -1),
          },
        ),
        _feedback('b', 4, [_wetRoots]),
        _feedback('c', 5, [_wetRoots]),
      ]);
      await _waitFor(() => appRepository.feedbacks.length == 3);
      await appRepository.removeFeedbacks([appRepository.feedbacks['c']!]);
      await appRepository.addTestSessions([
        _session('live', [_frontCalm, _wetRoots.aspect]),
        _session('trashed', [_wetRoots.aspect]),
      ]);
      await _waitFor(() => appRepository.testSessions.length == 2);
      await appRepository.removeTestSessions([appRepository.testSessions['trashed']!]);
      await _waitFor(() => appRepository.deletedFeedbacks.length == 1 && appRepository.deletedTestSessions.length == 1);
    });
    addTearDown(() async {
      await tester.runAsync(() async {
        await appRepository.disposeAndAwaitCancellation();
        appSettings.dispose();
        await database.close();
      });
    });
  }

  Future<void> pumpButton(WidgetTester tester, String label, Future<void> Function(BuildContext) onPressed) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appRepository),
        ],
        child: MaterialApp(
          theme: materialAppTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(onPressed: () => onPressed(context), child: Text(label)),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> renameTo(WidgetTester tester, String label) async {
    await pumpButton(
      tester,
      'rename',
      (context) => CustomIssueActions.rename(context, issue: _wetRoots),
    );
    await tester.tap(find.text('rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), label);
    await tester.tap(find.widgetWithText(TextButton, 'Rename'));
    await tester.pump();
    await tester.runAsync(() => _waitFor(() => appRepository.feedbacks['b']!.customIssues.single.slug != 'wet roots'));
    await tester.pumpAndSettle();
  }

  testWidgets('rename rewrites live and trashed feedbacks, comparisons and goals', (tester) async {
    await seed(tester);

    await renameTo(tester, 'Slippery roots');

    const slippery = CustomIssue('slippery roots', 'Slippery roots');
    expect(appRepository.feedbacks['b']!.customIssues, [slippery]);
    expect(appRepository.feedbacks['a']!.customIssues, [_loose, slippery]);
    expect(appRepository.feedbacks['a']!.comparisons, {
      FeedbackComparison(referenceSetupId: 's1', aspect: slippery.aspect, outcome: 1),
      const FeedbackComparison(referenceSetupId: 's1', aspect: _frontCalm, outcome: -1),
    });
    expect(appRepository.deletedFeedbacks.single.customIssues, [slippery]);
    expect(appRepository.testSessions['live']!.goal, [_frontCalm, slippery.aspect]);
    expect(appRepository.deletedTestSessions.single.goal, [slippery.aspect]);
    expect(appRepository.customIssues.contains('wet roots'), isFalse);
    expect(find.text('Issue renamed.'), findsOneWidget);
  });

  testWidgets('rename to an existing issue merges and takes its label', (tester) async {
    await seed(tester);

    await renameTo(tester, 'loose');

    expect(find.text('Merged into "loose".'), findsOneWidget);
    expect(appRepository.feedbacks['a']!.customIssues, [const CustomIssue('loose', 'loose')]);
    expect(appRepository.feedbacks['b']!.customIssues, [const CustomIssue('loose', 'loose')]);
    expect(appRepository.customIssues.usages.map((u) => u.slug), ['loose']);
  });

  testWidgets('renaming to the same label changes nothing', (tester) async {
    await seed(tester);
    final before = appRepository.feedbacks['b']!;
    await pumpButton(
      tester,
      'rename',
      (context) => CustomIssueActions.rename(context, issue: _wetRoots),
    );
    await tester.tap(find.text('rename'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Rename'));
    await tester.pumpAndSettle();

    expect(appRepository.feedbacks['b'], before);
    expect(find.text('Issue renamed.'), findsNothing);
  });

  testWidgets('remove strips the issue from feedbacks, comparisons and goals after a confirmation', (tester) async {
    await seed(tester);
    await pumpButton(
      tester,
      'remove',
      (context) => CustomIssueActions.remove(context, issue: _wetRoots),
    );

    await tester.tap(find.text('remove'));
    await tester.pumpAndSettle();
    expect(find.text('Remove "Wet roots"?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Remove'));
    await tester.pump();
    await tester.runAsync(() => _waitFor(() => appRepository.feedbacks['b']!.customIssues.isEmpty));
    await tester.pumpAndSettle();

    expect(appRepository.feedbacks['a']!.customIssues, [_loose]);
    expect(appRepository.feedbacks['a']!.comparisons.map((c) => c.aspect), [_frontCalm]);
    expect(appRepository.deletedFeedbacks.single.customIssues, isEmpty);
    expect(appRepository.testSessions['live']!.goal, [_frontCalm]);
    expect(appRepository.deletedTestSessions.single.goal, isEmpty);
    expect(find.text('Issue removed.'), findsOneWidget);
  });

  testWidgets('cancelling the confirmation keeps the issue', (tester) async {
    await seed(tester);
    await pumpButton(
      tester,
      'remove',
      (context) => CustomIssueActions.remove(context, issue: _wetRoots),
    );

    await tester.tap(find.text('remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(appRepository.feedbacks['b']!.customIssues, [_wetRoots]);
    expect(find.text('Issue removed.'), findsNothing);
  });
}
