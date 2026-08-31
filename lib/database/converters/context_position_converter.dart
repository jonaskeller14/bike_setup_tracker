import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/context/context_position.dart';

export '../../models/context/context_position.dart';

class ContextPositionConverter extends TypeConverter<ContextPosition, String> {
  const ContextPositionConverter();

  @override
  ContextPosition fromSql(String fromDb) {
    final jsonMap = json.decode(fromDb) as Map<String, dynamic>;
    final int? version = jsonMap['version'] as int?;

    switch (version) {
      case null || 1:
        return ContextPosition(
          latitude: _toDouble(jsonMap['latitude']),
          longitude: _toDouble(jsonMap['longitude']),
          accuracy: _toDouble(jsonMap['accuracy']),
          altitude: _toDouble(jsonMap['altitude']),
          speed: _toDouble(jsonMap['speed']),
          speedAccuracy: _toDouble(jsonMap['speedAccuracy']),
          heading: _toDouble(jsonMap['heading']),
          timestamp: _fromMilliseconds(jsonMap['time']),
          isMock: jsonMap['isMock'] as bool?,
        );
      default:
        throw Exception(
          'Json Version $version of ContextPosition incompatible.',
        );
    }
  }

  @override
  String toSql(ContextPosition value) {
    return json.encode({
      'version': 1,
      'latitude': value.latitude,
      'longitude': value.longitude,
      'accuracy': value.accuracy,
      'altitude': value.altitude,
      'speed': value.speed,
      'speedAccuracy': value.speedAccuracy,
      'heading': value.heading,
      'time': value.timestamp?.millisecondsSinceEpoch,
      'isMock': value.isMock,
    });
  }

  static double? _toDouble(Object? value) => (value as num?)?.toDouble();

  static DateTime? _fromMilliseconds(Object? value) {
    final milliseconds = value as num?;
    return milliseconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            milliseconds.toInt(),
            isUtc: true,
          );
  }
}
