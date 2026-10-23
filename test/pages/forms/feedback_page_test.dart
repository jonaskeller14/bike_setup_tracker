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
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/forms/feedback_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/feedback/feedback_aspect_row.dart';
import 'package:bike_setup_tracker/widgets/feedback/feedback_comparison_field.dart';
import 'package:bike_setup_tracker/widgets/lists/adjustment_compact_display/adjustment_compact_display_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bikeId = 'bike';
const _reboundId = 'rebound';

/// Add mode keeps a location spinner running, so pumpAndSettle never returns.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

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

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      null,
    );
  });

  Setup setup(String id, int day, int rebound, {String? name}) {
    final local = DateTime(2026, 5, day, 10);
    return Setup(
      id: id,
      name: name ?? id.toUpperCase(),
      datetime: local.toUtc(),
      datetimeLocal: local,
      tags: const {},
      bike: _bikeId,
      person: null,
      bikeAdjustmentValues: {_reboundId: StepValue(rebound)},
      personAdjustmentValues: const {},
    );
  }

  RideFeedback feedback({
    String id = 'f',
    required int day,
    required String setupId,
    Set<FeedbackObservation> observations = const {},
    Set<FeedbackComparison> comparisons = const {},
  }) {
    final local = DateTime(2026, 5, day, 12);
    return RideFeedback(
      id: id,
      bike: _bikeId,
      setupId: setupId,
      dateTimeUTC: local.toUtc(),
      dateTimeLocal: local,
      observations: observations,
      comparisons: comparisons,
    );
  }

  /// S1 (May 1) → S2 (May 2, rebound +2, flagged "Front: Harsh") → S3 (May 3).
  Future<void> seed(WidgetTester tester, {String? longName, List<RideFeedback> extraFeedbacks = const []}) async {
    await tester.runAsync(() async {
      database = AppDatabase.memory();
      appRepository = AppRepository(database);
      appSettings = AppSettings()..showOnboarding = false;
      await appRepository.addBikes([Bike(id: _bikeId, name: longName ?? 'Test Bike', person: null)]);
      await appRepository.addComponents([
        Component(
          id: 'fork',
          name: longName ?? 'Fork',
          componentType: ComponentType.fork,
          installations: [Installation.sinceBeginning(parent: _bikeId)],
          adjustments: [
            StepAdjustment(
              id: _reboundId,
              name: longName ?? 'Rebound',
              notes: '',
              unit: AdjustmentUnit.fromLegacy('clicks'),
              min: 0,
              max: 20,
              step: 1,
              visualization: StepAdjustmentVisualization.slider,
            ),
          ],
        ),
      ]);
      await appRepository.addSetups([
        setup('s1', 1, 5, name: longName),
        setup('s2', 2, 7, name: longName),
        setup('s3', 3, 7, name: longName),
      ]);
      final feedbacks = [
        feedback(
          id: 'f2',
          day: 2,
          setupId: 's2',
          observations: {const FeedbackObservation.flag(IssueKey(FeedbackEnd.front, FeedbackAttribute.comfort))},
        ),
        ...extraFeedbacks,
      ];
      await appRepository.addFeedbacks(feedbacks);
      for (var attempt = 0; attempt < 100; attempt++) {
        if (appRepository.setups.length == 3 && appRepository.feedbacks.length == feedbacks.length) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    addTearDown(() async {
      await tester.runAsync(() async {
        // Closing the database right after dispose() races its fire-and-forget
        // subscription cancellation and can hang; wait for cancellation first.
        await appRepository.disposeAndAwaitCancellation();
        appSettings.dispose();
        await database.close();
      });
    });
  }

  Future<void> openForm(
    WidgetTester tester,
    FeedbackPage Function() page, {
    ThemeData? theme,
    double width = 800,
  }) async {
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
          builder: (context, child) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await Navigator.push(context, MaterialPageRoute<RideFeedback>(builder: (_) => page())),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  FeedbackPage addOnMay(int day, {String? heroTag}) {
    final local = DateTime(2026, 5, day, 12);
    return FeedbackPage.add(
      initialBike: appRepository.bikes[_bikeId],
      initialDateTimeUtc: local.toUtc(),
      initialDateTimeLocal: local,
      heroTag: heroTag,
    );
  }

  Future<void> tapChip(WidgetTester tester, Finder chip) async {
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await settle(tester);
  }

  Finder overallChip(String label) => find.descendant(
    of: find.descendant(of: find.byType(FeedbackComparisonField), matching: find.byType(FeedbackOutcomeSelector)).first,
    matching: find.byTooltip(label),
  );
  Finder followUpChip(String label) =>
      find.descendant(of: find.byType(FeedbackAspectRow), matching: find.byTooltip(label));
  Finder issueChip(String label, FeedbackEnd end) {
    final chips = find.widgetWithText(FilterChip, label);
    return end == FeedbackEnd.front ? chips.first : chips.last;
  }

  bool isSelected(WidgetTester tester, Finder chip) => tester.widget<FilterChip>(chip).selected;

  /// Whether the face labelled [label] that [face] finds is the selected one.
  bool isFaceSelected(WidgetTester tester, Finder face, String label) {
    final button = tester.widget<SegmentedButton<int>>(
      find.ancestor(of: face, matching: find.byType(SegmentedButton<int>)).first,
    );
    return button.selected.contains(button.segments.firstWhere((s) => s.tooltip == label).value);
  }

  Future<RideFeedback?> save(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.check));
    await settle(tester);
    return result as RideFeedback?;
  }

  group('FeedbackPage add', () {
    testWidgets('saves the comparison, the follow-up and the chips as rows and keys', (tester) async {
      await seed(tester);
      await openForm(tester, () => addOnMay(3));

      expect(find.text('S3'), findsOneWidget, reason: 'rated setup');
      expect(
        tester.widget<DropdownButtonFormField<String>>(find.byType(DropdownButtonFormField<String>).last).initialValue,
        's2',
      );
      expect(find.text('No values changed'), findsOneWidget);
      expect(find.byType(FeedbackAspectRow), findsOneWidget);
      expect(find.text('Front: Harsh'), findsOneWidget);

      await tapChip(tester, overallChip('Slightly better'));
      await tapChip(tester, followUpChip('Better'));
      await tapChip(tester, issueChip('Bottoms out', FeedbackEnd.rear));
      await tester.enterText(find.widgetWithText(TextFormField, 'Notes (optional)'), '  dusty  ');
      await settle(tester);

      final saved = (await save(tester))!;
      expect(saved.setupId, 's3');
      expect(saved.bike, _bikeId);
      expect(saved.notes, 'dusty');
      expect(saved.comparisons, {
        const FeedbackComparison(referenceSetupId: 's2', aspect: OverallAspect(), outcome: 1),
        const FeedbackComparison(
          referenceSetupId: 's2',
          aspect: EndAspect(FeedbackEnd.front, FeedbackAttribute.comfort),
          outcome: 1,
        ),
      });
      expect(saved.observations, {
        const FeedbackObservation.flag(IssueKey(FeedbackEnd.rear, FeedbackAttribute.bottoming)),
      });
    });

    testWidgets('shows the changed values since the reference', (tester) async {
      await seed(tester);
      await openForm(tester, () => addOnMay(2));

      expect(find.byType(AdjustmentCompactDisplayList), findsOneWidget);
      expect(find.bySemanticsLabel('Rebound, changed from 5 to 7 clicks'), findsOneWidget);
      expect(find.text('No values changed'), findsNothing);
      expect(find.byType(FeedbackAspectRow), findsNothing, reason: 'S1 has no open issues');
    });

    testWidgets('tapping the selected outcome clears it', (tester) async {
      await seed(tester);
      await openForm(tester, () => addOnMay(3));

      await tapChip(tester, overallChip('Worse'));
      await tapChip(tester, overallChip('Worse'));

      expect((await save(tester))!.comparisons, isEmpty);
    });

    testWidgets('"Nothing stood out" clears the chips and a chip clears it', (tester) async {
      await seed(tester);
      await openForm(tester, () => addOnMay(3));

      await tapChip(tester, issueChip('Harsh', FeedbackEnd.front));
      await tapChip(tester, issueChip('Low grip', FeedbackEnd.rear));
      await tapChip(tester, find.widgetWithText(FilterChip, FeedbackVocabulary.nothingStoodOut));

      expect(isSelected(tester, issueChip('Harsh', FeedbackEnd.front)), isFalse);
      expect(isSelected(tester, issueChip('Low grip', FeedbackEnd.rear)), isFalse);
      expect(isSelected(tester, find.widgetWithText(FilterChip, FeedbackVocabulary.nothingStoodOut)), isTrue);
      expect(find.textContaining(FeedbackAttribute.comfort.hint, findRichText: true), findsNothing);

      await tapChip(tester, issueChip('Unsettled', FeedbackEnd.front));

      expect(isSelected(tester, find.widgetWithText(FilterChip, FeedbackVocabulary.nothingStoodOut)), isFalse);
      expect((await save(tester))!.observations, {
        const FeedbackObservation.flag(IssueKey(FeedbackEnd.front, FeedbackAttribute.calm)),
      });
    });

    testWidgets('shows the hint of a selected chip', (tester) async {
      await seed(tester);
      await openForm(tester, () => addOnMay(3));

      expect(find.textContaining(FeedbackAttribute.comfort.hint, findRichText: true), findsNothing);
      await tapChip(tester, issueChip('Harsh', FeedbackEnd.front));
      expect(find.textContaining(FeedbackAttribute.comfort.hint, findRichText: true), findsOneWidget);
    });

    testWidgets('says when a new time rates another setup', (tester) async {
      await seed(tester);
      await openForm(tester, () => addOnMay(3));
      expect(find.text('S3'), findsOneWidget);

      final timeChip = find.widgetWithText(ActionChip, '12:00');
      await tester.ensureVisible(timeChip);
      await tester.tap(timeChip);
      await settle(tester);
      await tester.tap(find.byTooltip('Switch to text input mode'));
      await settle(tester);
      final fields = find.descendant(of: find.byType(TimePickerDialog), matching: find.byType(TextField));
      await tester.enterText(fields.first, '09');
      await tester.enterText(fields.last, '00');
      await tester.tap(find.text('OK'));
      await settle(tester);

      expect(find.text("Now rating 'S2'."), findsOneWidget);
      expect(find.text('S2'), findsOneWidget, reason: 'rated setup card');
    });

    testWidgets('changing the reference changes the follow-ups', (tester) async {
      await seed(tester);
      await openForm(tester, () => addOnMay(3));
      await tapChip(tester, followUpChip('Worse'));
      await tapChip(tester, overallChip('Same'));

      await tester.tap(find.byType(DropdownButtonFormField<String>).last);
      await settle(tester);
      await tester.tap(find.text('S1').last);
      await settle(tester);

      expect(find.byType(FeedbackAspectRow), findsNothing);
      expect(find.byType(AdjustmentCompactDisplayList), findsOneWidget);
      expect((await save(tester))!.comparisons, {
        const FeedbackComparison(referenceSetupId: 's1', aspect: OverallAspect(), outcome: 0),
      });
    });

    testWidgets('the rated setup card flies in but not back out', (tester) async {
      await seed(tester);
      await openForm(tester, () => addOnMay(3, heroTag: 'tile'));
      bool heroEnabled() =>
          tester.widget<HeroMode>(find.ancestor(of: find.byType(Hero), matching: find.byType(HeroMode)).first).enabled;

      expect(find.byType(Hero), findsOneWidget);
      expect(heroEnabled(), isTrue);

      await tester.pageBack();
      await tester.pump();

      expect(heroEnabled(), isFalse);
      await settle(tester);
      expect(find.byType(FeedbackPage), findsNothing);
    });

    testWidgets('the card header flies in from a smaller tile header without overflowing', (tester) async {
      await seed(tester);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appSettings),
            ChangeNotifierProvider.value(value: appRepository),
          ],
          child: MaterialApp(
            theme: materialAppTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    const Hero(
                      tag: 'tile',
                      child: SizedBox(width: 200, height: 24, child: Text('tile')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<RideFeedback>(builder: (_) => addOnMay(3, heroTag: 'tile')),
                      ),
                      child: const Text('open'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 30));
        expect(tester.takeException(), isNull, reason: 'frame $frame');
      }
      await settle(tester);
      expect(find.byType(FeedbackPage), findsOneWidget);
    });

    testWidgets('hides the comparison when no earlier setup exists', (tester) async {
      await seed(tester);
      await openForm(tester, () => addOnMay(1));

      expect(find.text('S1'), findsOneWidget);
      expect(find.byType(FeedbackComparisonField), findsNothing);
      expect((await save(tester))!.setupId, 's1');
    });

    testWidgets('blocks saving when no setup precedes the time', (tester) async {
      await seed(tester);
      final local = DateTime(2026, 4, 1, 12);
      await openForm(
        tester,
        () => FeedbackPage.add(
          initialBike: appRepository.bikes[_bikeId],
          initialDateTimeUtc: local.toUtc(),
          initialDateTimeLocal: local,
        ),
      );

      expect(find.textContaining('No setup at this time'), findsOneWidget);
      expect(find.byType(FeedbackComparisonField), findsNothing);

      await tester.tap(find.byIcon(Icons.check));
      await tester.pump();

      expect(find.textContaining('No setup exists before this date/time'), findsOneWidget);
      expect(find.byType(FeedbackPage), findsOneWidget);
      await settle(tester);
      expect(result, isNull);
    });
  });

  group('FeedbackPage edit', () {
    final storedComparisons = {
      const FeedbackComparison(referenceSetupId: 's2', aspect: OverallAspect(), outcome: 2),
      const FeedbackComparison(
        referenceSetupId: 's2',
        aspect: EndAspect(FeedbackEnd.front, FeedbackAttribute.comfort),
        outcome: -1,
      ),
      const FeedbackComparison(referenceSetupId: 's1', aspect: OverallAspect(), outcome: 1),
      const FeedbackComparison(referenceSetupId: 's2', aspect: UnknownAspect('front.flex'), outcome: 1),
    };
    final storedObservations = {
      const FeedbackObservation.flag(IssueKey(FeedbackEnd.rear, FeedbackAttribute.grip)),
      const FeedbackObservation(key: UnknownFeedbackKey('future:m1'), value: 3, textValue: '3'),
      const FeedbackObservation(key: UnknownFeedbackKey('future.key'), value: 1),
    };
    RideFeedback stored({String setupId = 's3'}) => feedback(
      id: 'f3',
      day: 3,
      setupId: setupId,
      comparisons: storedComparisons,
      observations: storedObservations,
    );

    testWidgets('shows the stored answers and saves them unchanged', (tester) async {
      await seed(tester, extraFeedbacks: [stored()]);
      await openForm(tester, () => FeedbackPage.edit(feedback: appRepository.feedbacks['f3']!));

      expect(isFaceSelected(tester, overallChip('Better'), 'Better'), isTrue);
      expect(isFaceSelected(tester, followUpChip('Worse'), 'Worse'), isTrue);
      expect(isSelected(tester, issueChip('Low grip', FeedbackEnd.rear)), isTrue);
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isTrue);

      final saved = (await save(tester))!;
      expect(saved.id, 'f3');
      expect(saved.comparisons, storedComparisons);
      expect(saved.observations, storedObservations);
    });

    testWidgets('keeps answers the form does not show when others change', (tester) async {
      await seed(tester, extraFeedbacks: [stored()]);
      await openForm(tester, () => FeedbackPage.edit(feedback: appRepository.feedbacks['f3']!));

      await tapChip(tester, overallChip('Slightly worse'));
      await tapChip(tester, find.widgetWithText(FilterChip, FeedbackVocabulary.nothingStoodOut));
      expect(tester.widget<PopScope>(find.byType(PopScope)).canPop, isFalse);

      final saved = (await save(tester))!;
      expect(saved.comparisons, {
        const FeedbackComparison(referenceSetupId: 's2', aspect: OverallAspect(), outcome: -1),
        ...storedComparisons.where((c) => !(c.referenceSetupId == 's2' && c.aspect is OverallAspect)),
      });
      expect(saved.observations, {
        const FeedbackObservation.flag(NoIssueKey()),
        const FeedbackObservation(key: UnknownFeedbackKey('future:m1'), value: 3, textValue: '3'),
        const FeedbackObservation(key: UnknownFeedbackKey('future.key'), value: 1),
      });
    });

    testWidgets('shows the drift warning and relinks to the resolved setup', (tester) async {
      await seed(tester, extraFeedbacks: [stored(setupId: 's1')]);
      await openForm(tester, () => FeedbackPage.edit(feedback: appRepository.feedbacks['f3']!));

      expect(find.text('Setup link changed'), findsOneWidget);
      await tester.tap(find.text('Relink'));
      await settle(tester);
      expect(find.text('Setup link changed'), findsNothing);

      expect((await save(tester))!.setupId, 's3');
    });
  });

  for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
    testWidgets('long names and all chips fit a narrow screen ($label)', (tester) async {
      await seed(tester, longName: 'Very long setup name that keeps going ' * 4);
      await openForm(tester, () => addOnMay(3), theme: theme, width: 320);

      expect(find.byType(FeedbackComparisonField), findsOneWidget);
      expect(find.byType(FeedbackAspectRow), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
