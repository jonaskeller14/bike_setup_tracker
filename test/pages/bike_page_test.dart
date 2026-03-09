import 'package:bike_setup_tracker/models/filtered_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/app_data.dart';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/pages/bike_page.dart';

void main() {
  testWidgets('BikePage/Add input validation', (WidgetTester tester) async {
    final appSettings = AppSettings();
    appSettings.showOnboarding = false;

    final appData = AppData(AppDatabase.memory());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appData),
          ChangeNotifierProvider<FilteredData>(
            create: (context) => FilteredData(appData.database),
          ),
        ],
        child: MaterialApp(home: BikePage.add()),
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
    appSettings.showOnboarding = false;

    final appData = AppData(AppDatabase.memory());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appData),
          ChangeNotifierProvider<FilteredData>(
            create: (context) => FilteredData(appData.database),
          ),
        ],
        child: MaterialApp(home: BikePage.edit(bike: Bike(name: "TestBike #1", person: null))),
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
