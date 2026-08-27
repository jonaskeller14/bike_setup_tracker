import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../models/context/context_position.dart';

enum LocationProviderPermission {
  denied,
  deniedForever,
  whileInUse,
  always,
  unableToDetermine,
}

abstract interface class LocationProvider {
  Future<bool> isLocationServiceEnabled();

  Future<LocationProviderPermission> checkPermission();

  Future<LocationProviderPermission> requestPermission();

  Future<ContextPosition> getCurrentPosition();

  Future<bool> openAppSettings();

  Future<bool> openLocationSettings();
}

class LocationProviderServiceDisabledException implements Exception {
  const LocationProviderServiceDisabledException();
}

class GeolocatorLocationProvider implements LocationProvider {
  static const _timeoutDuration = kDebugMode ? Duration(seconds: 30) : Duration(seconds: 5);

  @override
  Future<bool> isLocationServiceEnabled() => geo.Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationProviderPermission> checkPermission() async {
    return _mapPermission(await geo.Geolocator.checkPermission());
  }

  @override
  Future<LocationProviderPermission> requestPermission() async {
    return _mapPermission(await geo.Geolocator.requestPermission());
  }

  @override
  Future<ContextPosition> getCurrentPosition() async {
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: _timeoutDuration,
        ),
      );
      return mapPosition(position);
    } on geo.LocationServiceDisabledException {
      throw const LocationProviderServiceDisabledException();
    }
  }

  @override
  Future<bool> openAppSettings() => geo.Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => geo.Geolocator.openLocationSettings();

  static LocationProviderPermission _mapPermission(geo.LocationPermission permission) {
    return switch (permission) {
      geo.LocationPermission.denied => LocationProviderPermission.denied,
      geo.LocationPermission.deniedForever => LocationProviderPermission.deniedForever,
      geo.LocationPermission.whileInUse => LocationProviderPermission.whileInUse,
      geo.LocationPermission.always => LocationProviderPermission.always,
      geo.LocationPermission.unableToDetermine => LocationProviderPermission.unableToDetermine,
    };
  }

  @visibleForTesting
  static ContextPosition mapPosition(geo.Position position) {
    return ContextPosition(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.hasAltitude ? position.altitude : null,
      accuracy: position.hasAccuracy ? position.accuracy : null,
      heading: position.hasHeading ? position.heading : null,
      speed: position.hasSpeed ? position.speed : null,
      speedAccuracy: position.hasSpeedAccuracy ? position.speedAccuracy : null,
      timestamp: position.timestamp,
      isMock: position.isMocked,
    );
  }
}
