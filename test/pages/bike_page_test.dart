import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/pages/bike_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
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
    appSettings.showOnboarding = false;
  });

  tearDown(() async {
    appRepository.dispose();
    appSettings.dispose();
    await database.close();
  });

  Widget createWidgetUnderTest(Widget home) {
    appRepository.dispose();
    appRepository = AppRepository(database);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appRepository),
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
