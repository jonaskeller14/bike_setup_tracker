import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/pages/settings/preferences_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../goldens/support/localized_test_app.dart';

void main() {
  late AppSettings appSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appSettings = AppSettings();
  });

  tearDown(() {
    Intl.defaultLocale = null;
    appSettings.dispose();
  });

  Future<void> pumpPage(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Intl.defaultLocale = locale.languageCode;
    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>.value(
        value: appSettings,
        child: localizedTestApp(locale: locale, home: const PreferencesPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the date and time samples the way the pickers will format them', (tester) async {
    appSettings
      ..dateFormat = 'dd MMM yyyy'
      ..timeFormat = 'h:mm a';

    await pumpPage(tester);

    expect(find.text('dd MMM yyyy (09 Dec 2025)'), findsOneWidget);
    expect(find.text('h:mm a (8:07 PM)'), findsOneWidget);
  });

  testWidgets('shows the month sample in the app language', (tester) async {
    appSettings.dateFormat = 'dd MMM yyyy';

    await pumpPage(tester, locale: const Locale('de'));

    expect(find.textContaining('dd MMM yyyy (09 Dez'), findsOneWidget);
  });

  testWidgets('translates the titles and the chosen unit labels', (tester) async {
    await pumpPage(tester, locale: const Locale('de'));

    expect(find.text('Voreinstellungen'), findsOneWidget);
    expect(find.text('DARSTELLUNG'), findsOneWidget);
    expect(find.text('STANDARDEINHEITEN'), findsOneWidget);
    expect(find.text('Kilometer (km)'), findsOneWidget);
    expect(find.text('Celsius (°C)'), findsOneWidget);
    expect(find.text('An'), findsOneWidget);
  });

  testWidgets('hides the language picker until the language flag is on, then names each language itself', (
    tester,
  ) async {
    await pumpPage(tester);
    expect(find.text('Language'), findsNothing);

    appSettings.enableLanguageSelection = true;
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);
  });
}
