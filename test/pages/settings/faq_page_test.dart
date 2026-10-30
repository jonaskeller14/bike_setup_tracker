import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/pages/settings/faq_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../goldens/support/localized_test_app.dart';

void main() {
  late AppSettings appSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appSettings = AppSettings();
  });

  tearDown(() => appSettings.dispose());

  /// Tall enough that the lazy slivers build every section.
  Future<void> pumpPage(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    tester.view.physicalSize = const Size(800, 30000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>.value(
        value: appSettings,
        child: localizedTestApp(locale: locale, home: const FAQPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists the always-on sections in English', (tester) async {
    await pumpPage(tester);

    expect(find.text('Frequently asked Questions'), findsOneWidget);
    expect(find.text('GENERAL'), findsOneWidget);
    expect(find.text('BIKES'), findsOneWidget);
    expect(find.text('SETUP'), findsOneWidget);
    expect(find.text('STRAVA SYNC'), findsOneWidget);
    expect(find.text('RIDER'), findsNothing);
    expect(find.text('TASKS'), findsNothing);
    expect(find.text('What is this app about?'), findsOneWidget);
  });

  testWidgets('adds the Rider and Tasks sections once their features are on', (tester) async {
    appSettings
      ..enablePerson = true
      ..enableTask = true;

    await pumpPage(tester);

    expect(find.text('RIDER'), findsOneWidget);
    expect(find.text('TASKS'), findsOneWidget);
  });

  testWidgets('keeps the adjustment questions inside the Bikes section', (tester) async {
    await pumpPage(tester);

    final reorderComponents = tester.getTopLeft(find.text('How do I reorder my components?')).dy;
    final adjustment = tester.getTopLeft(find.text('What is an "Adjustment"?')).dy;
    final reorderBikes = tester.getTopLeft(find.text('How do I reorder my bikes?')).dy;
    final setup = tester.getTopLeft(find.text('What is a "Setup"?')).dy;

    expect(adjustment, greaterThan(reorderComponents));
    expect(reorderBikes, greaterThan(adjustment));
    expect(setup, greaterThan(reorderBikes));
  });

  testWidgets('is translated into German', (tester) async {
    appSettings.enableTask = true;

    await pumpPage(tester, locale: const Locale('de'));

    expect(find.text('Häufig gestellte Fragen'), findsOneWidget);
    expect(find.text('ALLGEMEIN'), findsOneWidget);
    expect(find.text('AUFGABEN'), findsOneWidget);
    expect(find.text('Worum geht es in dieser App?'), findsOneWidget);
    expect(find.text('What is this app about?'), findsNothing);
  });
}
