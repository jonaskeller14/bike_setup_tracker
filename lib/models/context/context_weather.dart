import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:units_converter/units_converter.dart';

import '../../icons/weather_icons.dart';

enum Condition {
  dry('Dry'),
  moist('Moist'),
  wet('Wet'),
  muddy('Muddy');

  final String value;
  const Condition(this.value);

  IconData get iconData => switch (this) {
    dry => Icons.wb_sunny,
    moist => Icons.water_drop_outlined,
    wet => Icons.water_drop,
    muddy => Icons.water,
  };

  Color get color => switch (this) {
    dry => Colors.deepOrange,
    moist => Colors.amber,
    wet => Colors.lightBlue,
    muddy => Colors.blue,
  };
}

class ContextWeather {
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
  final bool conditionManuallySet;

  static const IconData currentTemperatureIconData = Icons.thermostat;
  static const IconData currentHumidityIconData = Icons.opacity;
  static const IconData currentWindSpeedIconData = Icons.air;
  static const IconData dayAccumulatedPrecipitationIconData = Icons.water_drop;
  static const IconData currentSoilMoisture0to7cmIconData = Icons.spa;

  ContextWeather({
    required this.currentDateTime, 
    this.currentTemperature,
    this.currentWeatherCode,
    this.currentHumidity,
    this.currentWindSpeed,
    this.currentPrecipitation,
    this.currentSoilMoisture0to7cm,
    this.dayAccumulatedPrecipitation,
    this.currentIsDay,
    this.conditionManuallySet = false,
    Condition? condition,
  }) : condition = condition ?? getConditionFromSoilMoisture0to7cm(currentSoilMoisture0to7cm);

  ContextWeather copyWith({
    DateTime? currentDateTime,
    Object? currentTemperature = const _Sentinel(),
    Object? currentWeatherCode = const _Sentinel(),
    Object? currentHumidity = const _Sentinel(),
    Object? currentWindSpeed = const _Sentinel(),
    Object? currentPrecipitation = const _Sentinel(),
    Object? currentSoilMoisture0to7cm = const _Sentinel(),
    Object? dayAccumulatedPrecipitation = const _Sentinel(),
    Object? currentIsDay = const _Sentinel(),
    Object? condition = const _Sentinel(),
    bool? conditionManuallySet,
  }) {
    return ContextWeather(
      currentDateTime: currentDateTime ?? this.currentDateTime,
      currentTemperature: currentTemperature is _Sentinel 
          ? this.currentTemperature 
          : (currentTemperature as double?),
      currentWeatherCode: currentWeatherCode is _Sentinel 
          ? this.currentWeatherCode 
          : (currentWeatherCode as int?),
      currentHumidity: currentHumidity is _Sentinel 
          ? this.currentHumidity 
          : (currentHumidity as double?),
      currentWindSpeed: currentWindSpeed is _Sentinel 
          ? this.currentWindSpeed 
          : (currentWindSpeed as double?),
      currentPrecipitation: currentPrecipitation is _Sentinel 
          ? this.currentPrecipitation 
          : (currentPrecipitation as double?),
      currentSoilMoisture0to7cm: currentSoilMoisture0to7cm is _Sentinel 
          ? this.currentSoilMoisture0to7cm 
          : (currentSoilMoisture0to7cm as double?),
      dayAccumulatedPrecipitation: dayAccumulatedPrecipitation is _Sentinel 
          ? this.dayAccumulatedPrecipitation 
          : (dayAccumulatedPrecipitation as double?),
      currentIsDay: currentIsDay is _Sentinel 
          ? this.currentIsDay 
          : (currentIsDay as bool?),
      condition: condition is _Sentinel
          ? this.condition
          : (condition as Condition?),
      conditionManuallySet: conditionManuallySet ?? this.conditionManuallySet,
    );
  }

  ContextWeather withoutCondition() => copyWith(condition: Condition.dry, conditionManuallySet: false);

  @override
  bool operator ==(Object other) {
    return identical(this, other) || 
        other is ContextWeather &&
        other.currentDateTime == currentDateTime &&
        other.currentTemperature == currentTemperature &&
        other.currentWeatherCode == currentWeatherCode &&
        other.currentHumidity == currentHumidity &&
        other.currentWindSpeed == currentWindSpeed &&
        other.currentPrecipitation == currentPrecipitation &&
        other.currentSoilMoisture0to7cm == currentSoilMoisture0to7cm &&
        other.dayAccumulatedPrecipitation == dayAccumulatedPrecipitation &&
        other.currentIsDay == currentIsDay &&
        other.condition == condition &&
        other.conditionManuallySet == conditionManuallySet;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentDateTime,
      currentTemperature,
      currentWeatherCode,
      currentHumidity,
      currentWindSpeed,
      currentPrecipitation,
      currentSoilMoisture0to7cm,
      dayAccumulatedPrecipitation,
      currentIsDay,
      condition,
      conditionManuallySet,
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
    'version': 1,
    'currentDateTime': currentDateTime.toIso8601String(),
    'currentTemperature': currentTemperature,
    'currentWeatherCode': currentWeatherCode,
    'currentHumidity': currentHumidity,
    'currentWindSpeed': currentWindSpeed,
    'currentPrecipitation': currentPrecipitation,
    'currentSoilMoisture0to7cm': currentSoilMoisture0to7cm,
    'dayAccumulatedPrecipitation': dayAccumulatedPrecipitation,
    'condition': condition.toString(),
    'conditionManuallySet': conditionManuallySet,
  };

  factory ContextWeather.fromJson(Map<String, dynamic> json) {
    final int? version = json["version"] as int?;
    switch (version) {
      case null || 1:
        return ContextWeather(
          currentDateTime: DateTime.parse(json['currentDateTime'] as String),
          currentTemperature: json['currentTemperature'] as double?,
          currentWeatherCode: json['currentWeatherCode'] as int?,
          currentHumidity: json['currentHumidity'] as double?,
          currentWindSpeed: json['currentWindSpeed'] as double?,
          currentPrecipitation: json['currentPrecipitation'] as double?,
          currentSoilMoisture0to7cm: json['currentSoilMoisture0to7cm'] as double?,
          dayAccumulatedPrecipitation: json['dayAccumulatedPrecipitation'] as double?,
          condition: Condition.values.firstWhereOrNull((e) => e.toString() == json['condition'] as String?),
          conditionManuallySet: json['conditionManuallySet'] as bool? ?? false,
        );
      default: throw Exception("Json Version $version of Weather incompatible.");
    }
  }

  static TEMPERATURE _temperatureUnitEnum(String unit) => switch (unit) {
    '°C' => TEMPERATURE.celsius,
    '°F' => TEMPERATURE.fahrenheit,
    'K' => TEMPERATURE.kelvin,
    _ => TEMPERATURE.celsius,
  };

  static SPEED _windSpeedUnitEnum(String unit) => switch (unit) {
    'km/h' => SPEED.kilometersPerHour,
    'm/s' => SPEED.metersPerSecond,
    'mph' => SPEED.milesPerHour,
    'kt' => SPEED.knots,
    _ => SPEED.kilometersPerHour,
  };

  static LENGTH _precipitationUnitEnum(String unit) => switch (unit) {
    'mm' => LENGTH.millimeters,
    'in' => LENGTH.inches,
    _ => LENGTH.millimeters,
  };

  static double? convertTemperatureToCelsius(double? temp, String currentUnit) {
    if (temp == null) return null;
    return temp.convertFromTo(_temperatureUnitEnum(currentUnit), TEMPERATURE.celsius);
  }

  static double? convertTemperatureFromCelsius(double? tempC, String targetUnit) {
    if (tempC == null) return null;
    return tempC.convertFromTo(TEMPERATURE.celsius, _temperatureUnitEnum(targetUnit));
  }

  static double? convertWindSpeedToKmh(double? speed, String currentUnit) {
    if (speed == null) return null;
    return speed.convertFromTo(_windSpeedUnitEnum(currentUnit), SPEED.kilometersPerHour);
  }

  static double? convertWindSpeedFromKmh(double? speedKmh, String targetUnit) {
    if (speedKmh == null) return null;
    return speedKmh.convertFromTo(SPEED.kilometersPerHour, _windSpeedUnitEnum(targetUnit));
  }

  static double? convertPrecipitationToMm(double? precip, String currentUnit) {
    if (precip == null) return null;
    return precip.convertFromTo(_precipitationUnitEnum(currentUnit), LENGTH.millimeters);
  }

  static double? convertPrecipitationFromMm(double? precipMm, String targetUnit) {
    if (precipMm == null) return null;
    return precipMm.convertFromTo(LENGTH.millimeters, _precipitationUnitEnum(targetUnit));
  }

  IconData getIconData() {
    return getStaticIconData(
      currentWeatherCode ?? -1, 
      isDay: currentIsDay ?? true,
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

  String? getWeatherCodeLabel() {
    return getStaticWeatherCodeLabel(currentWeatherCode);
  }

  static String? getStaticWeatherCodeLabel(int? code) {
    if (code == null) return null;
    switch (code) {
      // Clear and Cloudy
      case 0: return "Clear sky";
      case 1: return "Mainly clear";
      case 2: return "Partly cloudy";
      case 3: return "Overcast";

      // Fog
      case 45: return "Fog";
      case 48: return "Depositing rime fog";

      // Drizzle
      case 51: return "Light drizzle";
      case 53: return "Moderate drizzle";
      case 55: return "Dense drizzle";
      case 56: return "Light freezing drizzle";
      case 57: return "Dense freezing drizzle";

      // Rain
      case 61: return "Slight rain";
      case 63: return "Moderate rain";
      case 65: return "Heavy rain";
      case 66: return "Light freezing rain";
      case 67: return "Heavy freezing rain";

      // Snow
      case 71: return "Slight snow fall";
      case 73: return "Moderate snow fall";
      case 75: return "Heavy snow fall";
      case 77: return "Snow grains";

      // Showers
      case 80: return "Slight rain showers";
      case 81: return "Moderate rain showers";
      case 82: return "Violent rain showers";
      case 85: return "Slight snow showers";
      case 86: return "Heavy snow showers";

      // Thunderstorms
      case 95: return "Thunderstorm";
      case 96: return "Thunderstorm with slight hail";
      case 99: return "Thunderstorm with heavy hail";

      default: return "Unknown";
    }
  }
}

class _Sentinel {
  const _Sentinel();
}
