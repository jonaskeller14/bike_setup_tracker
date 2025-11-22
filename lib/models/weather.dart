class Weather {
    DateTime currentDateTime;
    double? currentTemperature;
    int? currentWeatherCode;
    double? currentHumidity;
    double? currentWindSpeed;
    double? currentPrecipitation;

    Weather({
      required this.currentDateTime, 
      this.currentTemperature,
      this.currentWeatherCode,
      this.currentHumidity,
      this.currentWindSpeed,
      this.currentPrecipitation,      
    });

    Map<String, dynamic> toJson() => {
      'currentDateTime': currentDateTime.toIso8601String(),
      'currentTemperature': currentTemperature,
      'currentWeatherCode': currentWeatherCode,
      'currentHumidity': currentHumidity,
      'currentWindSpeed': currentWindSpeed,
      'currentPrecipitation': currentPrecipitation,
    };

    factory Weather.fromJson(Map<String, dynamic> json) {
      return Weather(
        currentDateTime: DateTime.parse(json['currentDateTime']),
        currentTemperature: json['currentTemperature'],
        currentWeatherCode: json['currentWeatherCode'],
        currentHumidity: json['currentHumidity'],
        currentWindSpeed: json['currentWindSpeed'],
        currentPrecipitation: json['currentPrecipitation'],
      );
    }
}