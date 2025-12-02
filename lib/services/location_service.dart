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

class LocationService {
  final Location _location = Location();
  LocationStatus status = LocationStatus.idle;

  Future<LocationData?> fetchLocation() async {
    status = LocationStatus.searching;
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        status = LocationStatus.noService;
        return null;
      }
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        status = LocationStatus.noPermission;
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
      status = LocationStatus.success;
    } on TimeoutException catch (e) {
      debugPrint("Location Timeout Error: $e");
      status = LocationStatus.idle;
      location = null;
    } catch (_) {
      location = null;
      status = LocationStatus.noPermission;
    }    
    return location;
  }

  Future<LocationData?> locationFromAddress(String address) async {
    geo.Location? geoLocation;
    try {
      geoLocation = (await geo.locationFromAddress(address)).first;
    } catch (e) {
      geoLocation = null;
    }
    if (geoLocation == null) return null;
    return LocationData.fromMap(geoLocation.toJson());
  }

  LocationData setAltitude({required LocationData? location, required double? newAltitude}) {
    final newMap = location == null ? <String, dynamic>{} : Setup.locationDataToJson(location);
    newMap['altitude'] = newAltitude;
    newMap['time'] = newMap['time'] != null ? DateTime.parse(newMap['time']).millisecondsSinceEpoch.toDouble() : null;
    return LocationData.fromMap(newMap);
  }
}
