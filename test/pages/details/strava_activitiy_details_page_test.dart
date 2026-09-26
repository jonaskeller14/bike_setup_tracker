import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/pages/details/strava_activitiy_details_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/sheets/strava_activity.dart';
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
  });

  tearDown(() async {
    await appRepository.disposeAndAwaitCancellation();
    appSettings.dispose();
    await database.close();
  });

  StravaActivity activity({double? startLat = 44.16, double? startLon = 8.34}) => StravaActivity(
    id: 1,
    name: 'Ride',
    athlete: 1,
    sportType: SportType.Ride,
    startDate: DateTime(2025, 6, 1).toUtc(),
    startDateLocal: DateTime(2025, 6, 1),
    gearId: null,
    startLat: startLat,
    startLon: startLon,
    distance: null,
    totalElevationGain: null,
    movingTime: Duration.zero,
    elapsedTime: Duration.zero,
  );

  Widget wrap(Widget home) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appRepository),
      ],
      child: MaterialApp(theme: materialAppTheme, home: home),
    );
  }

  PopupMenuItem<Object?> menuItem(WidgetTester tester, String label) => tester.widget<PopupMenuItem<Object?>>(
    find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is PopupMenuItem)),
  );

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byType(StravaActivityActionsMenu));
    await tester.pumpAndSettle();
  }

  group('Details page', () {
    testWidgets('offers all actions from the app bar menu', (tester) async {
      await tester.pumpWidget(wrap(StravaActivityDetailsPage(stravaActivity: activity())));
      await tester.pump();

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.byType(StravaActivityActionsMenu)),
        findsOneWidget,
      );
      await openMenu(tester);

      expect(menuItem(tester, 'View on map').enabled, isTrue);
      expect(menuItem(tester, 'Open in maps app').enabled, isTrue);
      expect(menuItem(tester, 'View on Strava').enabled, isTrue);
      expect(find.text('Start location not available'), findsNothing);
    });

    testWidgets('disables the map actions without a start location', (tester) async {
      await tester.pumpWidget(
        wrap(StravaActivityDetailsPage(stravaActivity: activity(startLat: null, startLon: null))),
      );
      await tester.pump();
      await openMenu(tester);

      expect(menuItem(tester, 'View on map').enabled, isFalse);
      expect(menuItem(tester, 'Open in maps app').enabled, isFalse);
      expect(menuItem(tester, 'View on Strava').enabled, isTrue);
      expect(find.text('Start location not available'), findsNWidgets(2));
    });
  });

  group('Sheet', () {
    Future<void> showSheet(WidgetTester tester, {required bool showViewOnMap}) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showStravaActivitySheet(
                  context: context,
                  stravaActivity: activity(),
                  showViewOnMap: showViewOnMap,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows the menu next to the close button', (tester) async {
      await showSheet(tester, showViewOnMap: true);

      expect(find.byType(StravaActivityActionsMenu), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      await openMenu(tester);
      expect(find.text('View on map'), findsOneWidget);
      expect(find.text('Open in maps app'), findsOneWidget);
      expect(find.text('View on Strava'), findsOneWidget);
    });

    testWidgets('hides the in-app map action when opened from the map', (tester) async {
      await showSheet(tester, showViewOnMap: false);
      await openMenu(tester);

      expect(find.text('View on map'), findsNothing);
      expect(find.text('Open in maps app'), findsOneWidget);
      expect(find.text('View on Strava'), findsOneWidget);
    });
  });
}
