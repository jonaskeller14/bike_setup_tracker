import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_data.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';
import 'package:bike_setup_tracker/models/filtered_data.dart';
import 'package:bike_setup_tracker/pages/component_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Widget createWidgetUnderTest({
    required AppData appData,
    required AppSettings appSettings,
    Component? component,
    required ComponentPageMode mode,
    Object? initialBike,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appData),
        ChangeNotifierProxyProvider<AppData, FilteredData>(
          create: (context) => FilteredData(appData),
          update: (context, newAppData, filteredData) => filteredData!..update(newAppData),
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            switch (mode) {
              case ComponentPageMode.add:
                return ComponentPage.add(initialBike: initialBike);
              case ComponentPageMode.edit:
                return ComponentPage.edit(component: component!);
              case ComponentPageMode.duplicate:
                return ComponentPage.duplicate(component: component!);
            }
          },
        ),
      ),
    );
  }

  group('ComponentPage Initialization', () {
    testWidgets('renders in Add mode with default values', (WidgetTester tester) async {
      final appData = AppData();
      final appSettings = AppSettings();
      
      await tester.pumpWidget(createWidgetUnderTest(
        appData: appData,
        appSettings: appSettings,
        mode: ComponentPageMode.add,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Add Component'), findsOneWidget);
      expect(find.text('Component Name'), findsOneWidget);
      expect(find.text('NOT INSTALLED'), findsOneWidget);
      expect(find.text('Please select type'), findsOneWidget);
      expect(find.text('No adjustments yet'), findsOneWidget);
    });

    testWidgets('renders in Edit mode with component data', (WidgetTester tester) async {
      final appData = AppData();
      final appSettings = AppSettings();
      final bike = Bike(name: 'My Bike', person: 'Me');
      appData.addBike(bike);
      
      final component = Component(
        id: 'c1',
        name: 'My Fork',
        componentType: ComponentType.fork,
        installations: [],
        adjustments: [
          BooleanAdjustment(name: 'Lockout', notes: '', unit: '', category: AdjustmentCategory.component),
        ],
      ).copyWithNewInstallation(bike.id);

      await tester.pumpWidget(createWidgetUnderTest(
        appData: appData,
        appSettings: appSettings,
        component: component,
        mode: ComponentPageMode.edit,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Edit Component'), findsOneWidget);
      expect(find.text('My Fork'), findsOneWidget);
      expect(find.text('My Bike'), findsOneWidget);
      expect(find.text('Fork'), findsOneWidget);
      expect(find.text('Lockout'), findsOneWidget);
    });

    testWidgets('renders in Duplicate mode with component data and "Add" title', (WidgetTester tester) async {
      final appData = AppData();
      final appSettings = AppSettings();
      final component = Component(
        id: 'c1',
        name: 'My Fork',
        componentType: ComponentType.fork,
        installations: [],
        adjustments: [],
      );

      await tester.pumpWidget(createWidgetUnderTest(
        appData: appData,
        appSettings: appSettings,
        component: component,
        mode: ComponentPageMode.duplicate,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Add Component'), findsOneWidget);
      expect(find.text('My Fork'), findsOneWidget);
    });
  });

  group('ComponentPage Validation', () {
    testWidgets('shows error when name is empty', (WidgetTester tester) async {
      final appData = AppData();
      final appSettings = AppSettings();
      
      await tester.pumpWidget(createWidgetUnderTest(
        appData: appData,
        appSettings: appSettings,
        mode: ComponentPageMode.add,
      ));
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('shows error when type is not selected', (WidgetTester tester) async {
      final appData = AppData();
      final appSettings = AppSettings();
      
      await tester.pumpWidget(createWidgetUnderTest(
        appData: appData,
        appSettings: appSettings,
        mode: ComponentPageMode.add,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Component Name'), 'New Component');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('Component type cannot be empty. You can edit it later.'), findsOneWidget);
    });

    testWidgets('shows error when no adjustments are added', (WidgetTester tester) async {
      final appData = AppData();
      final appSettings = AppSettings();
      
      await tester.pumpWidget(createWidgetUnderTest(
        appData: appData,
        appSettings: appSettings,
        mode: ComponentPageMode.add,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Component Name'), 'New Component');
      
      // Select type
      final typeDropdown = find.text('Please select type');
      await tester.ensureVisible(typeDropdown);
      await tester.tap(typeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fork').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('You need to add at least one adjustment'), findsOneWidget);
    });
  });

  group('ComponentPage Dropdown Scenarios', () {
    testWidgets('displays "BIKE NOT FOUND" when initial bike is missing', (WidgetTester tester) async {
      final appData = AppData();
      final appSettings = AppSettings();
      
      // Page requested with an ID that doesn't exist in appData
      await tester.pumpWidget(createWidgetUnderTest(
        appData: appData,
        appSettings: appSettings,
        mode: ComponentPageMode.add,
        initialBike: 'non-existent-id',
      ));
      await tester.pumpAndSettle();

      expect(find.text('BIKE NOT FOUND'), findsOneWidget);
    });
  });
}
