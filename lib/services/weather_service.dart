import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:open_meteo/open_meteo.dart';
import '../models/weather.dart';

sealed class WeatherStatus {
  const WeatherStatus();
}

class WeatherIdle extends WeatherStatus {
  const WeatherIdle();
}

class WeatherSearching extends WeatherStatus {
  const WeatherSearching();
}

class WeatherSuccess extends WeatherStatus {
  const WeatherSuccess();
}

class WeatherError extends WeatherStatus {
  final String message;
  const WeatherError(this.message);
}

class WeatherService extends ChangeNotifier {
  final historicalAPI = const HistoricalApi(
    userAgent: "Bike Setup Tracker App v1.0",
    temperatureUnit: TemperatureUnit.celsius,
    windspeedUnit: WindspeedUnit.kmh,
    precipitationUnit: PrecipitationUnit.mm,
  );
  
  static const int _maxRequestsPerHour = 12;
  final List<DateTime> _requestTimestamps = [];

  WeatherStatus _status = const WeatherIdle();

  WeatherStatus get status => _status;
  String? get errorMessage {
    final s = _status;
    return s is WeatherError ? s.message : null;
  }

  void setStatus(WeatherStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  void _checkRateLimit() {
    final now = DateTime.now();
    _requestTimestamps.removeWhere((timestamp) => now.difference(timestamp).inHours >= 1);

    if (_requestTimestamps.length >= _maxRequestsPerHour) {
      final resetTime = _requestTimestamps.first.add(const Duration(hours: 1));
      final resetTimeString = "${resetTime.hour.toString().padLeft(2, '0')}:${resetTime.minute.toString().padLeft(2, '0')}";
      throw Exception("Rate limit exceeded ($_maxRequestsPerHour/h). Try again after $resetTimeString");
    }
    _requestTimestamps.add(now);
  }

  Future<Weather?> fetchWeather({required double lat, required double lon, required DateTime datetime, int counter = 1}) async {
    setStatus(const WeatherSearching());
    try {
      _checkRateLimit();

      if (datetime.isUtc) {
        debugPrint("WARNING: fetchWeather() is called with UTC Time");
        datetime = datetime.toLocal();
      }

      if (datetime.isAfter(DateTime.now())) throw Exception("Date must be in the past.");

      final response = await historicalAPI.request(
        locations: {
          OpenMeteoLocation(
            latitude: lat,
            longitude: lon,
            startDate: datetime,
            endDate: datetime,
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
      final apiDatetime = datetime.copyWith(minute: 0, second: 0, millisecond: 0, microsecond: 0, isUtc: false);
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

      setStatus(const WeatherSuccess());
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
    } on ClientException {
      setStatus(const WeatherError("Network Error (No Internet)."));
      return null;
    } on SocketException {
      setStatus(const WeatherError("Network Error (No Internet)."));
      return null;
    } catch (e) {
      // Preserve the rate-limit message (thrown with the reset time); any other
      // failure gets a generic message.
      final isRateLimit = e.toString().contains("Rate limit exceeded");
      final message = isRateLimit
          ? e.toString().replaceFirst("Exception: ", "")
          : "Error occurred during weather update.";
      setStatus(WeatherError(message));

      if (counter <= 2 && !isRateLimit) {
        setStatus(const WeatherSearching());
        // debugPrint("WeatherService Error --> Trying again after 10s.");
        await Future.delayed(const Duration(seconds: 10));
        return fetchWeather(lat: lat, lon: lon, datetime: datetime, counter: counter + 1);
      } else {
        return null;
      }
    }
  }
}
