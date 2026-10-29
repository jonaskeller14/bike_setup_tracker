import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/feedback/ride_feedback.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/pages/forms/feedback_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/strava_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/feedback/strava_feedback_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockStravaService extends Mock implements StravaService {}

const _bikeId = 'bike';

void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;
  late MockStravaService strava;

  final setupStart = DateTime(2026, 6, 1, 10);

  StravaActivity ride(int id, DateTime start) => StravaActivity(
    id: id,
    name: 'Ride $id',
    athlete: 1,
    sportType: SportType.Ride,
    startDate: start.toUtc(),
    startDateLocal: start,
    gearId: 'gear_1',
    startLat: null,
    startLon: null,
    distance: null,
    totalElevationGain: null,
    movingTime: Duration.zero,
    elapsedTime: Duration.zero,
  );

  Future<void> seed(WidgetTester tester, {bool enableRating = true, bool connected = true}) async {
    SharedPreferences.setMockInitialValues({});
    strava = MockStravaService();
    when(() => strava.isConnected).thenReturn(connected);
    await tester.runAsync(() async {
      database = AppDatabase.memory();
      appRepository = AppRepository(database);
      appSettings = AppSettings()
        ..showOnboarding = false
        ..enableRating = enableRating;
      await appRepository.addBikes([Bike(id: _bikeId, name: 'Test Bike', person: null, stravaGear: 'gear_1')]);
      await appRepository.addSetups([
        Setup(
          id: 's1',
          name: 'S1',
          datetime: setupStart.toUtc(),
          datetimeLocal: setupStart,
          tags: const {},
          bike: _bikeId,
          person: null,
          bikeAdjustmentValues: const {},
          personAdjustmentValues: const {},
        ),
      ]);
      for (var i = 0; i < 40 && appRepository.setups.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
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

  Future<void> pump(WidgetTester tester, StravaActivity activity, {bool compact = false, double width = 320}) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appRepository),
          ChangeNotifierProvider<StravaService>.value(value: strava),
        ],
        child: MaterialApp(
          theme: materialAppTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: StravaFeedbackPrompt(stravaActivity: activity, compact: compact),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('offers feedback for a ride since the current setup', (tester) async {
    await seed(tester);
    await pump(tester, ride(1, DateTime(2026, 6, 2)));

    expect(find.text('Add feedback for this ride'), findsOneWidget);
  });

  testWidgets('the compact variant fits a narrow tile', (tester) async {
    await seed(tester);
    await pump(tester, ride(1, DateTime(2026, 6, 2)), compact: true, width: 120);

    expect(find.text('Add feedback'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('is hidden when Feedback is off', (tester) async {
    await seed(tester, enableRating: false);
    await pump(tester, ride(1, DateTime(2026, 6, 2)));

    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('is hidden without a Strava connection', (tester) async {
    await seed(tester, connected: false);
    await pump(tester, ride(1, DateTime(2026, 6, 2)));

    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('is hidden for a ride before the current setup', (tester) async {
    await seed(tester);
    await pump(tester, ride(1, DateTime(2026, 5, 20)));

    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('is hidden once a feedback is linked to the ride', (tester) async {
    await seed(tester);
    final activity = ride(1, DateTime(2026, 6, 2));
    await pump(tester, activity);
    expect(find.byType(FilledButton), findsOneWidget);

    final at = DateTime(2026, 6, 2, 18);
    await tester.runAsync(() async {
      await appRepository.addFeedbacks([
        RideFeedback(
          bike: _bikeId,
          setupId: 's1',
          stravaActivityId: activity.id,
          dateTimeUTC: at.toUtc(),
          dateTimeLocal: at,
        ),
      ]);
      for (var i = 0; i < 40 && appRepository.feedbacks.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    await tester.pump();

    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('opens the feedback form for the ride', (tester) async {
    await seed(tester);
    await pump(tester, ride(1, DateTime(2026, 6, 2)));

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(FeedbackPage), findsOneWidget);
  });
}
