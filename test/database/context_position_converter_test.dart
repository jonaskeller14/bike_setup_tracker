import 'dart:convert';

import 'package:bike_setup_tracker/database/converters/context_position_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const converter = ContextPositionConverter();

  group('ContextPositionConverter', () {
    test('reads legacy version-null SQL JSON with missing optional fields', () {
      final position = converter.fromSql(
        jsonEncode({
          'latitude': 47,
          'longitude': 8.2,
          'altitude': null,
          'time': 1779444930123,
        }),
      );

      expect(position.latitude, 47.0);
      expect(position.longitude, 8.2);
      expect(position.altitude, isNull);
      expect(position.accuracy, isNull);
      expect(position.isMock, isNull);
      expect(
        position.timestamp,
        DateTime.fromMillisecondsSinceEpoch(1779444930123, isUtc: true),
      );
    });

    test('round-trips all version-1 fields', () {
      final position = ContextPosition(
        latitude: 47.1,
        longitude: 8.2,
        altitude: 123.4,
        accuracy: 5.5,
        heading: 180,
        speed: 7.5,
        speedAccuracy: 0.8,
        timestamp: DateTime.fromMillisecondsSinceEpoch(1779444930123, isUtc: true),
        isMock: false,
      );

      final sql = converter.toSql(position);
      final json = jsonDecode(sql) as Map<String, dynamic>;

      expect(json['version'], 1);
      expect(json['time'], 1779444930123);
      expect(converter.fromSql(sql), position);
    });

    test('accepts floating-point numeric timestamps and missing isMock', () {
      final position = converter.fromSql(
        jsonEncode({
          'version': 1,
          'time': 1779444930123.0,
        }),
      );

      expect(
        position.timestamp,
        DateTime.fromMillisecondsSinceEpoch(1779444930123, isUtc: true),
      );
      expect(position.isMock, isNull);
    });

    test('preserves nullable measurements', () {
      final position = converter.fromSql(converter.toSql(const ContextPosition()));

      expect(position, const ContextPosition());
    });

    test('rejects unknown future versions', () {
      expect(
        () => converter.fromSql(jsonEncode({'version': 2})),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Json Version 2 of ContextPosition incompatible.'),
          ),
        ),
      );
    });
  });
}
