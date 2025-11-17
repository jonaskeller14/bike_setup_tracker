import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey;

  WeatherService({required this.apiKey});

  Future<double?> fetchTemperature(double lat, double lon, {int counter = 1}) async {
    final url = Uri.parse("https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['main']['temp']?.toDouble();
    } else if (response.statusCode == 429 && counter <= 2) {
      debugPrint("Error: OWM API limit reached. Trying again after 10s.");
      await Future.delayed(Duration(seconds: 10));
      return fetchTemperature(lat, lon, counter: counter + 1);
    } else {
      return null;
    }
  }
}
