import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

enum Condition {
  dry('Dry'),
  moist('Moist'),
  wet('Wet'),
  muddy('Muddy');

  final String value;
  const Condition(this.value);
  Icon getConditionsIcon({double? size}) {
    switch (this) {
      case Condition.dry:
        return Icon(Icons.wb_sunny, size: size, color: Colors.deepOrange);
      case Condition.moist:
        return Icon(Icons.water_drop_outlined, size: size, color: Colors.amber);
      case Condition.wet:
        return Icon(Icons.water_drop, size: size, color: Colors.lightBlue);
      case Condition.muddy:
        return Icon(Icons.water, size: size, color: Colors.blue);
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

  final Condition? condition;

  Weather({
    required this.currentDateTime, 
    this.currentTemperature,
    this.currentWeatherCode,
    this.currentHumidity,
    this.currentWindSpeed,
    this.currentPrecipitation,
    this.currentSoilMoisture0to7cm,
    this.dayAccumulatedPrecipitation,
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
      condition: condition ?? this.condition,
    );
  }

  Icon getConditionsIcon({double? size}) {
    if (condition == null) return Icon(Icons.question_mark_sharp, size: size);
    return condition!.getConditionsIcon(size: size);
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
}