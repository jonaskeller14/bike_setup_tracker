import 'package:geocoding/geocoding.dart' as geo;
import 'package:flutter/foundation.dart';

enum AddressStatus {
  idle,
  searching,
  success,
  error,
}

class AddressService {
  AddressStatus status = AddressStatus.idle;

  Future<geo.Placemark?> fetchAddress({required double lat, required double lon}) async {
    status = AddressStatus.searching;
    try {
      final List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        status = AddressStatus.success;
        return placemarks.first;
      }
      return null;
    } catch (e) {
      status = AddressStatus.error;
      debugPrint('AddressService: Failed to get address: $e');
      return null;
    }
  }
}
