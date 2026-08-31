import 'package:bike_setup_tracker/models/context/context_position.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContextPosition', () {
    final timestamp = DateTime.parse('2026-05-22T10:15:30.123Z');

    test('constructs and compares all value fields', () {
      final position = ContextPosition(
        latitude: 47.1,
        longitude: 8.2,
        altitude: 123.4,
        accuracy: 5.5,
        heading: 180,
        speed: 7.5,
        speedAccuracy: 0.8,
        timestamp: timestamp,
        isMock: false,
      );

      expect(
        position,
        ContextPosition(
          latitude: 47.1,
          longitude: 8.2,
          altitude: 123.4,
          accuracy: 5.5,
          heading: 180,
          speed: 7.5,
          speedAccuracy: 0.8,
          timestamp: timestamp,
          isMock: false,
        ),
      );
      expect(position.hashCode, equals(position.copyWith().hashCode));
    });

    test('copyWith preserves omitted fields and can clear nullable fields', () {
      final position = ContextPosition(
        latitude: 47.1,
        longitude: 8.2,
        altitude: 123.4,
        accuracy: 5.5,
        timestamp: timestamp,
        isMock: true,
      );

      expect(
        position.copyWith(latitude: null, altitude: 200, isMock: null),
        ContextPosition(
          latitude: null,
          longitude: 8.2,
          altitude: 200,
          accuracy: 5.5,
          timestamp: timestamp,
          isMock: null,
        ),
      );
    });

    test('change detection only considers latitude, longitude, and altitude', () {
      const original = ContextPosition(
        latitude: 47.1,
        longitude: 8.2,
        altitude: 123.4,
        accuracy: 5,
      );

      expect(
        ContextPosition.equal(original, original.copyWith(accuracy: 50)),
        isTrue,
      );
      expect(
        ContextPosition.equal(original, original.copyWith(altitude: 125)),
        isFalse,
      );
      expect(ContextPosition.equal(null, null), isTrue);
      expect(ContextPosition.equal(original, null), isFalse);
    });

    test('valid coordinate changes ignore altitude and reject unusable coordinates', () {
      const original = ContextPosition(latitude: 47.1, longitude: 8.2, altitude: 100);

      expect(
        ContextPosition.hasValidCoordinateChange(original, original.copyWith(altitude: 200)),
        isFalse,
      );
      expect(
        ContextPosition.hasValidCoordinateChange(original, original.copyWith(latitude: 47.2)),
        isTrue,
      );
      expect(
        ContextPosition.hasValidCoordinateChange(original, original.copyWith(longitude: null)),
        isFalse,
      );
      expect(
        ContextPosition.hasValidCoordinateChange(original, original.copyWith(latitude: double.nan)),
        isFalse,
      );
      expect(
        ContextPosition.hasValidCoordinateChange(original, original.copyWith(longitude: 181)),
        isFalse,
      );
    });

    test('converts altitude units', () {
      expect(ContextPosition.convertAltitudeToMeters(328.084, 'ft'), closeTo(100, 0.0001));
      expect(ContextPosition.convertAltitudeFromMeters(100, 'ft'), closeTo(328.084, 0.0001));
      expect(ContextPosition.convertAltitudeToMeters(100, 'm'), 100);
      expect(ContextPosition.convertAltitudeFromMeters(null, 'm'), isNull);
    });

    test('round-trips complete backup JSON with ISO-8601 timestamp', () {
      final position = ContextPosition(
        latitude: 47.1,
        longitude: 8.2,
        altitude: 123.4,
        accuracy: 5.5,
        heading: 180,
        speed: 7.5,
        speedAccuracy: 0.8,
        timestamp: timestamp,
        isMock: false,
      );

      final json = position.toJson();
      expect(json['time'], '2026-05-22T10:15:30.123Z');
      expect(ContextPosition.fromJson(json), position);
    });

    test('accepts partial legacy backup JSON and integer measurements', () {
      final position = ContextPosition.fromJson({
        'latitude': 47,
        'longitude': null,
        'time': '2026-05-22T10:15:30+02:00',
      });

      expect(position.latitude, 47.0);
      expect(position.longitude, isNull);
      expect(position.altitude, isNull);
      expect(position.accuracy, isNull);
      expect(position.isMock, isNull);
      expect(position.timestamp, DateTime.parse('2026-05-22T10:15:30+02:00'));
    });
  });
}
