import 'package:bike_setup_tracker/models/filtered_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/app_data.dart';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/pages/bike_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase database;
  late AppData appData;
  late AppSettings appSettings;
  late FilteredData filteredData;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.memory();
    appData = AppData(database);
    appSettings = AppSettings();
    appSettings.showOnboarding = false;
  });

  tearDown(() async {
    appData.dispose();
    appSettings.dispose();
    filteredData.dispose();
    await database.close();
  });

  Widget createWidgetUnderTest(Widget home) {
    filteredData = FilteredData(appData.database);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appData),
        ChangeNotifierProvider<FilteredData>.value(
          value: filteredData,
        ),
      ],
      child: MaterialApp(home: home),
    );
  }

  testWidgets('BikePage/Add input validation', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(BikePage.add()));

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
    await tester.pumpWidget(createWidgetUnderTest(BikePage.edit(bike: Bike(name: "TestBike #1", person: null))));

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
