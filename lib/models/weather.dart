import 'package:flutter/material.dart';

class Weather {
    DateTime currentDateTime;
    double? currentTemperature;
    int? currentWeatherCode;
    double? currentHumidity;
    double? currentWindSpeed;
    double? currentPrecipitation;
    double? currentSoilMoisture0to7cm;
    double? dayAccumulatedPrecipitation;

    Weather({
      required this.currentDateTime, 
      this.currentTemperature,
      this.currentWeatherCode,
      this.currentHumidity,
      this.currentWindSpeed,
      this.currentPrecipitation,
      this.currentSoilMoisture0to7cm,
      this.dayAccumulatedPrecipitation,
    });

    Icon getConditionsIcon({double? size}) {
      if (currentSoilMoisture0to7cm == null) return Icon(Icons.question_mark_sharp, size: size);
      if (currentSoilMoisture0to7cm! < 0.1) {
        return Icon(Icons.wb_sunny, size: size, color: Colors.deepOrange);
      } else if (currentSoilMoisture0to7cm! < 0.2) {
        return Icon(Icons.water_drop_outlined, size: size, color: Colors.amber);
      } else if (currentSoilMoisture0to7cm! < 0.35) {
        return Icon(Icons.water_drop, size: size, color: Colors.lightBlue);
      } else {
        return Icon(Icons.water, size: size, color: Colors.blue);
      }
    }

    String? getConditionsLabel() {
      if (currentSoilMoisture0to7cm == null) return null;
      if (currentSoilMoisture0to7cm! < 0.1) {
        return "Dry";
      } else if (currentSoilMoisture0to7cm! < 0.2) {
        return "Moist";
      } else if (currentSoilMoisture0to7cm! < 0.35) {
        return "Wet";
      } else {
        return "Muddy";
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
      );
    }
}