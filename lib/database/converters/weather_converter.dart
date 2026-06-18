import 'dart:convert';
import 'package:drift/drift.dart';
import '../../models/context/context_weather.dart';

export '../../models/context/context_weather.dart';

class WeatherConverter extends TypeConverter<ContextWeather, String> {
  const WeatherConverter();

  @override
  ContextWeather fromSql(String fromDb) {
    return ContextWeather.fromJson(json.decode(fromDb));
  }

  @override
  String toSql(ContextWeather value) {
    return json.encode(value.toJson());
  }
}
