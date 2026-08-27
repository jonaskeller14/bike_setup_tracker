import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;

import '../models/context/context_position.dart';
import 'location_provider.dart';

enum LocationStatus {
  idle,
  searching,
  noService,
  noPermission,
  permissionDeniedForever,
  error,
  success,
}

class LocationService extends ChangeNotifier {
  final LocationProvider _provider;
  final Future<List<ContextPosition>> Function(String) _addressLookup;
  LocationStatus _status = LocationStatus.idle;
  bool _disposed = false;

  LocationService({
    LocationProvider? provider,
    Future<List<ContextPosition>> Function(String)? addressLookup,
  }) : _provider = provider ?? GeolocatorLocationProvider(),
       _addressLookup = addressLookup ?? _locationsFromAddress;

  LocationStatus get status => _status;

  void setStatus(LocationStatus newStatus) {
    if (_disposed) return;
    _status = newStatus;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<ContextPosition?> fetchLocation() async {
    if (_status == LocationStatus.searching) return null;
    setStatus(LocationStatus.searching);
    try {
      if (!await _provider.isLocationServiceEnabled()) {
        setStatus(LocationStatus.noService);
        return null;
      }

      var permission = await _provider.checkPermission();
      if (permission == LocationProviderPermission.denied) {
        permission = await _provider.requestPermission();
      }

      switch (permission) {
        case LocationProviderPermission.denied:
        case LocationProviderPermission.unableToDetermine:
          setStatus(LocationStatus.noPermission);
          return null;
        case LocationProviderPermission.deniedForever:
          setStatus(LocationStatus.permissionDeniedForever);
          return null;
        case LocationProviderPermission.whileInUse:
        case LocationProviderPermission.always:
          break;
      }

      final location = await _provider.getCurrentPosition();
      setStatus(LocationStatus.success);
      return location;
    } on LocationProviderServiceDisabledException {
      setStatus(LocationStatus.noService);
      return null;
    } on TimeoutException catch (error) {
      debugPrint('Location timeout: $error');
      setStatus(LocationStatus.error);
      return null;
    } catch (error) {
      debugPrint('Location error: $error');
      setStatus(LocationStatus.error);
      return null;
    }
  }

  Future<bool> openAppSettings() => _provider.openAppSettings();

  Future<bool> openLocationSettings() => _provider.openLocationSettings();

  Future<ContextPosition?> locationFromAddress(String address) async {
    setStatus(LocationStatus.searching);

    try {
      final geoLocations = await _addressLookup(address);
      final geoLocation = geoLocations.firstOrNull;
      if (geoLocation == null) {
        setStatus(LocationStatus.idle);
        return null;
      }
      setStatus(LocationStatus.success);
      return ContextPosition(
        latitude: geoLocation.latitude,
        longitude: geoLocation.longitude,
        timestamp: geoLocation.timestamp,
      );
    } catch (e) {
      setStatus(LocationStatus.error);
      return null;
    }
  }

  static Future<List<ContextPosition>> _locationsFromAddress(String address) async {
    final locations = await geo.locationFromAddress(address);
    return locations
        .map(
          (location) => ContextPosition(
            latitude: location.latitude,
            longitude: location.longitude,
            timestamp: location.timestamp,
          ),
        )
        .toList();
  }
}
