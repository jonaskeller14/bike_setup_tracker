import 'package:geocoding/geocoding.dart' as geo;
import 'package:flutter/foundation.dart';

class AddressService {
  Future<geo.Placemark?> getPlacemark({required double lat, required double lon}) async {
    try {
      final List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        return placemarks.first;
      }
      return null;
    } catch (e, stack) {
      debugPrint('AddressService: Failed to get address: $e\n$stack');
      return null;
    }
  }
}
