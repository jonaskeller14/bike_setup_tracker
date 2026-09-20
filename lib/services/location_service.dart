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
  timeout,
  error,
  success,
}

class LocationService extends ChangeNotifier {
  static final geo.Geocoding _geocoding = geo.Geocoding();
  final LocationProvider _provider;
  final Future<List<ContextPosition>> Function(String) _addressLookup;
  final StreamController<ContextPosition> _positions = StreamController<ContextPosition>.broadcast();
  StreamSubscription<ContextPosition>? _positionSubscription;
  LocationStatus _status = LocationStatus.idle;
  bool _disposed = false;

  LocationService({
    LocationProvider? provider,
    Future<List<ContextPosition>> Function(String)? addressLookup,
  }) : _provider = provider ?? GeolocatorLocationProvider(),
       _addressLookup = addressLookup ?? _locationsFromAddress;

  LocationStatus get status => _status;

  /// Positions emitted by [fetchLocation] and, once [startPositionUpdates] has
  /// been called, by the platform's continuous updates.
  Stream<ContextPosition> get positionStream => _positions.stream;

  /// Idempotent: a second call while already subscribed is a no-op.
  void startPositionUpdates() {
    if (_disposed || _positionSubscription != null) return;
    _positionSubscription = _provider.getPositionStream().listen(
      _emitPosition,
      onError: (Object error) => debugPrint('Location stream error: $error'),
    );
  }

  void stopPositionUpdates() {
    unawaited(_positionSubscription?.cancel());
    _positionSubscription = null;
  }

  void _emitPosition(ContextPosition position) {
    if (_disposed) return;
    _positions.add(position);
  }

  void setStatus(LocationStatus newStatus) {
    if (_disposed) return;
    _status = newStatus;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stopPositionUpdates();
    unawaited(_positions.close());
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
      _emitPosition(location);
      return location;
    } on LocationProviderServiceDisabledException {
      setStatus(LocationStatus.noService);
      return null;
    } on TimeoutException catch (error) {
      debugPrint('Location timeout: $error');
      setStatus(LocationStatus.timeout);
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
    final locations = await _geocoding.locationFromAddress(address);
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
