import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  Future<double?> fetchTemperature(double lat, double lon, {int counter = 1}) async {
    final url = Uri.parse(
      "https://api.open-meteo.com/v1/forecast"
      "?latitude=$lat"
      "&longitude=$lon"
      "&current=temperature_2m"
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final temp = data["current"]?["temperature_2m"];
      if (temp is num) return temp.toDouble();
      return null;

    } else if (response.statusCode == 429 && counter <= 2) {
      debugPrint("Error: Weather API limit reached. Trying again after 10s.");
      await Future.delayed(const Duration(seconds: 10));
      return fetchTemperature(lat, lon, counter: counter + 1);
    } else {
      debugPrint("Weather fetch failed: ${response.statusCode}");
      return null;
    }
  }
}
