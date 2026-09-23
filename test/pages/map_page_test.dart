import 'dart:async';

import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/context/context_position.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/pages/map_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/location_provider.dart';
import 'package:bike_setup_tracker/services/location_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MockAppRepository repository;
  late AppSettings settings;
  late MockSubscriptionService subscriptionService;
  late List<VoidCallback> repositoryListeners;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = MockAppRepository();
    when(() => repository.bikes).thenReturn(<String, Bike>{});
    when(() => repository.selectedBike).thenReturn(null);
    when(() => repository.selectedSetupTags).thenReturn(<String>{});
    when(() => repository.selectedTaskRuleTags).thenReturn(<String>{});
    when(() => repository.selectedTaskPriorities).thenReturn(TaskPriority.values.toSet());
    when(() => repository.filteredSetups).thenReturn({});
    when(() => repository.filteredRatingEntries).thenReturn({});
    when(() => repository.getFilteredStravaActivitiesWithPosition()).thenAnswer((_) async => []);
    when(() => repository.hasStravaActivitiesWithPosition()).thenAnswer((_) async => false);
    when(() => repository.hasSetupsWithPosition).thenReturn(false);
    when(() => repository.hasRatingEntriesWithPosition).thenReturn(false);
    repositoryListeners = [];
    when(() => repository.addListener(any())).thenAnswer(
      (invocation) => repositoryListeners.add(invocation.positionalArguments.first as VoidCallback),
    );
    when(() => repository.removeListener(any())).thenAnswer(
      (invocation) => repositoryListeners.remove(invocation.positionalArguments.first as VoidCallback),
    );
    settings = AppSettings();
    subscriptionService = MockSubscriptionService();
    when(() => subscriptionService.hasStravaEntitlement).thenReturn(false);
  });

  tearDown(() {
    settings.dispose();
  });

  Widget buildPage(
    LocationService service, {
    Stream<LocationMarkerHeading?>? headingStream = const Stream.empty(),
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ListenableProvider<AppRepository>.value(value: repository),
        ListenableProvider<SubscriptionService>.value(value: subscriptionService),
      ],
      child: MaterialApp(
        home: MapPage(locationService: service, headingStream: headingStream),
      ),
    );
  }

  testWidgets('locate delegates once, shows the marker, and centers the map', (tester) async {
    final provider = FakeMapLocationProvider(
      const ContextPosition(latitude: 47.3769, longitude: 8.5417),
    );
    final service = LocationService(provider: provider);
    await tester.pumpWidget(buildPage(service));
    await tester.pump();

    await tester.tap(find.byKey(const Key('map-locate-me')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(provider.getCurrentPositionCalls, 1);
    expect(find.byKey(const Key('map-user-location-marker')), findsOneWidget);
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.mapController!.camera.center.latitude, closeTo(47.3769, 0.001));
    expect(map.mapController!.camera.center.longitude, closeTo(8.5417, 0.001));
  });

  testWidgets('surfaces lookup errors without adding a marker', (tester) async {
    final provider = FakeMapLocationProvider(null)..error = StateError('failure');
    final service = LocationService(provider: provider);
    await tester.pumpWidget(buildPage(service));
    await tester.pump();

    await tester.tap(find.byKey(const Key('map-locate-me')));
    await tester.pump();

    expect(find.text('Unable to determine your location.'), findsOneWidget);
    expect(find.byKey(const Key('map-user-location-marker')), findsNothing);
  });

  testWidgets('offers location settings when services are disabled', (tester) async {
    final provider = FakeMapLocationProvider(null)..serviceEnabled = false;
    final service = LocationService(provider: provider);
    await tester.pumpWidget(buildPage(service));
    await tester.pump();

    await tester.tap(find.byKey(const Key('map-locate-me')));
    await tester.pump();

    expect(find.text('Location services are disabled.'), findsOneWidget);
    tester.widget<TextButton>(find.widgetWithText(TextButton, 'Settings')).onPressed!();
    expect(provider.openLocationSettingsCalls, 1);
  });

  testWidgets('offers app settings only for permanent permission denial', (tester) async {
    final provider = FakeMapLocationProvider(null)
      ..permission = LocationProviderPermission.deniedForever;
    final service = LocationService(provider: provider);
    await tester.pumpWidget(buildPage(service));
    await tester.pump();

    await tester.tap(find.byKey(const Key('map-locate-me')));
    await tester.pump();

    expect(find.text('Location permission is permanently denied.'), findsOneWidget);
    tester.widget<TextButton>(find.widgetWithText(TextButton, 'Settings')).onPressed!();
    expect(provider.openAppSettingsCalls, 1);
  });

  testWidgets('keeps ordinary permission denial retryable without settings action', (tester) async {
    final provider = FakeMapLocationProvider(null)
      ..permission = LocationProviderPermission.denied;
    final service = LocationService(provider: provider);
    await tester.pumpWidget(buildPage(service));
    await tester.pump();

    await tester.tap(find.byKey(const Key('map-locate-me')));
    await tester.pump();

    expect(find.text('Location permission was not granted.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Settings'), findsNothing);
    expect(tester.widget<IconButton>(find.byKey(const Key('map-locate-me'))).onPressed, isNotNull);
  });

  testWidgets('rejects non-finite coordinates', (tester) async {
    final provider = FakeMapLocationProvider(
      const ContextPosition(latitude: double.nan, longitude: 8.5417),
    );
    final service = LocationService(provider: provider);
    await tester.pumpWidget(buildPage(service));
    await tester.pump();

    await tester.tap(find.byKey(const Key('map-locate-me')));
    await tester.pump();

    expect(find.text('No valid location was returned.'), findsOneWidget);
    expect(find.byKey(const Key('map-user-location-marker')), findsNothing);
  });

  testWidgets('disables repeated locate taps while searching', (tester) async {
    final completer = Completer<ContextPosition>();
    final provider = FakeMapLocationProvider(null)..pendingPosition = completer.future;
    final service = LocationService(provider: provider);
    await tester.pumpWidget(buildPage(service));
    await tester.pump();

    await tester.tap(find.byKey(const Key('map-locate-me')));
    await tester.pump();

    expect(provider.getCurrentPositionCalls, 1);
    expect(
      tester.widget<IconButton>(find.byKey(const Key('map-locate-me'))).onPressed,
      isNull,
    );

    completer.complete(const ContextPosition(latitude: 47.1, longitude: 8.2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(provider.getCurrentPositionCalls, 1);
  });

  testWidgets('starts live updates only after a successful locate', (tester) async {
    final provider = FakeMapLocationProvider(
      const ContextPosition(latitude: 47.3769, longitude: 8.5417),
    );
    final service = LocationService(provider: provider);
    await tester.pumpWidget(buildPage(service));
    await tester.pump();

    expect(provider.positionController.hasListener, isFalse);

    await tester.tap(find.byKey(const Key('map-locate-me')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(provider.positionController.hasListener, isTrue);
    expect(find.byKey(const Key('map-user-location-marker')), findsOneWidget);

    // A streamed update moves the marker but must not drag the camera along.
    final before = tester.getCenter(find.byKey(const Key('map-user-location-marker')));
    provider.positionController.add(const ContextPosition(latitude: 47.3789, longitude: 8.5417));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final after = tester.getCenter(find.byKey(const Key('map-user-location-marker')));
    expect(after.dy, lessThan(before.dy));
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.mapController!.camera.center.latitude, closeTo(47.3769, 0.001));
  });

  testWidgets('shows the compass only while north is not up', (tester) async {
    final service = LocationService(provider: FakeMapLocationProvider(null));
    await tester.pumpWidget(buildPage(service));
    await tester.pump();

    expect(find.byKey(const Key('map-compass')), findsNothing);

    final controller = tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;
    controller.rotate(45);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('map-compass')), findsOneWidget);

    await tester.tap(find.byKey(const Key('map-compass')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(controller.camera.rotation, closeTo(0, 0.001));

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('map-compass')), findsNothing);
  });

  testWidgets('returns to north the short way round past a full turn', (tester) async {
    final service = LocationService(provider: FakeMapLocationProvider(null));
    await tester.pumpWidget(buildPage(service));
    await tester.pump();

    final controller = tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;
    controller.rotate(350);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('map-compass')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 350 -> 360 is a 10 degree turn; 350 -> 0 would be 350 the wrong way.
    expect(controller.camera.rotation, closeTo(360, 0.001));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('map-compass')), findsNothing);
  });

  testWidgets('uses no device heading source on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final service = LocationService(provider: FakeMapLocationProvider(null));
      await tester.pumpWidget(buildPage(service, headingStream: null));
      await tester.pump();

      // flutter_rotation_sensor 0.2.0 has no north reference on iOS, so the
      // heading cone must stay off rather than point the wrong way.
      final layer = tester.widget<CurrentLocationLayer>(find.byType(CurrentLocationLayer));
      expect(await layer.headingStream!.isEmpty, isTrue);
    } finally {
      // Must be reset inside the body: the binding asserts on leaked debug
      // variables before addTearDown callbacks run.
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('is safe to dispose during an in-flight request', (tester) async {
    final completer = Completer<ContextPosition>();
    final provider = FakeMapLocationProvider(null)..pendingPosition = completer.future;
    final service = LocationService(provider: provider);
    await tester.pumpWidget(buildPage(service));
    await tester.pump();

    await tester.tap(find.byKey(const Key('map-locate-me')));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    completer.complete(const ContextPosition(latitude: 47.1, longitude: 8.2));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  group('Strava pin state', () {
    late StravaActivity positionedActivity;

    setUp(() {
      when(() => subscriptionService.hasStravaEntitlement).thenReturn(true);
      positionedActivity = StravaActivity(
        id: 1,
        name: 'Ride',
        athlete: 1,
        sportType: SportType.Ride,
        startDate: DateTime(2025, 6, 1).toUtc(),
        startDateLocal: DateTime(2025, 6, 1).toLocal(),
        gearId: null,
        startLat: 44.16,
        startLon: 8.34,
        distance: null,
        totalElevationGain: null,
        movingTime: Duration.zero,
        elapsedTime: Duration.zero,
      );
    });

    MapPageState stateOf(WidgetTester tester) => tester.state<MapPageState>(find.byType(MapPage));

    testWidgets('reports no empty state while the activity query is pending', (tester) async {
      final completer = Completer<List<StravaActivity>>();
      when(() => repository.getFilteredStravaActivitiesWithPosition()).thenAnswer((_) => completer.future);
      await tester.pumpWidget(buildPage(LocationService(provider: FakeMapLocationProvider(null))));
      await tester.pump();

      expect(stateOf(tester).pinState, MapPinState.loading);

      completer.complete([]);
      await tester.pump();
      await tester.pump();

      expect(stateOf(tester).pinState, MapPinState.none);
    });

    testWidgets('surfaces the error state when the activity query fails', (tester) async {
      when(() => repository.getFilteredStravaActivitiesWithPosition()).thenAnswer((_) async => throw StateError('nope'));
      when(() => repository.hasSetupsWithPosition).thenReturn(true);
      await tester.pumpWidget(buildPage(LocationService(provider: FakeMapLocationProvider(null))));
      await tester.pump();
      await tester.pump();

      expect(stateOf(tester).pinState, MapPinState.error);
      expect(tester.takeException(), isNull);
    });

    testWidgets('queries once per repository notify, not per rebuild', (tester) async {
      await tester.pumpWidget(buildPage(LocationService(provider: FakeMapLocationProvider(null))));
      await tester.pump();

      verify(() => repository.getFilteredStravaActivitiesWithPosition()).called(1);

      // An unrelated rebuild: a layer toggle must not hit the database again.
      settings.displayShowSetups = false;
      await tester.pump();
      verifyNever(() => repository.getFilteredStravaActivitiesWithPosition());

      for (final listener in repositoryListeners) {
        listener();
      }
      await tester.pump();
      await tester.pump();

      verify(() => repository.getFilteredStravaActivitiesWithPosition()).called(1);
    });

    testWidgets('a repository notify does not re-enter loading', (tester) async {
      await tester.pumpWidget(buildPage(LocationService(provider: FakeMapLocationProvider(null))));
      await tester.pump();
      await tester.pump();

      expect(stateOf(tester).pinState, MapPinState.none);

      final completer = Completer<List<StravaActivity>>();
      when(() => repository.getFilteredStravaActivitiesWithPosition()).thenAnswer((_) => completer.future);
      for (final listener in repositoryListeners) {
        listener();
      }
      await tester.pump();

      expect(stateOf(tester).pinState, MapPinState.none);

      completer.complete([]);
      await tester.pump();
      await tester.pump();

      expect(stateOf(tester).pinState, MapPinState.none);
    });

    testWidgets('separates a filtered-empty map from an empty one', (tester) async {
      when(() => repository.hasStravaActivitiesWithPosition()).thenAnswer((_) async => true);
      await tester.pumpWidget(buildPage(LocationService(provider: FakeMapLocationProvider(null))));
      await tester.pump();
      await tester.pump();

      expect(stateOf(tester).pinState, MapPinState.filtered);
    });

    testWidgets('reports nothing once an activity is pinned', (tester) async {
      when(() => repository.getFilteredStravaActivitiesWithPosition()).thenAnswer((_) async => [positionedActivity]);
      await tester.pumpWidget(buildPage(LocationService(provider: FakeMapLocationProvider(null))));
      await tester.pump();
      await tester.pump();

      expect(stateOf(tester).pinState, isNull);
    });
  });
}

class FakeMapLocationProvider implements LocationProvider {
  final ContextPosition? position;
  final StreamController<ContextPosition> positionController = StreamController<ContextPosition>.broadcast();
  Future<ContextPosition>? pendingPosition;
  Object? error;
  int getCurrentPositionCalls = 0;
  int openAppSettingsCalls = 0;
  int openLocationSettingsCalls = 0;
  bool serviceEnabled = true;
  LocationProviderPermission permission = LocationProviderPermission.whileInUse;

  FakeMapLocationProvider(this.position);

  @override
  Future<LocationProviderPermission> checkPermission() async {
    return permission;
  }

  @override
  Future<ContextPosition> getCurrentPosition() async {
    getCurrentPositionCalls++;
    if (error != null) throw error!;
    if (pendingPosition != null) return pendingPosition!;
    return position!;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCalls++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    openLocationSettingsCalls++;
    return true;
  }

  @override
  Future<LocationProviderPermission> requestPermission() async {
    return permission;
  }

  @override
  Stream<ContextPosition> getPositionStream() => positionController.stream;
}

class MockSubscriptionService extends Mock implements SubscriptionService {}

class MockAppRepository extends Mock implements AppRepository {}