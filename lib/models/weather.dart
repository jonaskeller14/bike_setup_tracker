class Weather {
    DateTime currentDateTime;
    double? currentTemperature;
    int? currentWeatherCode;
    double? currentHumidity;
    double? currentWindSpeed;
    double? currentPrecipitation;
    double? currentSoilMoisture0to7cm;

    Weather({
      required this.currentDateTime, 
      this.currentTemperature,
      this.currentWeatherCode,
      this.currentHumidity,
      this.currentWindSpeed,
      this.currentPrecipitation,
      this.currentSoilMoisture0to7cm,
    });

    Map<String, dynamic> toJson() => {
      'currentDateTime': currentDateTime.toIso8601String(),
      'currentTemperature': currentTemperature,
      'currentWeatherCode': currentWeatherCode,
      'currentHumidity': currentHumidity,
      'currentWindSpeed': currentWindSpeed,
      'currentPrecipitation': currentPrecipitation,
      'currentSoilMoisture0to7cm': currentSoilMoisture0to7cm,
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
      );
    }
}