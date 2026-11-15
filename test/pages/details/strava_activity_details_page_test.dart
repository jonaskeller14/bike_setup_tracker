import 'dart:async';

import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/pages/details/strava_activity_details_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/sheets/strava_activity.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../goldens/support/localized_test_app.dart';

void main() {
  late AppDatabase database;
  late AppRepository appRepository;
  late AppSettings appSettings;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // The page holds a Drift stream; closing it asynchronously would leave a
    // timer pending in the fake-async zone when the page unmounts.
    database = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    appRepository = AppRepository(database);
    appSettings = AppSettings();
  });

  tearDown(() async {
    await appRepository.disposeAndAwaitCancellation();
    appSettings.dispose();
    await database.close();
  });

  StravaActivity activity({
    String name = 'Ride',
    double? startLat = 44.16,
    double? startLon = 8.34,
    double? distance,
    Duration? movingTime,
  }) => StravaActivity(
    id: 1,
    name: name,
    athlete: 1,
    sportType: SportType.Ride,
    startDate: DateTime(2025, 6, 1).toUtc(),
    startDateLocal: DateTime(2025, 6, 1),
    gearId: null,
    startLat: startLat,
    startLon: startLon,
    distance: distance,
    totalElevationGain: null,
    movingTime: movingTime ?? Duration.zero,
    elapsedTime: Duration.zero,
  );

  Widget wrap(Widget home, {Locale locale = const Locale('en')}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appSettings),
        ChangeNotifierProvider.value(value: appRepository),
      ],
      child: localizedTestApp(theme: materialAppTheme, locale: locale, home: home),
    );
  }

  PopupMenuItem<Object?> menuItem(WidgetTester tester, String label) => tester.widget<PopupMenuItem<Object?>>(
    find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is PopupMenuItem)),
  );

  /// The page's Drift query completes in real async but delivers in the fake
  /// zone, so both have to take turns until its row arrives.
  Future<void> settleQuery(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
  }

  /// Awaiting a write inside runAsync deadlocks once the page listens: the
  /// write waits for the page's re-query, which only runs while the fake zone
  /// is pumped.
  Future<void> writeWhilePageListens(WidgetTester tester, Future<void> Function() write) async {
    var done = false;
    await tester.runAsync(() async => unawaited(write().whenComplete(() => done = true)));
    for (var i = 0; !done && i < 100; i++) {
      await settleQuery(tester);
    }
    expect(done, isTrue);
    await settleQuery(tester);
  }

  Future<void> pumpDetailsPage(WidgetTester tester, StravaActivity stravaActivity, {Locale locale = const Locale('en')}) async {
    await tester.runAsync(() => appRepository.setStravaActivities([stravaActivity]));
    await tester.pumpWidget(wrap(StravaActivityDetailsPage(activityId: stravaActivity.id), locale: locale));
    await settleQuery(tester);
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byType(StravaActivityActionsMenu));
    await tester.pumpAndSettle();
  }

  group('Details page', () {
    testWidgets('shows distance and speed with a decimal comma in German', (tester) async {
      await pumpDetailsPage(
        tester,
        activity(distance: 12345.6, movingTime: const Duration(hours: 1)),
        locale: const Locale('de'),
      );

      expect(find.textContaining('12,35 km'), findsWidgets);
      expect(find.textContaining('12,3 km/h'), findsWidgets);
      expect(find.textContaining('12.35'), findsNothing);
    });

    testWidgets('offers all actions from the app bar menu', (tester) async {
      await pumpDetailsPage(tester, activity());

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
      await pumpDetailsPage(tester, activity(startLat: null, startLon: null));
      await openMenu(tester);

      expect(menuItem(tester, 'View on map').enabled, isFalse);
      expect(menuItem(tester, 'Open in maps app').enabled, isFalse);
      expect(menuItem(tester, 'View on Strava').enabled, isTrue);
      expect(find.text('Start location not available'), findsNWidgets(2));
    });

    testWidgets('shows a Strava update while the page is open', (tester) async {
      await pumpDetailsPage(tester, activity(name: 'Morning loop'));
      expect(find.text('Morning loop'), findsOneWidget);

      await writeWhilePageListens(tester, () => appRepository.setStravaActivities([activity(name: 'Renamed ride')]));

      expect(find.text('Renamed ride'), findsOneWidget);
      expect(find.text('Morning loop'), findsNothing);
    });

    testWidgets('shows not found for an unknown activity', (tester) async {
      await tester.pumpWidget(wrap(const StravaActivityDetailsPage(activityId: 42)));
      await settleQuery(tester);

      expect(find.text('Activity not found'), findsOneWidget);
      expect(find.byType(StravaActivityActionsMenu), findsNothing);
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
