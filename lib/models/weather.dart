class Weather {
    double? currentTemperature;

    Weather({this.currentTemperature});

    Map<String, dynamic> toJson() => {
      'currentTemperature': currentTemperature,
    };

    factory Weather.fromJson(Map<String, dynamic> json) {
      return Weather(
        currentTemperature: json['currentTemperature']
      );
    }
}