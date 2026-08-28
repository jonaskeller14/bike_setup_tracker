import 'dart:async';

import 'package:bike_setup_tracker/models/context/context_position.dart';
import 'package:bike_setup_tracker/services/elevation_service.dart';
import 'package:bike_setup_tracker/services/location_provider.dart';
import 'package:bike_setup_tracker/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as geo;

void main() {
  group('ElevationService.addMissingElevation', () {
    test('adds fetched elevation when altitude is missing', () async {
      final result = await FakeElevationService(512).addMissingElevation(
        const ContextPosition(latitude: 47.1, longitude: 8.2),
      );

      expect(result.altitude, 512);
    });

    test('preserves altitude already reported by the location provider', () async {
      final service = FakeElevationService(900);
      const position = ContextPosition(latitude: 47.1, longitude: 8.2, altitude: 512);

      expect(await service.addMissingElevation(position), same(position));
      expect(service.fetchCalls, 0);
    });
  });

  group('LocationService.fetchLocation', () {
    test('reports disabled services without checking permission', () async {
      final provider = FakeLocationProvider()..serviceEnabled = false;
      final service = LocationService(provider: provider);

      expect(await service.fetchLocation(), isNull);
      expect(service.status, LocationStatus.noService);
      expect(provider.checkPermissionCalls, 0);
      expect(provider.getCurrentPositionCalls, 0);
    });

    test('requests a denied permission and continues when granted', () async {
      final provider = FakeLocationProvider()
        ..checkedPermission = LocationProviderPermission.denied
        ..requestedPermission = LocationProviderPermission.whileInUse;
      final service = LocationService(provider: provider);

      expect(await service.fetchLocation(), provider.position);
      expect(service.status, LocationStatus.success);
      expect(provider.requestPermissionCalls, 1);
      expect(provider.getCurrentPositionCalls, 1);
    });

    test('keeps an ordinary denial retryable', () async {
      final provider = FakeLocationProvider()
        ..checkedPermission = LocationProviderPermission.denied
        ..requestedPermission = LocationProviderPermission.denied;
      final service = LocationService(provider: provider);

      expect(await service.fetchLocation(), isNull);
      expect(service.status, LocationStatus.noPermission);
      expect(provider.getCurrentPositionCalls, 0);
    });

    test('reports permanently denied permission distinctly', () async {
      final provider = FakeLocationProvider()..checkedPermission = LocationProviderPermission.deniedForever;
      final service = LocationService(provider: provider);

      expect(await service.fetchLocation(), isNull);
      expect(service.status, LocationStatus.permissionDeniedForever);
      expect(provider.requestPermissionCalls, 0);
      expect(provider.getCurrentPositionCalls, 0);
    });

    test('treats unable-to-determine permission as unavailable', () async {
      final provider = FakeLocationProvider()..checkedPermission = LocationProviderPermission.unableToDetermine;
      final service = LocationService(provider: provider);

      expect(await service.fetchLocation(), isNull);
      expect(service.status, LocationStatus.noPermission);
      expect(provider.getCurrentPositionCalls, 0);
    });

    for (final permission in [
      LocationProviderPermission.whileInUse,
      LocationProviderPermission.always,
    ]) {
      test('treats ${permission.name} as granted', () async {
        final provider = FakeLocationProvider()..checkedPermission = permission;
        final service = LocationService(provider: provider);

        expect(await service.fetchLocation(), provider.position);
        expect(service.status, LocationStatus.success);
        expect(provider.getCurrentPositionCalls, 1);
      });
    }

    test('handles a timeout with one acquisition call', () async {
      final provider = FakeLocationProvider()..currentPositionError = TimeoutException('timed out');
      final service = LocationService(provider: provider);

      expect(await service.fetchLocation(), isNull);
      expect(service.status, LocationStatus.timeout);
      expect(provider.getCurrentPositionCalls, 1);
    });

    test('handles a service-disabled acquisition race', () async {
      final provider = FakeLocationProvider()..currentPositionError = const LocationProviderServiceDisabledException();
      final service = LocationService(provider: provider);

      expect(await service.fetchLocation(), isNull);
      expect(service.status, LocationStatus.noService);
      expect(provider.getCurrentPositionCalls, 1);
    });

    test('contains unexpected provider exceptions', () async {
      final provider = FakeLocationProvider()..currentPositionError = StateError('plugin failure');
      final service = LocationService(provider: provider);

      expect(await service.fetchLocation(), isNull);
      expect(service.status, LocationStatus.error);
      expect(provider.getCurrentPositionCalls, 1);
    });

    test('notifies deterministic searching then success states', () async {
      final provider = FakeLocationProvider();
      final service = LocationService(provider: provider);
      final statuses = <LocationStatus>[];
      service.addListener(() => statuses.add(service.status));

      expect(await service.fetchLocation(), provider.position);

      expect(statuses, [LocationStatus.searching, LocationStatus.success]);
    });

    test('does not start a concurrent acquisition', () async {
      final completer = Completer<ContextPosition>();
      final provider = FakeLocationProvider()..currentPosition = () => completer.future;
      final service = LocationService(provider: provider);

      final first = service.fetchLocation();
      await Future<void>.delayed(Duration.zero);
      expect(await service.fetchLocation(), isNull);
      completer.complete(provider.position);
      expect(await first, provider.position);
      expect(provider.getCurrentPositionCalls, 1);
    });

    test('does not notify after disposal during an acquisition', () async {
      final completer = Completer<ContextPosition>();
      final provider = FakeLocationProvider()..currentPosition = () => completer.future;
      final service = LocationService(provider: provider);

      final request = service.fetchLocation();
      await Future<void>.delayed(Duration.zero);
      service.dispose();
      completer.complete(provider.position);

      expect(await request, provider.position);
    });
  });

  group('LocationService.locationFromAddress', () {
    test('returns the first address match', () async {
      final expected = ContextPosition(
        latitude: 47.1,
        longitude: 8.2,
        timestamp: DateTime.utc(2026, 8, 27),
      );
      final service = LocationService(
        provider: FakeLocationProvider(),
        addressLookup: (_) async => [expected],
      );

      expect(await service.locationFromAddress('Zurich'), expected);
      expect(service.status, LocationStatus.success);
    });

    test('returns idle for an empty address result', () async {
      final service = LocationService(
        provider: FakeLocationProvider(),
        addressLookup: (_) async => [],
      );

      expect(await service.locationFromAddress('Unknown'), isNull);
      expect(service.status, LocationStatus.idle);
    });
  });

  group('GeolocatorLocationProvider mapping', () {
    test('maps reported fields to ContextPosition', () {
      final timestamp = DateTime.utc(2026, 8, 27, 12);
      final result = GeolocatorLocationProvider.mapPosition(
        geo.Position(
          latitude: 47.1,
          longitude: 8.2,
          timestamp: timestamp,
          accuracy: 3,
          altitude: 512,
          altitudeAccuracy: 4,
          heading: 180,
          headingAccuracy: 5,
          speed: 6,
          speedAccuracy: 0.5,
          isMocked: true,
          hasAccuracy: true,
          hasAltitude: true,
          hasHeading: true,
          hasSpeed: true,
          hasSpeedAccuracy: true,
        ),
      );

      expect(
        result,
        ContextPosition(
          latitude: 47.1,
          longitude: 8.2,
          accuracy: 3,
          altitude: 512,
          heading: 180,
          speed: 6,
          speedAccuracy: 0.5,
          timestamp: timestamp,
          isMock: true,
        ),
      );
    });

    test('keeps measurements null when the platform did not report them', () {
      final result = GeolocatorLocationProvider.mapPosition(
        geo.Position(
          latitude: 47.1,
          longitude: 8.2,
          timestamp: DateTime.utc(2026, 8, 27),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );

      expect(result.accuracy, isNull);
      expect(result.altitude, isNull);
      expect(result.heading, isNull);
      expect(result.speed, isNull);
      expect(result.speedAccuracy, isNull);
    });

    test('keeps non-zero altitude when Android loses the availability flag', () {
      final result = GeolocatorLocationProvider.mapPosition(
        geo.Position(
          latitude: 47.1,
          longitude: 8.2,
          timestamp: DateTime.utc(2026, 8, 27),
          accuracy: 0,
          altitude: 512,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );

      expect(result.altitude, 512);
    });
  });
}

class FakeElevationService extends ElevationService {
  final double? elevation;
  int fetchCalls = 0;

  FakeElevationService(this.elevation);

  @override
  Future<double?> fetchElevation({required double lat, required double lon}) async {
    fetchCalls++;
    return elevation;
  }
}

class FakeLocationProvider implements LocationProvider {
  bool serviceEnabled = true;
  LocationProviderPermission checkedPermission = LocationProviderPermission.whileInUse;
  LocationProviderPermission requestedPermission = LocationProviderPermission.whileInUse;
  ContextPosition position = const ContextPosition(latitude: 47.1, longitude: 8.2);
  Object? currentPositionError;
  Future<ContextPosition> Function()? currentPosition;
  int checkPermissionCalls = 0;
  int requestPermissionCalls = 0;
  int getCurrentPositionCalls = 0;

  @override
  Future<LocationProviderPermission> checkPermission() async {
    checkPermissionCalls++;
    return checkedPermission;
  }

  @override
  Future<ContextPosition> getCurrentPosition() async {
    getCurrentPositionCalls++;
    if (currentPositionError != null) throw currentPositionError!;
    return currentPosition?.call() ?? position;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<LocationProviderPermission> requestPermission() async {
    requestPermissionCalls++;
    return requestedPermission;
  }
}
