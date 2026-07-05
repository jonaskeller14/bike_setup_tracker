import 'package:bike_setup_tracker/models/context/context_weather.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit-conversion coverage for [ContextWeather]. The stored unit strings
/// (`°C`, `mph`, `in`, …) are mapped onto the units_converter package; these
/// tests pin the string mapping, the null-passthrough, and round-tripping
/// through each base unit (celsius / km-h / mm).
void main() {
  group('ContextWeather — temperature conversion', () {
    test('null input returns null', () {
      expect(ContextWeather.convertTemperatureToCelsius(null, '°F'), isNull);
      expect(ContextWeather.convertTemperatureFromCelsius(null, 'K'), isNull);
    });

    test('celsius is identity', () {
      expect(ContextWeather.convertTemperatureToCelsius(20, '°C'), closeTo(20, 1e-9));
      expect(ContextWeather.convertTemperatureFromCelsius(20, '°C'), closeTo(20, 1e-9));
    });

    test('fahrenheit <-> celsius', () {
      expect(ContextWeather.convertTemperatureToCelsius(32, '°F'), closeTo(0, 1e-9));
      expect(ContextWeather.convertTemperatureToCelsius(212, '°F'), closeTo(100, 1e-9));
      expect(ContextWeather.convertTemperatureFromCelsius(100, '°F'), closeTo(212, 1e-9));
    });

    test('kelvin <-> celsius', () {
      expect(ContextWeather.convertTemperatureToCelsius(273.15, 'K'), closeTo(0, 1e-9));
      expect(ContextWeather.convertTemperatureFromCelsius(0, 'K'), closeTo(273.15, 1e-9));
    });

    test('unknown unit falls back to celsius (identity)', () {
      expect(ContextWeather.convertTemperatureToCelsius(15, 'rankine'), closeTo(15, 1e-9));
      expect(ContextWeather.convertTemperatureFromCelsius(15, 'rankine'), closeTo(15, 1e-9));
    });

    test('round-trips through celsius for every unit', () {
      for (final unit in ['°C', '°F', 'K']) {
        final celsius = ContextWeather.convertTemperatureToCelsius(18.5, unit)!;
        expect(
          ContextWeather.convertTemperatureFromCelsius(celsius, unit),
          closeTo(18.5, 1e-9),
        );
      }
    });
  });

  group('ContextWeather — wind speed conversion', () {
    test('null input returns null', () {
      expect(ContextWeather.convertWindSpeedToKmh(null, 'mph'), isNull);
      expect(ContextWeather.convertWindSpeedFromKmh(null, 'kt'), isNull);
    });

    test('km/h is identity', () {
      expect(ContextWeather.convertWindSpeedToKmh(10, 'km/h'), closeTo(10, 1e-9));
      expect(ContextWeather.convertWindSpeedFromKmh(10, 'km/h'), closeTo(10, 1e-9));
    });

    test('m/s -> km/h', () {
      expect(ContextWeather.convertWindSpeedToKmh(1, 'm/s'), closeTo(3.6, 1e-9));
    });

    test('knots -> km/h (exact 1.852)', () {
      expect(ContextWeather.convertWindSpeedToKmh(1, 'kt'), closeTo(1.852, 1e-9));
    });

    test('mph -> km/h (exact 1.609344)', () {
      expect(ContextWeather.convertWindSpeedToKmh(1, 'mph'), closeTo(1.609344, 1e-6));
    });

    test('unknown unit falls back to km/h (identity)', () {
      expect(ContextWeather.convertWindSpeedToKmh(7, 'mach'), closeTo(7, 1e-9));
      expect(ContextWeather.convertWindSpeedFromKmh(7, 'mach'), closeTo(7, 1e-9));
    });

    test('round-trips through km/h for every unit', () {
      for (final unit in ['km/h', 'm/s', 'mph', 'kt']) {
        final kmh = ContextWeather.convertWindSpeedToKmh(25.0, unit)!;
        expect(
          ContextWeather.convertWindSpeedFromKmh(kmh, unit),
          closeTo(25.0, 1e-9),
        );
      }
    });
  });

  group('ContextWeather — precipitation conversion', () {
    test('null input returns null', () {
      expect(ContextWeather.convertPrecipitationToMm(null, 'in'), isNull);
      expect(ContextWeather.convertPrecipitationFromMm(null, 'in'), isNull);
    });

    test('mm is identity', () {
      expect(ContextWeather.convertPrecipitationToMm(5, 'mm'), closeTo(5, 1e-9));
      expect(ContextWeather.convertPrecipitationFromMm(5, 'mm'), closeTo(5, 1e-9));
    });

    test('inches <-> mm (exact 25.4 mm/in)', () {
      expect(ContextWeather.convertPrecipitationToMm(1, 'in'), closeTo(25.4, 1e-9));
      expect(ContextWeather.convertPrecipitationFromMm(25.4, 'in'), closeTo(1, 1e-9));
    });

    test('unknown unit falls back to mm (identity)', () {
      expect(ContextWeather.convertPrecipitationToMm(3, 'cubits'), closeTo(3, 1e-9));
      expect(ContextWeather.convertPrecipitationFromMm(3, 'cubits'), closeTo(3, 1e-9));
    });

    test('round-trips through mm for every unit', () {
      for (final unit in ['mm', 'in']) {
        final mm = ContextWeather.convertPrecipitationToMm(12.7, unit)!;
        expect(
          ContextWeather.convertPrecipitationFromMm(mm, unit),
          closeTo(12.7, 1e-9),
        );
      }
    });
  });
}
