import 'dart:convert';
import 'package:drift/drift.dart';
import '../../models/weather.dart';

export '../../models/weather.dart';

class WeatherConverter extends TypeConverter<Weather, String> {
  const WeatherConverter();

  @override
  Weather fromSql(String fromDb) {
    return Weather.fromJson(json.decode(fromDb));
  }

  @override
  String toSql(Weather value) {
    return json.encode(value.toJson());
  }
}
