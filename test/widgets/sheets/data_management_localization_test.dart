import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/service_error.dart';
import 'package:bike_setup_tracker/models/strava/strava_gear.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/lists/strava_gear_link_list.dart';
import 'package:bike_setup_tracker/widgets/sheets/export.dart';
import 'package:bike_setup_tracker/widgets/sheets/import_merge_overwrite.dart';
import 'package:bike_setup_tracker/widgets/sheets/share_format.dart';
import 'package:bike_setup_tracker/widgets/sheets/strava_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../goldens/support/localized_test_app.dart';

void main() {
  const german = Locale('de');

  Widget app(Widget child, {Locale locale = const Locale('en')}) {
    return localizedTestApp(
      theme: materialAppTheme,
      locale: locale,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the import method step reads in German', (tester) async {
    await tester.pumpWidget(
      app(
        SelectImportMethodSheetContent(onOverwrite: () {}, onMerge: () {}, onReplace: () {}, onBack: () {}),
        locale: german,
      ),
    );

    expect(find.text('Daten importieren'), findsOneWidget);
    expect(find.text('Daten überschreiben'), findsOneWidget);
    expect(find.text('Daten zusammenführen'), findsOneWidget);
    expect(find.text('Daten ersetzen'), findsOneWidget);
    expect(find.text('Overwrite data'), findsNothing);
  });

  testWidgets('the share format step reads in German', (tester) async {
    await tester.pumpWidget(
      app(SelectShareFormatSheetContent(onJson: () {}, onText: () {}, onCsv: () {}, onXlsx: () {}), locale: german),
    );

    expect(find.text('Format zum Teilen'), findsOneWidget);
    expect(find.text('JSON-Datei'), findsOneWidget);
    expect(find.text('Excel-Tabelle'), findsOneWidget);
    expect(find.text('Reiner Text'), findsOneWidget);
  });

  testWidgets('the export destination step reads in German and keeps the English text in en', (tester) async {
    final settings = AppSettings();
    Widget destinations(Locale locale) => ChangeNotifierProvider<AppSettings>.value(
      value: settings,
      child: app(
        SelectExportDestinationSheetContent(onFile: () {}, onBackup: () {}, onGoogleDriveBackup: () {}, onAttachmentBundle: () {}),
        locale: locale,
      ),
    );

    await tester.pumpWidget(destinations(const Locale('en')));
    expect(find.text('Save Backup'), findsOneWidget);

    await tester.pumpWidget(destinations(german));
    await tester.pumpAndSettle();
    expect(find.text('Daten exportieren'), findsOneWidget);
    expect(find.text('Backup speichern'), findsOneWidget);
    expect(find.text('Datei speichern'), findsOneWidget);
  });

  testWidgets('the Strava gear list reads in German', (tester) async {
    final gears = [for (var i = 1; i <= 5; i++) StravaGear(id: 'g$i', name: 'Gear $i')];
    final bikes = [Bike(name: 'Bike 1', person: null, stravaGear: 'g1')];

    await tester.pumpWidget(app(StravaGearLinkList(gears: gears, bikes: bikes), locale: german));

    expect(find.text('Strava-Ausrüstung:'), findsOneWidget);
    expect(find.text('1 von 5 verknüpft'), findsOneWidget);
    expect(find.text('Alle anzeigen (5)'), findsOneWidget);
    expect(find.text('Mit keinem Bike verknüpft'), findsWidgets);
  });

  group('StravaErrorTile', () {
    testWidgets('shows the translated sentence and a wifi icon when offline', (tester) async {
      await tester.pumpWidget(
        app(const StravaErrorTile(failure: StravaFailure(StravaErrorKind.noInternet)), locale: german),
      );

      expect(find.text('Keine Internetverbindung. Bitte prüfe deine Verbindung und versuche es erneut.'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('shows the server text as it came and an error icon', (tester) async {
      await tester.pumpWidget(
        app(const StravaErrorTile(failure: StravaFailure(StravaErrorKind.serverMessage, 'Rate limit hit')), locale: german),
      );

      expect(find.text('Rate limit hit'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
