import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

enum WeatherStatus {
  idle,
  error,
  success,
}

class WeatherService {
  WeatherStatus status = WeatherStatus.idle;

  Future<Weather?> fetchWeather({required double lat, required double lon, required DateTime datetime, int counter = 1}) async {
    if (datetime.isAfter(DateTime.now())) return null;
    final String authority = "archive-api.open-meteo.com";
    final String path = "/v1/archive";

    final Map<String, dynamic> queryParams = {
      'latitude': '$lat',
      'longitude': '$lon',
    };

    final String dateStr = datetime.toIso8601String().split('T')[0];  // Format date to YYYY-MM-DD
    queryParams['start_date'] = dateStr;
    queryParams['end_date'] = dateStr;
    queryParams['hourly'] = 'temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m,precipitation,soil_moisture_0_to_7cm';

    final url = Uri.https(authority, path, queryParams);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        final hourlyData = data['hourly'];
        if (hourlyData == null) return null;

        final int hourIndex = datetime.hour.clamp(0, 23);  // Cap the hour between 0 and 23 to prevent index errors

        final List<dynamic>? times = hourlyData['time'];
        final String? timeString = (times != null && times.length > hourIndex)
            ? times[hourIndex] as String
            : null;
        if (timeString == null) return null; 
        final DateTime apiDatetime = DateTime.parse(timeString);

        // 🌡️ Temperature
        final List<dynamic>? temps = hourlyData['temperature_2m'];
        double? currentTemperature = (temps != null && temps.isNotEmpty) 
            ? (temps[hourIndex] as num).toDouble()
            : null;
        
        // ☁️ Weather Code
        final List<dynamic>? codes = hourlyData['weather_code'];
        final int? currentWeatherCode = (codes != null && codes.length > hourIndex)
            ? (codes[hourIndex] as num).toInt()
            : null;

        // 💧 Relative Humidity
        final List<dynamic>? humidity = hourlyData['relative_humidity_2m'];
        final double? currentHumidity = (humidity != null && humidity.length > hourIndex)
            ? (humidity[hourIndex] as num).toDouble()
            : null;

        // 💨 Wind Speed
        final List<dynamic>? windSpeed = hourlyData['wind_speed_10m'];
        final double? currentWindSpeed = (windSpeed != null && windSpeed.length > hourIndex)
            ? (windSpeed[hourIndex] as num).toDouble()
            : null;
            
        // 🌧️ Precipitation
        final List<dynamic>? precipitation = hourlyData['precipitation'];
        final double? currentPrecipitation = (precipitation != null && precipitation.length > hourIndex)
            ? (precipitation[hourIndex] as num).toDouble()
            : null;
        double? dayAccumulatedPrecipitation = 0.0;
        if (precipitation != null && precipitation.length > hourIndex) {
          for (int i = 0; i <= hourIndex; i++) {
              final precipitationValue = precipitation[i];
              if (precipitationValue is num && dayAccumulatedPrecipitation != null) {
                  dayAccumulatedPrecipitation += precipitationValue.toDouble();
              } else {
                  dayAccumulatedPrecipitation = null;
                  break;
              }
          }
        }
        
        // 🌱 Soil Moisture
        final List<dynamic>? soilMoisture0to7cm = hourlyData['soil_moisture_0_to_7cm'];
        final double? currentSoilMoisture0to7cm = (soilMoisture0to7cm != null && soilMoisture0to7cm.length > hourIndex)
            ? (soilMoisture0to7cm[hourIndex] as num).toDouble()
            : null;

        return Weather(
          currentDateTime: apiDatetime, 
          currentTemperature: currentTemperature,
          currentWeatherCode: currentWeatherCode,
          currentHumidity: currentHumidity,
          currentWindSpeed: currentWindSpeed,
          currentPrecipitation: currentPrecipitation,
          currentSoilMoisture0to7cm: currentSoilMoisture0to7cm,
          dayAccumulatedPrecipitation: dayAccumulatedPrecipitation,
        );

      } else if (response.statusCode == 429 && counter <= 2) {
        debugPrint("Error: Weather API limit reached. Trying again after 10s.");
        await Future.delayed(const Duration(seconds: 10));
        return fetchWeather(lat: lat, lon: lon, datetime: datetime, counter: counter + 1);  // Pass the date back into the recursive call
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
