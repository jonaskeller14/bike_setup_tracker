import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/pages/settings/about_page.dart';
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

  Future<void> pumpPage(WidgetTester tester, Locale locale) async {
    Intl.defaultLocale = locale.languageCode;
    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettings>.value(
        value: appSettings,
        child: localizedTestApp(locale: locale, home: const AboutPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The subtitle under the release date [label].
  String releaseDateText(WidgetTester tester, String label) {
    final tile = find.ancestor(of: find.text(label), matching: find.byType(ListTile));
    return (tester.widget<ListTile>(tile).subtitle! as Text).data!;
  }

  testWidgets('shows the release date with an English month name', (tester) async {
    await pumpPage(tester, const Locale('en'));

    expect(find.text('About & Legal'), findsOneWidget);
    expect(
      releaseDateText(tester, 'Release Date'),
      matches(
        RegExp(r'^(January|February|March|April|May|June|July|August|September|October|November|December) \d{4}$'),
      ),
    );
  });

  testWidgets('shows the release date with a German month name', (tester) async {
    await pumpPage(tester, const Locale('de'));

    expect(find.text('Über die App & Rechtliches'), findsOneWidget);
    expect(
      releaseDateText(tester, 'Veröffentlichungsdatum'),
      matches(RegExp(r'^(Januar|Februar|März|April|Mai|Juni|Juli|August|September|Oktober|November|Dezember) \d{4}$')),
    );
  });
}
