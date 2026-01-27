import 'package:bike_setup_tracker/models/filtered_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bike_setup_tracker/main.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/app_data.dart';


void main() {
  testWidgets('OnBoarding Test', (WidgetTester tester) async {
    final appSettings = AppSettings();
    final appData = AppData();
    
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appData),
          ChangeNotifierProxyProvider<AppData, FilteredData>(
            create: (context) => FilteredData(appData),
            update: (context, newAppData, filteredData) => filteredData!..update(newAppData),
          ),
        ],
        child: const BikeSetupTrackerApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text("Ready to Dial It In?"), findsOneWidget);
    expect(find.text("Skip"), findsOneWidget);

    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();
    
    expect(find.text("STEP 1"), findsOneWidget);
    expect(find.text("Skip"), findsOneWidget);

    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();
    
    expect(find.text("STEP 2"), findsOneWidget);
    expect(find.text("Skip"), findsOneWidget);

    await tester.tap(find.text("Next"));
    await tester.pumpAndSettle();

    expect(find.text("STEP 3"), findsOneWidget);
    expect(find.text("Skip"), findsOneWidget);

    await tester.tap(find.text("Finish"));
    await tester.pumpAndSettle();
  });

  testWidgets('Not Show OnBoarding', (WidgetTester tester) async {
    final appSettings = AppSettings();
    appSettings.setShowOnboarding(false);

    final appData = AppData();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appData),
          ChangeNotifierProxyProvider<AppData, FilteredData>(
            create: (context) => FilteredData(appData),
            update: (context, newAppData, filteredData) => filteredData!..update(newAppData),
          ),
        ],
        child: const BikeSetupTrackerApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text("Ready to Dial It In?"), findsNothing);
  });
}
