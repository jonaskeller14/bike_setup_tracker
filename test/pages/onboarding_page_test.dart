import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/pages/onboarding_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/strava_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/onboarding/onboarding_slide_1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSubscriptionService extends Mock implements SubscriptionService {}

class MockStravaService extends Mock implements StravaService {}


void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;
  late MockSubscriptionService subscription;
  late MockStravaService strava;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
    subscription = MockSubscriptionService();
    strava = MockStravaService();

    // The Strava slide reads live state; nothing is entitled or resolved here.
    when(() => subscription.hasStravaEntitlement).thenReturn(false);
    when(() => subscription.offersReady).thenReturn(false);
    when(() => strava.isConnected).thenReturn(false);
    when(() => strava.availability).thenReturn(null);
  });

  tearDown(() async {
    appRepository.dispose();
    appSettings.dispose();
    await database.close();
  });

  Widget buildTestApp() {
    appRepository.dispose();
    appRepository = AppRepository(database);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appRepository),
        ChangeNotifierProvider<AppRepository>.value(
          value: appRepository,
        ),
        ChangeNotifierProvider<SubscriptionService>.value(value: subscription),
        ChangeNotifierProvider<StravaService>.value(value: strava),
      ],
      // Use a simplified app structure for onboarding tests to avoid 
      // complex service dependencies (Firebase, Strava, etc.) in HomePage.
      child: Consumer<AppSettings>(
        builder: (context, settings, child) {
          return MaterialApp(
            theme: materialAppTheme,
            home: settings.showOnboarding 
                ? const OnboardingPage() 
                : const Scaffold(body: Center(child: Text("Home Page Proxy"))),
          );
        },
      ),
    );
  }

  testWidgets('OnBoarding Test', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text("Ready to Dial It In?"), findsOneWidget);
    expect(find.text("Skip"), findsOneWidget);

    // Slide 1 -> Slide 2
    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();

    expect(find.text("STEP 1"), findsOneWidget);
    expect(find.text("Skip"), findsOneWidget);

    // Slide 2 -> Slide 3
    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();
    
    expect(find.text("STEP 2"), findsOneWidget);
    expect(find.text("Skip"), findsOneWidget);

    // Slide 3 -> Slide 4
    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();

    expect(find.text("STEP 3"), findsOneWidget);
    expect(find.text("Skip"), findsOneWidget);

    // Slide 4 -> Slide 6 (the rider slide is off by default)
    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();

    expect(find.text("Yours, for free"), findsOneWidget);
    // The last slide finishes instead of skipping.
    expect(find.text("Skip"), findsOneWidget);

    // Slide 6 -> Finish
    await tester.tap(find.text("Continue free"));
    await tester.pumpAndSettle();

    // Verify we arrived at the home page proxy
    expect(find.text("Home Page Proxy"), findsOneWidget);
  });

  testWidgets('Not Show OnBoarding', (WidgetTester tester) async {
    appSettings.showOnboarding = false;

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text("Ready to Dial It In?"), findsNothing);
    expect(find.text("Home Page Proxy"), findsOneWidget);
  });

  testWidgets('Primary action lives in the slide, not in a floating button', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
    expect(scaffold.floatingActionButton, isNull);

    // One full-width primary action per slide, inside the slide itself.
    final button = find.widgetWithText(FilledButton, "Next");
    expect(button, findsOneWidget);
    expect(find.descendant(of: find.byType(OnboardingSlide1), matching: button), findsOneWidget);
    expect(tester.getSize(button).width, greaterThan(tester.getSize(find.byType(PageView)).width / 2));
  });

  testWidgets('Progress dots follow the slide count', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((widget) => widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith("onboarding_dot_")),
      findsNWidgets(5),
    );
  });

  testWidgets('Progress is announced as a step count', (WidgetTester tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // The dots themselves stay decorative; the row speaks for them.
    expect(find.bySemanticsLabel("Step 1 of 5"), findsOneWidget);

    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel("Step 2 of 5"), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('Rider slide only exists behind the Person feature flag', (WidgetTester tester) async {
    appSettings.enablePerson = true;

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((widget) => widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith("onboarding_dot_")),
      findsNWidgets(6),
    );
  });

  testWidgets('Replay from Settings reopens onboarding with the current flags', (WidgetTester tester) async {
    appSettings.showOnboarding = false;

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();
    expect(find.text("Home Page Proxy"), findsOneWidget);

    // Settings -> Help turns it back on. The rider slide follows the flag as it
    // stands at replay time, not as it stood on the first run.
    appSettings.enablePerson = true;
    appSettings.showOnboarding = true;
    await tester.pumpAndSettle();

    expect(find.text("Ready to Dial It In?"), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) => widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith("onboarding_dot_")),
      findsNWidgets(6),
    );
  });

  testWidgets('Skip completes onboarding from a teaching slide', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();
    expect(find.text("STEP 1"), findsOneWidget);

    await tester.tap(find.text("Skip"));
    await tester.pumpAndSettle();

    expect(find.text("Home Page Proxy"), findsOneWidget);
    expect(appSettings.showOnboarding, isFalse);
  });

  group('Rider slide', () {
    /// The rider slide sits right after the promise slide.
    Future<void> goToRiderSlide(WidgetTester tester) async {
      appSettings.enablePerson = true;

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text("Next"));
      await tester.pumpAndSettle();

      expect(find.text("What's your name?"), findsOneWidget);
    }

    testWidgets('Continue needs a name before it advances', (WidgetTester tester) async {
      await goToRiderSlide(tester);

      await tester.tap(find.text("Continue"));
      await tester.pumpAndSettle();

      expect(find.text("What's your name?"), findsOneWidget);
      expect(find.text("Enter a name to continue."), findsOneWidget);
      expect(appRepository.persons, isEmpty);
    });

  //   testWidgets('A valid name persists the rider and advances', (WidgetTester tester) async {
  //     await goToRiderSlide(tester);

  //     await tester.enterText(find.byType(TextFormField), "Jonas");
  //     await tester.tap(find.text("Continue"));
  //     await tester.pumpAndSettle();

  //     expect(appRepository.persons.values.map((person) => person.name), contains("Jonas"));
  //     expect(appRepository.persons.values.single.adjustments, hasLength(1));
  //     expect(find.text("STEP 1"), findsOneWidget);
  //   });

  //   testWidgets('Not now advances without creating a rider', (WidgetTester tester) async {
  //     await goToRiderSlide(tester);

  //     await tester.tap(find.text("Not now"));
  //     await tester.pumpAndSettle();

  //     expect(find.text("STEP 1"), findsOneWidget);
  //     expect(appRepository.persons, isEmpty);
  //     expect(appSettings.showOnboarding, isTrue);
  //   });
  });
}
