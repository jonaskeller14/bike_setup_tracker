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
      setStatus(LocationStatus.idle);
      location = null;
    } catch (_) {
      location = null;
      setStatus(LocationStatus.noPermission);
    }    
    return location;
  }

  static Future<LocationData?> locationFromAddress(String address) async {
    geo.Location? geoLocation;
    try {
      geoLocation = (await geo.locationFromAddress(address)).first;
    } catch (e) {
      geoLocation = null;
    }
    if (geoLocation == null) return null;
    return LocationData.fromMap(geoLocation.toJson());
  }

  static LocationData setAltitude({required LocationData? location, required double? newAltitude}) {
    final newMap = location == null ? <String, dynamic>{} : Setup.locationDataToJson(location);
    newMap['altitude'] = newAltitude;
    newMap['time'] = newMap['time'] != null ? DateTime.parse(newMap['time']).millisecondsSinceEpoch.toDouble() : null;
    return LocationData.fromMap(newMap);
  }
}
