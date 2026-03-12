import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bike_setup_tracker/pages/onboarding_page.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appRepository = AppRepository(database);
    appSettings = AppSettings();
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
      ],
      // Use a simplified app structure for onboarding tests to avoid 
      // complex service dependencies (Firebase, Strava, etc.) in HomePage.
      child: Consumer<AppSettings>(
        builder: (context, settings, child) {
          return MaterialApp(
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

    // Slide 4 -> Finish
    await tester.tap(find.text("Finish"));
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
}
