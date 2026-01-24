import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../models/setup.dart';

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

  LocationStatus get status => _status;

  void setStatus(LocationStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  Future<LocationData?> fetchLocation() async {
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
        Future.delayed(Duration(seconds: 5), () => null),
      ]);

      location ??= await _location.getLocation().timeout(
        const Duration(seconds: 5),
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
    return location;
  }

  Future<LocationData?> locationFromAddress(String address) async {
    setStatus(LocationStatus.searching);

    try {
      final geoLocations = await geo.locationFromAddress(address);
      final geoLocation = geoLocations.firstOrNull;
      if (geoLocation == null) {
        setStatus(LocationStatus.idle);
        return null;
      }
      final locationData = LocationData.fromMap(geoLocation.toJson());
      
      setStatus(LocationStatus.success);
      return locationData;
    } catch (e) {
      setStatus(LocationStatus.error);
      return null;
    }
  }

  static LocationData copyWithLocationData(LocationData? location, {
    Object? latitude = const _Sentinel(),
    Object? longitude = const _Sentinel(),
    Object? altitude = const _Sentinel(),
  }) {
    final newMap = location == null ? <String, dynamic>{} : Setup.locationDataToJson(location);
    if (latitude is! _Sentinel) newMap["latitude"] = latitude as double?;
    if (longitude is! _Sentinel) newMap["longitude"] = longitude as double?;
    if (altitude is! _Sentinel) newMap["altitude"] = altitude as double?;
    newMap['time'] = newMap['time'] != null ? DateTime.parse(newMap['time']).millisecondsSinceEpoch.toDouble() : null;
    return LocationData.fromMap(newMap);
  }
}

class _Sentinel {
  const _Sentinel();
}
