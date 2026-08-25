import 'package:bike_setup_tracker/database/app_database.dart';
import 'package:bike_setup_tracker/database/mappers.dart';
import 'package:bike_setup_tracker/models/app_hint.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/app_hint_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/widgets/items/strava_list_tile.dart';
import 'package:bike_setup_tracker/widgets/lists/setup_list.dart';
import 'package:bike_setup_tracker/widgets/timeline_day_header.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guards the SetupList build-cost fix (2026-07-26): with day headers enabled
/// the timeline must stay lazy — one `SliverList` of `StickySection` day
/// children — instead of inflating one pinned sliver group per loaded day,
/// which made deep Strava windows (1000+ activities ≈ 500 days) take seconds
/// to build on every tab switch and data change.
///
/// The regression guard is the *widget count*: with ~500 loaded days, only
/// near-viewport day headers/tiles may exist. Wall-clock timings are printed
/// for information only (debug-mode, machine-dependent) — never asserted.
class _EntitledSubscriptionService extends SubscriptionService {
  @override
  bool get hasStravaEntitlement => true;
}

void main() {
  testWidgets('SetupList with a deep Strava window builds lazily', (
    tester,
  ) async {
    // SubscriptionService's field initializer touches InAppPurchase.instance,
    // whose billing connection fails on the test platform channel with an
    // async channel-error. That is unrelated to what this test verifies. The
    // reporter must be restored within the test body (the binding verifies
    // it), hence the try/finally around the whole test.
    final originalReporter = reportTestException;
    reportTestException = (FlutterErrorDetails details, String testDescription) {
      final exception = details.exception;
      if (exception is PlatformException && exception.code == 'channel-error') {
        debugPrint('Ignored billing channel-error (no store in test env).');
        return;
      }
      originalReporter(details, testDescription);
    };
    try {
      await _runDeepWindowLazinessTest(tester);
    } finally {
      reportTestException = originalReporter;
    }
  });
}

Future<void> _runDeepWindowLazinessTest(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final database = AppDatabase.memory();
  addTearDown(database.close);

  final bike = Bike(name: 'Bench Bike', person: null);
  await tester.runAsync(() async {
    await database.bikesDao.insertBike(bike.toCompanion());

    final base = DateTime.utc(2024, 1, 1, 8);
    // 1000 activities, 2 per day over 500 days. One batch so the drift
    // watch streams re-query once instead of per row.
    await database.batch((b) {
      for (int i = 0; i < 1000; i++) {
        final start = base.add(Duration(hours: i * 12));
        b.insert(
          database.stravaDao.stravaActivities,
          StravaActivitiesCompanion.insert(
            id: drift.Value(i + 1),
            name: 'Activity ${i + 1}',
            athlete: 1,
            sportType: SportType.Ride,
            startDate: start,
            startDateLocal: start,
            movingTime: 30 * 60,
            elapsedTime: 35 * 60,
            lastModified: start,
            gearId: const drift.Value(null),
            startLat: const drift.Value(44.0),
            startLon: const drift.Value(8.0),
            distance: const drift.Value(10000),
            totalElevationGain: const drift.Value(300),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }
    });
    // 200 setups over the same period.
    for (int i = 0; i < 200; i++) {
      final dt = base.add(Duration(hours: i * 60 + 2));
      final setup = Setup(
        name: 'Setup ${i + 1}',
        datetime: dt,
        datetimeLocal: dt,
        tags: {},
        bike: bike.id,
        person: null,
        bikeAdjustmentValues: {},
        personAdjustmentValues: {},
      ).copyWith(lastModified: DateTime.now().toUtc());
      await database.setupsDao.insertSetupWithValues(
        setup: setup.toCompanion(),
        bikeValues: setup.bikeAdjustmentValues,
        personValues: setup.personAdjustmentValues,
      );
    }
  });

  final appSettings = AppSettings();
  appSettings.showOnboarding = false;
  appSettings.enableTimelineDayHeaders = true;

  final appRepository = AppRepository(database);
  addTearDown(appRepository.dispose);
  // Load the full history at once, simulating a session that scrolled deep.
  appRepository.debugSetStravaLimit(1100);
  await tester.runAsync(() async {
    await appRepository.initialStravaLoad();
    // Let the drift streams and the _dataChanged microtask settle.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  final appHintService = AppHintService(
    appRepository: appRepository,
    appSettings: appSettings,
  );
  await appHintService.load();
  await appHintService.dismiss(AppHint.gettingStartedV1);
  addTearDown(appHintService.dispose);

  final show = ValueNotifier<bool>(false);
  addTearDown(show.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>.value(value: appSettings),
        ChangeNotifierProvider<AppRepository>.value(value: appRepository),
        ChangeNotifierProvider<AppHintService>.value(value: appHintService),
        ChangeNotifierProvider<SubscriptionService>(
          create: (_) => _EntitledSubscriptionService(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: ValueListenableBuilder<bool>(
              valueListenable: show,
              builder: (_, visible, _) => visible ? const SetupList() : const SizedBox.expand(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));

  // Cold inflate — what a tab switch without keep-alive pays.
  final stopwatch = Stopwatch()..start();
  show.value = true;
  await tester.pump();
  stopwatch.stop();
  await tester.pump(const Duration(seconds: 1));
  debugPrint(
    'SetupList cold inflate, 1000-activity window, day headers on: '
    '${stopwatch.elapsedMilliseconds}ms (informational)',
  );

  // ~500 loaded days, but only the handful of day sections near the
  // viewport may be built. The eager sliver-per-day structure this test
  // guards against would inflate all ~500 headers and fail here.
  final builtHeaders = find.byType(TimelineDayHeader).evaluate().length;
  final builtStravaTiles = find.byType(StravaListTile).evaluate().length;
  expect(appRepository.filteredStravaActivities.length, 1000);
  expect(builtHeaders, greaterThan(0));
  expect(
    builtHeaders,
    lessThan(30),
    reason:
        'Day headers must be built lazily (one SliverList of '
        'StickySection children), not one eager sliver group per day.',
  );
  expect(
    builtStravaTiles,
    lessThan(40),
    reason: 'Timeline rows must only be built near the viewport.',
  );
}
