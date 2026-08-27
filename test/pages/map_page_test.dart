import 'dart:async';

import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/models/bike.dart';
import 'package:bike_setup_tracker/models/context/context_position.dart';
import 'package:bike_setup_tracker/pages/map_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/services/location_provider.dart';
import 'package:bike_setup_tracker/services/location_service.dart';
import 'package:bike_setup_tracker/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MockAppRepository repository;
  late AppSettings settings;
  late MockSubscriptionService subscriptionService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = MockAppRepository();
    when(() => repository.bikes).thenReturn(<String, Bike>{});
    when(() => repository.selectedBike).thenReturn(null);
    when(() => repository.selectedSetupTags).thenReturn(<String>{});
    when(() => repository.filteredSetups).thenReturn({});
    when(() => repository.filteredRatingEntries).thenReturn({});
    when(() => repository.getFilteredStravaActivitiesWithPosition()).thenAnswer((_) async => []);
    settings = AppSettings();
    subscriptionService = MockSubscriptionService();
    when(() => subscriptionService.hasStravaEntitlement).thenReturn(false);
  });

  tearDown(() {
    settings.dispose();
  });

  Widget buildPage(LocationService service) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ListenableProvider<AppRepository>.value(value: repository),
        ListenableProvider<SubscriptionService>.value(value: subscriptionService),
      ],
      child: MaterialApp(home: MapPage(locationService: service)),
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
}

class FakeMapLocationProvider implements LocationProvider {
  final ContextPosition? position;
  Future<ContextPosition>? pendingPosition;
  Object? error;
  int getCurrentPositionCalls = 0;

  FakeMapLocationProvider(this.position);

  @override
  Future<LocationProviderPermission> checkPermission() async {
    return LocationProviderPermission.whileInUse;
  }

  @override
  Future<ContextPosition> getCurrentPosition() async {
    getCurrentPositionCalls++;
    if (error != null) throw error!;
    if (pendingPosition != null) return pendingPosition!;
    return position!;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<LocationProviderPermission> requestPermission() async {
    return LocationProviderPermission.whileInUse;
  }
}

class MockSubscriptionService extends Mock implements SubscriptionService {}

class MockAppRepository extends Mock implements AppRepository {}
