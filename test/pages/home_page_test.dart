import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bike_setup_tracker/main.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';


void main() {
  testWidgets('Home Page BottomNavigationBar', (WidgetTester tester) async {
    final appSettings = AppSettings();
    appSettings.setShowOnboarding(false);
    
    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>.value(
        value: appSettings,
        child: const BikeSetupTrackerApp(),
      ),
    );

    AppBar appBar = tester.widget(find.byType(AppBar));
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

    appBar = tester.widget(find.byType(AppBar));
    titleText = appBar.title as Text;

    expect(titleText.data, contains('Components'));

    final setupsDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Setups'),
    );

    await tester.tap(setupsDestination);
    await tester.pumpAndSettle();

    appBar = tester.widget(find.byType(AppBar));
    titleText = appBar.title as Text;

    expect(titleText.data, contains('Setup History'));
  });
}
