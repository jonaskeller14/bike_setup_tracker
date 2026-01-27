import 'package:bike_setup_tracker/models/filtered_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/app_data.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/pages/bike_page.dart';

void main() {
  testWidgets('BikePage/Add input validation', (WidgetTester tester) async {
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
        child: const MaterialApp(home: BikePage()),
      ),
    );

    Finder bikeNameField = find.byType(TextFormField).first;
    expect(bikeNameField, findsOneWidget);
    await tester.enterText(bikeNameField, '');

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.byType(BikePage), findsAny);

    bikeNameField = find.byType(TextFormField).first;
    expect(bikeNameField, findsOneWidget);
    await tester.enterText(bikeNameField, '    ');

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.byType(BikePage), findsAny);

    bikeNameField = find.byType(TextFormField).first;
    expect(bikeNameField, findsOneWidget);
    await tester.enterText(bikeNameField, 'TestBike #1');

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.byType(BikePage), findsNothing);
  });

    testWidgets('BikePage/Edit input validation', (WidgetTester tester) async {
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
        child: MaterialApp(home: BikePage(bike: Bike(name: "TestBike #1", person: null))),
      ),
    );

    Finder bikeNameField = find.byType(TextFormField).first;
    expect(bikeNameField, findsOneWidget);
    await tester.enterText(bikeNameField, '');

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.byType(BikePage), findsAny);

    bikeNameField = find.byType(TextFormField).first;
    expect(bikeNameField, findsOneWidget);
    await tester.enterText(bikeNameField, '    ');

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.byType(BikePage), findsAny);

    bikeNameField = find.byType(TextFormField).first;
    expect(bikeNameField, findsOneWidget);
    await tester.enterText(bikeNameField, 'TestBike #1 new');

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(find.byType(BikePage), findsNothing);
  });
}
