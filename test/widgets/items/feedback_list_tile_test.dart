import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_comparison.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_key.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_observation.dart';
import 'package:bike_setup_tracker/models/feedback/feedback_vocabulary.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/details/feedback_details_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/items/feedback_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _bikeId = 'bike';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> waitFor(bool Function() condition) async {
  for (var i = 0; i < 40 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}

Setup _setup(String id, String name, DateTime local) => Setup(
  id: id,
  name: name,
  datetime: local.toUtc(),
  datetimeLocal: local,
  tags: const {},
  bike: _bikeId,
  person: null,
  bikeAdjustmentValues: const {},
  personAdjustmentValues: const {},
);

void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;

  /// Rides on S2 but was saved for S1 (drift), compared with S1, flags the rear
  /// and carries a Strava link that never synced.
  RideFeedback feedback({String notes = 'Felt fast'}) {
    final local = DateTime(2026, 5, 2, 12);
    return RideFeedback(
      id: 'f1',
      bike: _bikeId,
      setupId: 's1',
      stravaActivityId: 42,
      dateTimeUTC: local.toUtc(),
      dateTimeLocal: local,
      notes: notes,
      observations: {
        const FeedbackObservation.flag(IssueKey(FeedbackEnd.rear, FeedbackAttribute.grip)),
      },
      comparisons: {
        const FeedbackComparison(referenceSetupId: 's1', aspect: OverallAspect(), outcome: 1),
        const FeedbackComparison(
          referenceSetupId: 's1',
          aspect: EndAspect(FeedbackEnd.front, FeedbackAttribute.comfort),
          outcome: 1,
        ),
      },
    );
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> seed(WidgetTester tester, {String s1Name = 'S1', String s2Name = 'S2', String? notes}) async {
    await tester.runAsync(() async {
      database = AppDatabase.memory();
      appRepository = AppRepository(database);
      appSettings = AppSettings()
        ..showOnboarding = false
        ..enableRating = true;
      await appRepository.addBikes([Bike(id: _bikeId, name: 'Test Bike', person: null)]);
      await appRepository.addSetups([
        _setup('s1', s1Name, DateTime(2026, 5, 1, 10)),
        _setup('s2', s2Name, DateTime(2026, 5, 2, 10)),
      ]);
      await appRepository.addFeedbacks([notes == null ? feedback() : feedback(notes: notes)]);
      await waitFor(() => appRepository.setups.length == 2 && appRepository.feedbacks.length == 1);
    });
    addTearDown(() async {
      await tester.runAsync(() async {
        await appRepository.disposeAndAwaitCancellation();
        appSettings.dispose();
        await database.close();
      });
    });
  }

  Future<void> pump(WidgetTester tester, Widget child, {double width = 400, ThemeData? theme}) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appRepository),
        ],
        child: MaterialApp(
          theme: theme ?? materialAppTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(width: width, child: child),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('the tile shows the verdict, the drift, the flags and the notes', (tester) async {
    await seed(tester);
    await pump(tester, FeedbackListTile(feedback: appRepository.feedbacks['f1']!));

    expect(find.text('Slightly better than S1'), findsOneWidget);
    expect(find.text("Originally 'S1', now 'S2'"), findsOneWidget);
    expect(find.text('Rear: Low grip'), findsOneWidget);
    expect(find.text('Felt fast'), findsOneWidget);
  });

  testWidgets('a tap opens the details with every answer', (tester) async {
    await seed(tester);
    await pump(tester, FeedbackListTile(feedback: appRepository.feedbacks['f1']!));

    await tester.tap(find.text('Slightly better than S1'));
    await settle(tester);

    final details = find.byType(FeedbackDetailsContent);
    expect(details, findsOneWidget);
    Finder inDetails(String text) => find.descendant(of: details, matching: find.text(text));
    expect(inDetails('S2'), findsOneWidget);
    expect(inDetails("Originally 'S1'"), findsOneWidget);
    expect(inDetails('Strava ride not synced'), findsOneWidget);
    expect(inDetails('Compared to'), findsOneWidget);
    expect(inDetails('S1'), findsOneWidget);
    expect(inDetails('Slightly better'), findsOneWidget);
    expect(inDetails('Front: Harsh'), findsOneWidget);
    expect(inDetails('Better'), findsOneWidget);
    expect(inDetails('Rear: Low grip'), findsOneWidget);
  });

  testWidgets('in selection mode a tap toggles the selection and the menu is gone', (tester) async {
    await seed(tester);
    var toggles = 0;
    await pump(
      tester,
      FeedbackListTile(
        feedback: appRepository.feedbacks['f1']!,
        selectionMode: true,
        onSelectionChanged: () => toggles++,
      ),
    );

    expect(find.byType(PopupMenuButton<Object>), findsNothing);
    await tester.tap(find.text('Slightly better than S1'));
    await settle(tester);

    expect(toggles, 1);
    expect(find.byType(FeedbackDetailsContent), findsNothing);
  });

  for (final (label, theme) in [('light', materialAppTheme), ('dark', materialAppDarkTheme)]) {
    testWidgets('long names fit a 320 px screen in the $label theme', (tester) async {
      final long = 'A very long setup name that keeps going ' * 3;
      await seed(tester, s1Name: long, s2Name: long, notes: 'Notes ' * 40);
      await pump(tester, FeedbackListTile(feedback: appRepository.feedbacks['f1']!), width: 320, theme: theme);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(FeedbackListTile));
      await settle(tester);
      expect(find.byType(FeedbackDetailsContent), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
