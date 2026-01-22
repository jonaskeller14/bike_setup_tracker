import 'package:geocoding/geocoding.dart' as geo;
import 'package:flutter/foundation.dart';

enum AddressStatus {
  idle,
  searching,
  success,
  error,
}

class AddressService extends ChangeNotifier {
  AddressStatus _status = AddressStatus.idle;

  AddressStatus get status => _status;

  void setStatus(AddressStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  Future<geo.Placemark?> fetchAddress({required double lat, required double lon}) async {
    setStatus(AddressStatus.searching);
    try {
      final List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        setStatus(AddressStatus.success);
        return placemarks.first;
      }
      return null;
    } catch (e) {
      setStatus(AddressStatus.error);
      debugPrint('AddressService: Failed to get address: $e');
      return null;
    }
  }
}
