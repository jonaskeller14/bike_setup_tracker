import 'package:flutter/material.dart';
import 'package:open_meteo/open_meteo.dart';

enum ElevationStatus {
  idle,
  searching,
  error,
  success,
}

class ElevationService {
  ElevationStatus status = ElevationStatus.idle;

  Future<double?> fetchElevation({required double lat, required double lon}) async {
    status = ElevationStatus.searching;
    try {
      final result = await ElevationApi(userAgent: "Bike Setup Tracker App v1.0").requestJson(latitudes: {lat}, longitudes: {lon});

      if (result.containsKey('error') && result['error'] == true) {
        final String reason = result['reason'] as String? ?? 'Unknown API Error';
        debugPrint('Open-Meteo API Error: $reason');
        throw Exception('API Request Failed: $reason'); 
      }

      if (result.containsKey('elevation')) {
        final elevationData = result['elevation'];
        if (elevationData is List && elevationData.isNotEmpty) {
          final newElevation = elevationData.first is double ? elevationData.first as double : null;
          status = ElevationStatus.success;
          return newElevation;
        }
      }
      status = ElevationStatus.error;
      return null;
    } catch (e) {
      status = ElevationStatus.error;
      return null;
    }
  }
}