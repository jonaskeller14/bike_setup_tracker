import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class WeatherService {
  Future<Weather?> fetchWeather(double lat, double lon, {DateTime? datetime, int counter = 1}) async {
    if (datetime != null && datetime.isAfter(DateTime.now())) return null;
    final bool isHistorical = datetime != null;
    final String authority = isHistorical ? "archive-api.open-meteo.com" : "api.open-meteo.com";
    final String path = isHistorical ? "/v1/archive" : "/v1/forecast";

    final Map<String, dynamic> queryParams = {
      'latitude': '$lat',
      'longitude': '$lon',
    };

    if (isHistorical) {
      final String dateStr = datetime.toIso8601String().split('T')[0];  // Format date to YYYY-MM-DD
      queryParams['start_date'] = dateStr;
      queryParams['end_date'] = dateStr;
      queryParams['hourly'] = 'temperature_2m';
    } else {
      queryParams['current'] = 'temperature_2m';
    }

    final url = Uri.https(authority, path, queryParams);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        double? resultTemp;

        if (isHistorical) {
          final List<dynamic>? temps = data['hourly']?['temperature_2m'];
          if (temps != null && temps.isNotEmpty) {
            final int hourIndex = datetime.hour.clamp(0, 23);  // Cap the hour between 0 and 23 to prevent index errors
            resultTemp = (temps[hourIndex] as num).toDouble();
          }
        } else {
          final temp = data["current"]?["temperature_2m"];
          if (temp is num) resultTemp = temp.toDouble();
        }

        if (resultTemp != null) {
          return Weather(currentTemperature: resultTemp);
        }
        return null;

      } else if (response.statusCode == 429 && counter <= 2) {
        debugPrint("Error: Weather API limit reached. Trying again after 10s.");
        await Future.delayed(const Duration(seconds: 10));
        return fetchWeather(lat, lon, datetime: datetime, counter: counter + 1);  // Pass the date back into the recursive call
      } else {
        debugPrint("Weather fetch failed: ${response.statusCode} | ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Exception caught: $e");
      return null;
    }
  }
}
