import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/filtered_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bike_setup_tracker/main.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/app_data.dart';
import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/widgets/garage_list.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/installation.dart';
import 'package:bike_setup_tracker/services/strava_service.dart';
import 'package:bike_setup_tracker/services/storage_service.dart';
import 'package:bike_setup_tracker/services/google_drive_service.dart';

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
    appSettings.enableGarage = false;
    appSettings.enableStrava = false;
  });

  tearDown(() async {
    appData.dispose();
    appSettings.dispose();
    filteredData.dispose();
    await database.close();
  });

  Widget createWidgetUnderTest() {
    filteredData = FilteredData(database);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>.value(value: appSettings),
        ChangeNotifierProvider<AppData>.value(value: appData),
        ChangeNotifierProvider<FilteredData>.value(
          value: filteredData,
        ),
        Provider<AppDatabase>.value(value: database),
        Provider<StorageService>(create: (_) => StorageService()),
        ChangeNotifierProvider<StravaService>(
            create: (_) => StravaService(appData)),
        ChangeNotifierProvider<GoogleDriveService>(
            create: (_) => GoogleDriveService(appData, database)),
      ],
      child: const BikeSetupTrackerApp(),
    );
  }

  testWidgets('Home Page BottomNavigationBar', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 200));

    AppBar appBar = tester.widget(find.byType(AppBar).last);
    Text titleText = appBar.title as Text;
    expect(titleText.data, contains('Bikes'));

    final bikesDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Bikes'),
    );

    await tester.tap(bikesDestination.first);
    await tester.pumpAndSettle();

    appBar = tester.widget(find.byType(AppBar).last);
    titleText = appBar.title as Text;
    expect(titleText.data, contains('Bikes'));

    final componentsDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Components'),
    );

    await tester.tap(componentsDestination.first);
    await tester.pumpAndSettle();

    appBar = tester.widget(find.byType(AppBar).last);
    titleText = appBar.title as Text;

    expect(titleText.data, contains('Components'));

    final setupsDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Setups'),
    );

    await tester.tap(setupsDestination);
    await tester.pumpAndSettle();

    appBar = tester.widget(find.byType(AppBar).last);
    titleText = appBar.title as Text;

    expect(titleText.data, contains('Setup History'));
  });

  testWidgets('Add Component without Bike', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text('Components')));
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(AppBar).last, matching: find.text('Components')),
        findsOneWidget);

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(AppBar).last,
            matching: find.text('Add Component')),
        findsNothing);

    await appData
        .addBike(Bike(name: "TestBike #1", person: null, isDeleted: true));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(AppBar).last,
            matching: find.text('Add Component')),
        findsNothing);

    await appData.addBike(Bike(name: "TestBike #2", person: null));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byType(AppBar).last,
            matching: find.text('Add Component')),
        findsOneWidget);
  });

  testWidgets('Add Setup without Bike and Components', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Setups'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Setup History'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Add Setup'),
      ),
      findsNothing,
    );

    final bike1 = Bike(name: "TestBike #1", person: null, isDeleted: true);
    await appData.addBike(bike1);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Add Setup'),
      ),
      findsNothing,
    );

    await appData.addComponent(
      Component(
        name: "TestComponent #1",
        installations: [Installation.sinceBeginning(parent: bike1.id)],
        componentType: ComponentType.other,
        adjustments: [],
        isDeleted: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Add Setup'),
      ),
      findsNothing,
    );

    final bike2 = Bike(name: "TestBike #2", person: null, isDeleted: false);
    await appData.addBike(bike2);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Add Setup'),
      ),
      findsNothing,
    );

    await appData.addComponent(
      Component(
        name: "TestComponent #2",
        installations: [Installation.sinceBeginning(parent: bike2.id)],
        componentType: ComponentType.other,
        adjustments: [],
        isDeleted: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Add Setup'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('BikeList: Add/Remove/Restore Bike and not show deleted', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(
      find
          .descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Bikes'),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Bikes'),
      ),
      findsOneWidget,
    );

    // Add Bike and show Bike
    await appData
        .addBike(Bike(name: "TestBike #1", person: null, isDeleted: false));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text("TestBike #1"), findsAtLeast(1));

    // Not show deleted Bike
    final bike2 = Bike(name: "TestBike #2", person: null, isDeleted: true);
    await appData.addBike(bike2);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text("TestBike #2"), findsNothing);

    // Remove Bike
    final bike3 = Bike(name: "TestBike #3", person: null, isDeleted: false);
    await appData.addBike(bike3);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text("TestBike #3"), findsAtLeast(1));
    await appData.removeBike(bike3);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text("TestBike #3"), findsNothing);

    // Restore Bike
    await appData.restoreBike(bike2);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text("TestBike #2"), findsAtLeast(1));
  });

  testWidgets('ComponentList/Edit Adjustment with saving Component', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 200));

    final bike1 = Bike(name: "Bike #1", person: null);
    final booleanAdjustment1 = BooleanAdjustment(
      name: "BooleanAdjustment #1",
      notes: null,
      unit: null,
      category: AdjustmentCategory.component,
    );
    final component1 = Component(
      name: "Component #1",
      installations: [Installation.sinceBeginning(parent: bike1.id)],
      componentType: ComponentType.fork,
      adjustments: [booleanAdjustment1],
    );

    await appData.addBike(bike1);
    await appData.addComponent(component1);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Components'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(Card),
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("Edit"));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Edit Component'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(Card),
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("Edit"));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Edit On/Off Adjustment'),
      ),
      findsOneWidget,
    );
    Finder nameField = find.byType(TextFormField).first;
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'BooleanAdjustment #1 edit #1');

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Components'),
      ),
      findsOneWidget,
    );
    expect(find.text('BooleanAdjustment #1'), findsNothing);
    expect(find.text('BooleanAdjustment #1 edit #1'), findsOneWidget);
  });

  testWidgets('ComponentList/Edit Adjustment without saving Component', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 200));

    final bike1 = Bike(name: "Bike #1", person: null);
    final booleanAdjustment1 = BooleanAdjustment(
      name: "BooleanAdjustment #1",
      notes: null,
      unit: null,
      category: AdjustmentCategory.component,
    );
    final component1 = Component(
      name: "Component #1",
      installations: [Installation.sinceBeginning(parent: bike1.id)],
      componentType: ComponentType.fork,
      adjustments: [booleanAdjustment1],
    );

    await appData.addBike(bike1);
    await appData.addComponent(component1);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Components'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(Card),
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("Edit"));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Edit Component'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(
        of: find.byType(Card),
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("Edit"));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Edit On/Off Adjustment'),
      ),
      findsOneWidget,
    );
    Finder nameField = find.byType(TextFormField).first;
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'BooleanAdjustment #1 edit #1');

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.text("Discard Changes"),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar).last,
        matching: find.text('Components'),
      ),
      findsOneWidget,
    );
    expect(find.text('BooleanAdjustment #1'), findsOneWidget);
    expect(find.text('BooleanAdjustment #1 edit #1'), findsNothing);
  });

  testWidgets('Home Page with enableGarage=True', (WidgetTester tester) async {
    appSettings.enableGarage = true;

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Title is "Bikes"
    AppBar appBar = tester.widget(find.byType(AppBar).last);
    Text titleText = appBar.title as Text;
    expect(titleText.data, contains('Bikes'));

    // Verify NavigationBar has "Bikes" and "Setups" but NOT "Components"
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Bikes'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Setups'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Components'),
      ),
      findsNothing,
    );

    // Verify GarageList is shown (body of the first page)
    expect(find.byType(GarageList), findsOneWidget);
  });
}
