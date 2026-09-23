import 'dart:async';

import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/context/context_position.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/models/task/task_rule.dart';
import 'package:bike_setup_tracker/pages/map_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/location_provider.dart';
import 'package:bike_setup_tracker/services/location_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:bike_setup_tracker/utils/map_empty_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
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

  /// For tests that do not exercise location: the automatic lookup on open
  /// stops at the permission check, so no position is ever produced.
  LocationService unpermittedService() => LocationService(
    provider: FakeMapLocationProvider(null)..permission = LocationProviderPermission.denied,
  );

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
    await tester.pump(const Duration(milliseconds: 600));
    // The page looks the user up automatically when it opens.
    final callsBeforeTap = provider.getCurrentPositionCalls;

    await tester.tap(find.byKey(const Key('map-locate-me')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(provider.getCurrentPositionCalls, callsBeforeTap + 1);
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

    // The automatic lookup on open is already searching.
    expect(provider.getCurrentPositionCalls, 1);
    expect(
      tester.widget<IconButton>(find.byKey(const Key('map-locate-me'))).onPressed,
      isNull,
    );

    await tester.tap(find.byKey(const Key('map-locate-me')));
    await tester.pump();
    expect(provider.getCurrentPositionCalls, 1);

    completer.complete(const ContextPosition(latitude: 47.1, longitude: 8.2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(provider.getCurrentPositionCalls, 1);
  });

  testWidgets('starts live updates only once a location arrives', (tester) async {
    final completer = Completer<ContextPosition>();
    final provider = FakeMapLocationProvider(null)..pendingPosition = completer.future;
    final service = LocationService(provider: provider);
    await tester.pumpWidget(buildPage(service));
    await tester.pump();

    expect(provider.positionController.hasListener, isFalse);

    completer.complete(const ContextPosition(latitude: 47.3769, longitude: 8.5417));
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
    final service = unpermittedService();
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
    final service = unpermittedService();
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
      final service = unpermittedService();
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

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    completer.complete(const ContextPosition(latitude: 47.1, longitude: 8.2));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  group('Automatic locate on open', () {
    const userPosition = ContextPosition(latitude: 47.3769, longitude: 8.5417);
    const pinPoint = LatLng(44.16, 8.34);
    const userPoint = LatLng(47.3769, 8.5417);

    MapCamera cameraOf(WidgetTester tester) =>
        tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!.camera;

    void stubPositionedSetup() {
      final setup = Setup(
        datetime: DateTime(2025, 6, 1).toUtc(),
        datetimeLocal: DateTime(2025, 6, 1),
        tags: const {},
        bike: 'bike-1',
        person: null,
        bikeAdjustmentValues: const {},
        personAdjustmentValues: const {},
        position: ContextPosition(latitude: pinPoint.latitude, longitude: pinPoint.longitude),
      );
      when(() => repository.filteredSetups).thenReturn({setup.id: setup});
      when(() => repository.hasSetupsWithPosition).thenReturn(true);
    }

    testWidgets('centers on the user when the map has no pins', (tester) async {
      final provider = FakeMapLocationProvider(userPosition);
      await tester.pumpWidget(buildPage(LocationService(provider: provider)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(provider.getCurrentPositionCalls, 1);
      expect(find.byKey(const Key('map-user-location-marker')), findsOneWidget);
      final camera = cameraOf(tester);
      expect(camera.center.latitude, closeTo(47.3769, 0.001));
      expect(camera.center.longitude, closeTo(8.5417, 0.001));
      expect(camera.zoom, closeTo(15, 0.001));
    });

    testWidgets('refits the camera to the pins and the user', (tester) async {
      stubPositionedSetup();
      await tester.pumpWidget(buildPage(LocationService(provider: FakeMapLocationProvider(userPosition))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final camera = cameraOf(tester);
      expect(camera.visibleBounds.contains(userPoint), isTrue);
      expect(camera.visibleBounds.contains(pinPoint), isTrue);
      // The pin overview zoomed out to take the distant user in.
      expect(camera.zoom, lessThan(13));
    });

    testWidgets('stays silent when the lookup fails', (tester) async {
      final provider = FakeMapLocationProvider(null)..error = StateError('failure');
      await tester.pumpWidget(buildPage(LocationService(provider: provider)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(provider.getCurrentPositionCalls, 1);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byKey(const Key('map-user-location-marker')), findsNothing);
    });

    testWidgets('leaves a camera the user has already moved alone', (tester) async {
      final completer = Completer<ContextPosition>();
      stubPositionedSetup();
      final provider = FakeMapLocationProvider(null)..pendingPosition = completer.future;
      await tester.pumpWidget(buildPage(LocationService(provider: provider)));
      await tester.pump();

      // Slow enough to count as a pan rather than a fling.
      final gesture = await tester.startGesture(tester.getCenter(find.byType(FlutterMap)));
      await gesture.moveBy(const Offset(0, -80));
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 600));
      final panned = cameraOf(tester).center;

      completer.complete(userPosition);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // The location was taken (live updates started) but the camera stayed put,
      // so the user marker is simply off-screen.
      expect(provider.positionController.hasListener, isTrue);
      expect(cameraOf(tester).center, panned);
    });

    testWidgets('does not look up again once permission is permanently denied', (tester) async {
      final provider = FakeMapLocationProvider(userPosition);
      final service = LocationService(provider: provider)
        ..setStatus(LocationStatus.permissionDeniedForever);
      await tester.pumpWidget(buildPage(service));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(provider.getCurrentPositionCalls, 0);
      expect(find.byKey(const Key('map-user-location-marker')), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });
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
      await tester.pumpWidget(buildPage(unpermittedService()));
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
      await tester.pumpWidget(buildPage(unpermittedService()));
      await tester.pump();
      await tester.pump();

      expect(stateOf(tester).pinState, MapPinState.error);
      expect(tester.takeException(), isNull);
    });

    testWidgets('queries once per repository notify, not per rebuild', (tester) async {
      await tester.pumpWidget(buildPage(unpermittedService()));
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
      await tester.pumpWidget(buildPage(unpermittedService()));
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
      await tester.pumpWidget(buildPage(unpermittedService()));
      await tester.pump();
      await tester.pump();

      expect(stateOf(tester).pinState, MapPinState.filtered);
    });

    testWidgets('reports nothing once an activity is pinned', (tester) async {
      when(() => repository.getFilteredStravaActivitiesWithPosition()).thenAnswer((_) async => [positionedActivity]);
      await tester.pumpWidget(buildPage(unpermittedService()));
      await tester.pump();
      await tester.pump();

      expect(stateOf(tester).pinState, isNull);
    });
  });

  group('Empty-state card', () {
    void notifyRepository() {
      for (final listener in repositoryListeners) {
        listener();
      }
    }

    testWidgets('stays away while the activity query is pending', (tester) async {
      when(() => subscriptionService.hasStravaEntitlement).thenReturn(true);
      final completer = Completer<List<StravaActivity>>();
      when(() => repository.getFilteredStravaActivitiesWithPosition()).thenAnswer((_) => completer.future);
      await tester.pumpWidget(buildPage(unpermittedService()));
      await tester.pump();

      expect(find.byKey(const Key('map-empty-none')), findsNothing);

      completer.complete([]);
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('map-empty-none')), findsOneWidget);
    });

    testWidgets('clears the filters from the filtered card', (tester) async {
      when(() => repository.hasSetupsWithPosition).thenReturn(true);
      when(() => repository.onBikeTap(any())).thenAnswer((_) {});
      await tester.pumpWidget(buildPage(unpermittedService()));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('map-empty-filtered')), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Clear filters'));
      await tester.pump();

      verify(() => repository.onBikeTap(null)).called(1);
    });

    testWidgets('collapses to a pill and expands again on a new reason', (tester) async {
      await tester.pumpWidget(buildPage(unpermittedService()));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.byKey(const Key('map-empty-collapse')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('map-empty-pill')), findsOneWidget);
      expect(find.byKey(const Key('map-empty-none')), findsNothing);

      // Positioned data appears: the reason turns into `filtered`.
      when(() => repository.hasSetupsWithPosition).thenReturn(true);
      notifyRepository();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('map-empty-filtered')), findsOneWidget);
      expect(find.byKey(const Key('map-empty-pill')), findsNothing);
    });

    testWidgets('leaves the map draggable around the card', (tester) async {
      await tester.pumpWidget(buildPage(unpermittedService()));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('map-empty-none')), findsOneWidget);
      final controller = tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;
      final before = controller.camera.center;

      final gesture = await tester.startGesture(tester.getCenter(find.byType(FlutterMap)));
      await gesture.moveBy(const Offset(0, -80));
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 600));

      // Dragging upwards pulls the camera south, card or no card.
      expect(controller.camera.center.latitude, lessThan(before.latitude));
    });

    testWidgets('disappears once a pin is visible', (tester) async {
      await tester.pumpWidget(buildPage(unpermittedService()));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('map-empty-none')), findsOneWidget);

      final setup = Setup(
        datetime: DateTime(2025, 6, 1).toUtc(),
        datetimeLocal: DateTime(2025, 6, 1),
        tags: const {},
        bike: 'bike-1',
        person: null,
        bikeAdjustmentValues: const {},
        personAdjustmentValues: const {},
        position: const ContextPosition(latitude: 44.16, longitude: 8.34),
      );
      when(() => repository.filteredSetups).thenReturn({setup.id: setup});
      when(() => repository.hasSetupsWithPosition).thenReturn(true);
      notifyRepository();
      await tester.pump();
      await tester.pump();

      expect(tester.state<MapPageState>(find.byType(MapPage)).pinState, isNull);
      expect(find.byKey(const Key('map-empty-none')), findsNothing);
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