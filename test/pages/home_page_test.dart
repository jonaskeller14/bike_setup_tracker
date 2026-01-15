import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bike_setup_tracker/main.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/app_data.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/component.dart';


void main() {
  testWidgets('Home Page BottomNavigationBar', (WidgetTester tester) async {
    final appSettings = AppSettings();
    appSettings.setShowOnboarding(false);

    final appData = AppData();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appData),
        ],
        child: const BikeSetupTrackerApp(),
      ),
    );

    AppBar appBar = tester.widget(find.byType(AppBar).last);
    Text titleText = appBar.title as Text;
    expect(titleText.data, contains('Bikes'));

    final bikesDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Bikes'),
    );

    await tester.tap(bikesDestination);
    await tester.pumpAndSettle();

    expect(titleText.data, contains('Bikes'));

    final componentsDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Components'),
    );

    await tester.tap(componentsDestination);
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
    final appSettings = AppSettings();
    appSettings.setShowOnboarding(false);

    final appData = AppData();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appData),
        ],
        child: const BikeSetupTrackerApp(),
      ),
    );

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Components')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(AppBar).last, matching: find.text('Components')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(AppBar).last, matching: find.text('Add Component')), findsNothing);

    appData.addBike(Bike(name: "TestBike #1", person: null, isDeleted: true));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(AppBar).last, matching: find.text('Add Component')), findsNothing);

    appData.addBike(Bike(name: "TestBike #2", person: null));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(AppBar).last.last, matching: find.text('Add Component')), findsOneWidget);
  });

  testWidgets('Add Setup without Bike and Components', (WidgetTester tester) async {
    final appSettings = AppSettings();
    appSettings.setShowOnboarding(false);

    final appData = AppData();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appData),
        ],
        child: const BikeSetupTrackerApp(),
      ),
    );

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Setups')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(AppBar).last, matching: find.text('Setup History')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(AppBar).last, matching: find.text('Add Setup')), findsNothing);

    final bike1 = Bike(name: "TestBike #1", person: null, isDeleted: true);
    appData.addBike(bike1);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(AppBar).last, matching: find.text('Add Setup')), findsNothing);

    appData.addComponent(Component(name: "TestComponent #1", bike: bike1.id, componentType: ComponentType.other, adjustments: [], isDeleted: true));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(AppBar).last, matching: find.text('Add Setup')), findsNothing);

    final bike2 = Bike(name: "TestBike #2", person: null, isDeleted: false);
    appData.addBike(bike2);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(AppBar).last, matching: find.text('Add Setup')), findsNothing);

    appData.addComponent(Component(name: "TestComponent #2", bike: bike2.id, componentType: ComponentType.other, adjustments: [], isDeleted: false));
    await tester.tap(find.widgetWithIcon(FloatingActionButton, Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.descendant(of: find.byType(AppBar).last, matching: find.text('Add Setup')), findsOneWidget);
  });

  testWidgets('BikeList: Add/Remove/Restore Bike and not show deleted', (WidgetTester tester) async {
    final appSettings = AppSettings();
    appSettings.setShowOnboarding(false);

    final appData = AppData();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appSettings),
          ChangeNotifierProvider.value(value: appData),
        ],
        child: const BikeSetupTrackerApp(),
      ),
    );

    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Bikes')));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(AppBar).last, matching: find.text('Bikes')), findsOneWidget);
    
    // Add Bike and show Bike
    appData.addBike(Bike(name: "TestBike #1", person: null, isDeleted: false));
    await tester.pumpAndSettle();
    expect(find.text("TestBike #1"), findsOneWidget);

    // Not show deleted Bike
    final bike2 = Bike(name: "TestBike #2", person: null, isDeleted: true);
    appData.addBike(bike2);
    await tester.pumpAndSettle();
    expect(find.text("TestBike #2"), findsNothing);

    // Remove Bike
    final bike3 = Bike(name: "TestBike #3", person: null, isDeleted: false);
    appData.addBike(bike3);
    await tester.pumpAndSettle();
    expect(find.text("TestBike #3"), findsOneWidget);
    appData.removeBike(bike3);
    await tester.pumpAndSettle();
    expect(find.text("TestBike #3"), findsNothing);

    // Restore Bike
    appData.restoreBike(bike2);
    await tester.pumpAndSettle();
    expect(find.text("TestBike #2"), findsOneWidget);
  });
}
