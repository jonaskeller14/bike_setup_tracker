import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'dart:async';
import 'package:open_meteo/open_meteo.dart';
import '../models/weather.dart';

enum WeatherStatus {
  idle,
  searching,
  error,
  success,
}

class WeatherService {
  final historicalAPI = HistoricalApi(
    userAgent: "Bike Setup Tracker App v1.0",
    temperatureUnit: TemperatureUnit.celsius,
    windspeedUnit: WindspeedUnit.kmh,
    precipitationUnit: PrecipitationUnit.mm,
  );
  WeatherStatus status = WeatherStatus.idle;

  Future<Weather?> fetchWeather({required double lat, required double lon, required DateTime datetime, int counter = 1}) async {
    status = WeatherStatus.searching;
    try {
      if (datetime.isAfter(DateTime.now())) throw Exception("Date must be in the past.");

      final response = await historicalAPI.request(
        locations: {
          OpenMeteoLocation(
            latitude: lat,
            longitude: lon,
            startDate: DateTime(datetime.year, datetime.month, datetime.day),
            endDate: DateTime(datetime.year, datetime.month, datetime.day),
          )
        },
        hourly: {
          HistoricalHourly.temperature_2m, 
          HistoricalHourly.weather_code,
          HistoricalHourly.relative_humidity_2m,
          HistoricalHourly.wind_speed_10m,
          HistoricalHourly.precipitation,
          HistoricalHourly.soil_moisture_0_to_7cm,
          HistoricalHourly.is_day,
        },
      );
      final apiDatetime = datetime.copyWith(minute: 0, second: 0, millisecond: 0, microsecond: 0);
      final double? currentTemperature = response.segments[0].hourlyData[HistoricalHourly.temperature_2m]!.values[apiDatetime]?.toDouble();
      final int? currentWeatherCode = response.segments[0].hourlyData[HistoricalHourly.weather_code]!.values[apiDatetime]?.toInt();
      final double? currentHumidity = response.segments[0].hourlyData[HistoricalHourly.relative_humidity_2m]!.values[apiDatetime]?.toDouble();
      final double? currentWindSpeed = response.segments[0].hourlyData[HistoricalHourly.wind_speed_10m]!.values[apiDatetime]?.toDouble();
      final double? currentPrecipitation = response.segments[0].hourlyData[HistoricalHourly.precipitation]!.values[apiDatetime]?.toDouble();
      final double dayAccumulatedPrecipitation = response.segments[0].hourlyData[HistoricalHourly.precipitation]!.values.values
          .map((item) => item.toDouble()) // Iterable<double>
          .fold(0.0, (accumulator, element) => accumulator + element); // Start at 0.0 and sum up
      final double? currentSoilMoisture0to7cm = response.segments[0].hourlyData[HistoricalHourly.soil_moisture_0_to_7cm]!.values[apiDatetime]?.toDouble();
      final int? currentIsDayInt = response.segments[0].hourlyData[HistoricalHourly.is_day]!.values[apiDatetime]?.toInt();
      final bool? currentIsDay = currentIsDayInt == null ? null : (currentIsDayInt == 1);

      status = WeatherStatus.success;
      return Weather(
        currentDateTime: apiDatetime, 
        currentTemperature: currentTemperature,
        currentWeatherCode: currentWeatherCode,
        currentHumidity: currentHumidity,
        currentWindSpeed: currentWindSpeed,
        currentPrecipitation: currentPrecipitation,
        currentSoilMoisture0to7cm: currentSoilMoisture0to7cm,
        dayAccumulatedPrecipitation: dayAccumulatedPrecipitation,
        currentIsDay: currentIsDay,
      );
    } on ClientException catch (e) {
      debugPrint("WeatherService: Network Error (No Internet): $e");
      status = WeatherStatus.error;
      return null;
    } on SocketException catch (e) {
      debugPrint("WeatherService: Network Error (No Internet): $e");
      status = WeatherStatus.error;
      return null;
    } catch (e) {
      debugPrint("WeatherService: Exception caught: $e");
      status = WeatherStatus.error;

      if (counter <= 2) {
        status = WeatherStatus.searching;
        debugPrint("WeatherService Error --> Trying again after 10s.");
        await Future.delayed(const Duration(seconds: 10));
        return fetchWeather(lat: lat, lon: lon, datetime: datetime, counter: counter + 1);
      }

      return null;
    }
  }
}
