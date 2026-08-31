import 'package:flutter/material.dart';
import 'package:open_meteo/open_meteo.dart';

import '../models/context/context_position.dart';

enum ElevationStatus {
  idle,
  searching,
  error,
  success,
}

class ElevationService extends ChangeNotifier {
  final elevationAPI = const ElevationApi(userAgent: "Bike Setup Tracker App v1.0");
  ElevationStatus _status = ElevationStatus.idle;

  ElevationStatus get status => _status;

  void setStatus(ElevationStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  Future<double?> fetchElevation({required double lat, required double lon}) async {
    setStatus(ElevationStatus.searching);
    try {
      final result = await elevationAPI.requestJson(latitudes: {lat}, longitudes: {lon});

      if (result.containsKey('error') && result['error'] == true) {
        final String reason = result['reason'] as String? ?? 'Unknown API Error';
        debugPrint('Open-Meteo API Error: $reason');
        throw Exception('API Request Failed: $reason');
      }

      if (result.containsKey('elevation')) {
        final elevationData = result['elevation'];
        if (elevationData is List && elevationData.isNotEmpty) {
          final newElevation = (elevationData.first as num?)?.toDouble();
          setStatus(ElevationStatus.success);
          return newElevation;
        }
      }
      setStatus(ElevationStatus.error);
      return null;
    } catch (e) {
      setStatus(ElevationStatus.error);
      return null;
    }
  }

  Future<ContextPosition> addMissingElevation(ContextPosition position) async {
    final latitude = position.latitude;
    final longitude = position.longitude;
    if (position.altitude != null || latitude == null || longitude == null) return position;

    final altitude = await fetchElevation(lat: latitude, lon: longitude);
    return altitude == null ? position : position.copyWith(altitude: altitude);
  }
}
