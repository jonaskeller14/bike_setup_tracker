import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/strava/strava_plan.dart';
import 'package:bike_setup_tracker/models/strava/strava_store_offer.dart';
import 'package:bike_setup_tracker/services/strava_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_6.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSubscriptionService extends Mock implements SubscriptionService {}

class MockStravaService extends Mock implements StravaService {}

class MockStravaStoreOffer extends Mock implements StravaStoreOffer {}

void main() {
  late MockSubscriptionService subscription;
  late MockStravaService strava;
  late AppSettings appSettings;

  setUpAll(() => registerFallbackValue(StravaPlan.yearly));

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    subscription = MockSubscriptionService();
    strava = MockStravaService();
    appSettings = AppSettings();

    // Default: a fresh rider with nothing resolved yet. Tests override.
    when(() => subscription.hasStravaEntitlement).thenReturn(false);
    when(() => subscription.isRestoring).thenReturn(false);
    when(() => subscription.offersReady).thenReturn(false);
    when(() => subscription.offerFor(any())).thenReturn(null);
    when(() => strava.isConnected).thenReturn(false);
    when(() => strava.availability).thenReturn(null);
    when(() => strava.checkAvailability()).thenAnswer((_) async => StravaAvailability.networkError);
  });

  tearDown(() => appSettings.dispose());

  /// Offers loaded, a slot available — the state in which a real price and
  /// therefore a real purchase label can be shown.
  void storeReady({required bool trialEligible}) {
    final offer = MockStravaStoreOffer();
    when(() => offer.isTrialEligible).thenReturn(trialEligible);
    when(() => subscription.offersReady).thenReturn(true);
    when(() => subscription.offerFor(any())).thenReturn(offer);
    when(() => strava.availability).thenReturn(StravaAvailability.available);
  }

  Future<void> pumpSlide(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppSettings>.value(value: appSettings),
          ChangeNotifierProvider<SubscriptionService>.value(value: subscription),
          ChangeNotifierProvider<StravaService>.value(value: strava),
        ],
        child: MaterialApp(
          theme: materialAppTheme,
          home: Scaffold(
            body: OnboardingSlide6(onFinish: () => appSettings.showOnboarding = false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Strava call to action', () {
    testWidgets('stays neutral while the store has not answered', (WidgetTester tester) async {
      await pumpSlide(tester);

      expect(find.text('Explore Strava Sync'), findsOneWidget);
    });

    testWidgets('stays neutral when no slot is available', (WidgetTester tester) async {
      storeReady(trialEligible: true);
      when(() => strava.availability).thenReturn(StravaAvailability.full);

      await pumpSlide(tester);

      expect(find.text('Explore Strava Sync'), findsOneWidget);
    });

    testWidgets('offers the trial only when the store grants one', (WidgetTester tester) async {
      storeReady(trialEligible: true);

      await pumpSlide(tester);

      expect(find.text('Start 7-day free trial'), findsOneWidget);
    });

    testWidgets('falls back to Subscribe without trial eligibility', (WidgetTester tester) async {
      storeReady(trialEligible: false);

      await pumpSlide(tester);

      expect(find.text('Subscribe'), findsOneWidget);
    });

    testWidgets('asks an entitled rider to connect Strava', (WidgetTester tester) async {
      when(() => subscription.hasStravaEntitlement).thenReturn(true);

      await pumpSlide(tester);

      expect(find.text('Connect Strava'), findsOneWidget);
    });

    testWidgets('opens Strava Sync once connected', (WidgetTester tester) async {
      when(() => subscription.hasStravaEntitlement).thenReturn(true);
      when(() => strava.isConnected).thenReturn(true);

      await pumpSlide(tester);

      expect(find.text('Open Strava Sync'), findsOneWidget);
    });
  });

  group('Completion', () {
    testWidgets('the Strava action opens the sheet without completing onboarding', (WidgetTester tester) async {
      // Offline: the sheet owns that state and says so itself.
      when(() => strava.availability).thenReturn(StravaAvailability.networkError);

      await pumpSlide(tester);
      await tester.ensureVisible(find.text('Explore Strava Sync'));
      await tester.tap(find.text('Explore Strava Sync'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(appSettings.showOnboarding, isTrue);
    });

    testWidgets('Continue free completes onboarding', (WidgetTester tester) async {
      await pumpSlide(tester);

      expect(find.text('Continue free'), findsOneWidget);
      await tester.tap(find.text('Continue free'));
      await tester.pumpAndSettle();

      expect(appSettings.showOnboarding, isFalse);
    });

    testWidgets('the finish action drops "free" once the subscription is held', (WidgetTester tester) async {
      when(() => subscription.hasStravaEntitlement).thenReturn(true);

      await pumpSlide(tester);

      expect(find.text('Continue free'), findsNothing);
      expect(find.text('Continue'), findsOneWidget);
    });
  });
}
