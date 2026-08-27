import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:location/location.dart';

import '../models/context/context_position.dart';

enum LocationStatus {
  idle,
  searching,
  noService,
  noPermission,
  error,
  success,
}

class LocationService extends ChangeNotifier {
  final Location _location = Location();
  LocationStatus _status = LocationStatus.idle;
  static const _timeoutDuration = kDebugMode ? Duration(seconds: 30) : Duration(seconds: 5);

  LocationStatus get status => _status;

  void setStatus(LocationStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  Future<ContextPosition?> fetchLocation() async {
    setStatus(LocationStatus.searching);
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        setStatus(LocationStatus.noService);
        return null;
      }
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setStatus(LocationStatus.noPermission);
        return null;
      }
    }

    LocationData? location;
    try {
      location = await Future.any([
        _location.getLocation(),
        Future.delayed(_timeoutDuration, () => null),
      ]);

      location ??= await _location.getLocation().timeout(
        _timeoutDuration,
        onTimeout: () {
          throw TimeoutException('Location retrieval timed out.');
        },
      );
      setStatus(LocationStatus.success);
    } on TimeoutException catch (e) {
      debugPrint("Location Timeout Error: $e");
      setStatus(LocationStatus.error);
      location = null;
    } catch (_) {
      location = null;
      setStatus(LocationStatus.error);
    }    
    return location == null ? null : _fromLocationData(location);
  }

  Future<ContextPosition?> locationFromAddress(String address) async {
    setStatus(LocationStatus.searching);

    try {
      final geoLocations = await geo.locationFromAddress(address);
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

  static ContextPosition _fromLocationData(LocationData location) {
    return ContextPosition(
      latitude: location.latitude,
      longitude: location.longitude,
      altitude: location.altitude,
      accuracy: location.accuracy,
      heading: location.heading,
      speed: location.speed,
      speedAccuracy: location.speedAccuracy,
      timestamp: location.time == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              location.time!.toInt(),
              isUtc: true,
            ),
      isMock: location.isMock,
    );
  }
}
