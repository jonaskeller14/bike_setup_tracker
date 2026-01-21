import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:weather_icons/weather_icons.dart';

enum Condition {
  dry('Dry'),
  moist('Moist'),
  wet('Wet'),
  muddy('Muddy');

  final String value;
  const Condition(this.value);

  IconData getIconData() {
    switch (this) {
      case dry: return Icons.wb_sunny;
      case moist: return Icons.water_drop_outlined;
      case wet: return Icons.water_drop;
      case muddy: return Icons.water;
    }
  }

  Color getColor() {
    switch (this) {
      case dry: return Colors.deepOrange;
      case moist: return Colors.amber;
      case wet: return Colors.lightBlue;
      case muddy: return Colors.blue;
    }  
  }
}

class Weather {
  final DateTime currentDateTime;
  final double? currentTemperature;
  final int? currentWeatherCode;
  final double? currentHumidity;
  final double? currentWindSpeed;
  final double? currentPrecipitation;
  final double? currentSoilMoisture0to7cm;
  final double? dayAccumulatedPrecipitation;
  final bool? currentIsDay;

  final Condition? condition;

  static const IconData currentTemperatureIconData = Icons.thermostat;
  static const IconData currentHumidityIconData = Icons.opacity;
  static const IconData currentWindSpeedIconData = Icons.air;
  static const IconData dayAccumulatedPrecipitationIconData = Icons.water_drop;
  static const IconData currentSoilMoisture0to7cmIconData = Icons.spa;

  Weather({
    required this.currentDateTime, 
    this.currentTemperature,
    this.currentWeatherCode,
    this.currentHumidity,
    this.currentWindSpeed,
    this.currentPrecipitation,
    this.currentSoilMoisture0to7cm,
    this.dayAccumulatedPrecipitation,
    this.currentIsDay,
    Condition? condition,
  }) : condition = condition ?? getConditionFromSoilMoisture0to7cm(currentSoilMoisture0to7cm);

  Weather copyWith({
    DateTime? currentDateTime,
    double? currentTemperature,
    int? currentWeatherCode,
    double? currentHumidity,
    double? currentWindSpeed,
    double? currentPrecipitation,
    double? currentSoilMoisture0to7cm,
    double? dayAccumulatedPrecipitation,
    bool? currentIsDay,
    Condition? condition,
  }) {
    return Weather(
      currentDateTime: currentDateTime ?? this.currentDateTime,
      currentTemperature: currentTemperature ?? this.currentTemperature,
      currentWeatherCode: currentWeatherCode ?? this.currentWeatherCode,
      currentHumidity: currentHumidity ?? this.currentHumidity,
      currentWindSpeed: currentWindSpeed ?? this.currentWindSpeed,
      currentPrecipitation: currentPrecipitation ?? this.currentPrecipitation,
      currentSoilMoisture0to7cm: currentSoilMoisture0to7cm ?? this.currentSoilMoisture0to7cm,
      dayAccumulatedPrecipitation: dayAccumulatedPrecipitation ?? this.dayAccumulatedPrecipitation,
      currentIsDay: currentIsDay ?? this.currentIsDay,
      condition: condition ?? this.condition,
    );
  }

  static Condition? getConditionFromSoilMoisture0to7cm(double? currentSoilMoisture0to7cm) {
    if (currentSoilMoisture0to7cm == null) return null;
    if (currentSoilMoisture0to7cm < 0.1) {
      return Condition.dry;
    } else if (currentSoilMoisture0to7cm < 0.2) {
      return Condition.moist;
    } else if (currentSoilMoisture0to7cm < 0.35) {
      return Condition.wet;
    } else {
      return Condition.muddy;
    }
  }

  Color? getTemperatureColor() {
    if (currentTemperature == null) return null;
    const minTemp = 0;
    const maxTemp = 30;
    return Color.lerp(Colors.blue, Colors.red, (currentTemperature! - minTemp)/(maxTemp - minTemp));
  }

  Map<String, dynamic> toJson() => {
    'currentDateTime': currentDateTime.toIso8601String(),
    'currentTemperature': currentTemperature,
    'currentWeatherCode': currentWeatherCode,
    'currentHumidity': currentHumidity,
    'currentWindSpeed': currentWindSpeed,
    'currentPrecipitation': currentPrecipitation,
    'currentSoilMoisture0to7cm': currentSoilMoisture0to7cm,
    'dayAccumulatedPrecipitation': dayAccumulatedPrecipitation,
    'condition': condition.toString(),
  };

  factory Weather.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"];
    switch (version) {
      case null:
        return Weather(
          currentDateTime: DateTime.parse(json['currentDateTime']),
          currentTemperature: json['currentTemperature'],
          currentWeatherCode: json['currentWeatherCode'],
          currentHumidity: json['currentHumidity'],
          currentWindSpeed: json['currentWindSpeed'],
          currentPrecipitation: json['currentPrecipitation'],
          currentSoilMoisture0to7cm: json['currentSoilMoisture0to7cm'],
          dayAccumulatedPrecipitation: json['dayAccumulatedPrecipitation'],
          condition: Condition.values.firstWhereOrNull((e) => e.toString() == json['condition']),
        );
      default: throw Exception("Json Version $version of Weather incompatible.");
    }
  }

  static double convertTemperatureToCelsius(double temp, String currentUnit) {
    switch (currentUnit) {
      case '°C':
        return temp;
      case '°F':
        return (temp - 32) * 5 / 9;
      case 'K':
        return temp - 273.15;
      default:
        return temp;
    }
  }

  static double convertTemperatureFromCelsius(double tempC, String targetUnit) {
    switch (targetUnit) {
      case '°C':
        return tempC;
      case '°F':
        return (tempC * 9 / 5) + 32;
      case 'K':
        return tempC + 273.15;
      default:
        return tempC;
    }
  }

  static double convertWindSpeedToKmh(double speed, String currentUnit) {
    const double msToKmh = 3.6;          // m/s * 3.6 = km/h
    const double mphToKmh = 1.60934;     // mph * 1.60934 = km/h
    const double ktToKmh = 1.852;        // kt * 1.852 = km/h

    switch (currentUnit) {
      case 'km/h':
        return speed;
      case 'm/s':
        return speed * msToKmh;
      case 'mph':
        return speed * mphToKmh;
      case 'kt':
        return speed * ktToKmh;
      default:
        return speed;
    }
  }

  static double convertWindSpeedFromKmh(double speedKmh, String targetUnit) {
    const double kmhToMs = 1 / 3.6;          // 1 km/h ≈ 0.27778 m/s
    const double kmhToMph = 1 / 1.60934;     // 1 km/h ≈ 0.62137 mph
    const double kmhToKt = 1 / 1.852;        // 1 km/h ≈ 0.53996 knots

    switch (targetUnit) {
      case 'km/h':
        return speedKmh;
      case 'm/s':
        return speedKmh * kmhToMs;
      case 'mph':
        return speedKmh * kmhToMph;
      case 'kt':
        return speedKmh * kmhToKt;
      default:
        return speedKmh;
    }
  }

  static double convertPrecipitationToMm(double precip, String currentUnit) {
    const double inToMm = 1 / 0.0393701;

    switch (currentUnit) {
      case 'mm':
        return precip;
      case 'in':
        return precip * inToMm;
      default:
        return precip;
    }
  }

  static double convertPrecipitationFromMm(double precipMm, String targetUnit) {
    const double mmToIn = 0.0393701;

    switch (targetUnit) {
      case 'mm':
        return precipMm;
      case 'in':
        return precipMm * mmToIn;
      default:
        return precipMm;
    }
  }

  IconData getIconData() {
    return getStaticIconData(
      currentWeatherCode ?? -1 , 
      isDay: currentIsDay ?? true
    );
  }

  static IconData getStaticIconData(int code, {bool isDay = true}) {
    switch (code) {
      // 0: Clear sky
      case 0:
        return isDay ? WeatherIcons.day_sunny : WeatherIcons.night_clear;

      // 1: Mainly clear
      case 1:
        return isDay ? WeatherIcons.day_sunny_overcast : WeatherIcons.night_alt_partly_cloudy;
      
      // 2: Partly cloudy
      case 2:
        return isDay ? WeatherIcons.day_cloudy : WeatherIcons.night_alt_cloudy;
      
      // 3: Overcast
      case 3:
        return WeatherIcons.cloudy;

      // 45, 48: Fog and depositing rime fog
      case 45:
      case 48:
        return isDay ? WeatherIcons.day_fog : WeatherIcons.night_fog;

      // 51, 53, 55: Drizzle: Light, moderate, and dense intensity
      case 51:
      case 53:
      case 55:
        return isDay ? WeatherIcons.day_sprinkle : WeatherIcons.night_sprinkle;

      // 56, 57: Freezing Drizzle: Light and dense intensity
      case 56:
      case 57:
        return isDay ? WeatherIcons.day_rain_mix : WeatherIcons.night_alt_rain_mix;

      // 61, 63, 65: Rain: Slight, moderate and heavy intensity
      case 61:
      case 63:
      case 65:
        return isDay ? WeatherIcons.day_rain : WeatherIcons.night_alt_rain;

      // 66, 67: Freezing Rain: Light and heavy intensity
      case 66:
      case 67:
        return isDay ? WeatherIcons.day_sleet : WeatherIcons.night_alt_sleet;

      // 71, 73, 75: Snow fall: Slight, moderate, and heavy intensity
      case 71:
      case 73:
      case 75:
        return isDay ? WeatherIcons.day_snow : WeatherIcons.night_alt_snow;

      // 77: Snow grains
      case 77:
        return isDay ? WeatherIcons.day_snow : WeatherIcons.night_alt_snow;

      // 80, 81, 82: Rain showers: Slight, moderate, and violent
      case 80:
      case 81:
      case 82:
        return isDay ? WeatherIcons.day_showers : WeatherIcons.night_alt_showers;

      // 85, 86: Snow showers slight and heavy
      case 85:
      case 86:
        return isDay ? WeatherIcons.day_snow_wind : WeatherIcons.night_alt_snow_wind;

      // 95: Thunderstorm: Slight or moderate
      case 95:
        return isDay ? WeatherIcons.day_thunderstorm : WeatherIcons.night_alt_thunderstorm;

      // 96, 99: Thunderstorm with slight and heavy hail
      case 96:
      case 99:
        return isDay ? WeatherIcons.day_storm_showers : WeatherIcons.night_alt_storm_showers;

      // Fallback
      default:
        return WeatherIcons.na;
    }
  }
}
