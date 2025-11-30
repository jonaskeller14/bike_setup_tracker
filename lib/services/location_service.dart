import 'package:location/location.dart';

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
    status = LocationStatus.idle;
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

    final location = await _location.getLocation();
    status = LocationStatus.success;
    return location;
  }
}
