import 'package:bike_setup_tracker/models/adjustment/adjustment_unit.dart';
import 'package:bike_setup_tracker/utils/unit_conversion.dart';
import 'package:flutter_test/flutter_test.dart';

const _epsilon = 1e-6;

KnownUnit _u(UnitQuantity quantity, String unitId) => KnownUnit(quantity: quantity, unitId: unitId);

void main() {
  group('convertUnit', () {
    test('same unit returns the input value unchanged', () {
      final psi = _u(UnitQuantity.pressure, 'psi');
      expect(convertUnit(65.0, psi, psi), 65.0);
    });

    test('pressure: psi -> bar', () {
      final result = convertUnit(14.5037738, _u(UnitQuantity.pressure, 'psi'), _u(UnitQuantity.pressure, 'bar'));
      expect(result, closeTo(1.0, 1e-4));
    });

    test('length: mm -> in', () {
      final result = convertUnit(25.4, _u(UnitQuantity.length, 'millimeters'), _u(UnitQuantity.length, 'inches'));
      expect(result, closeTo(1.0, _epsilon));
    });

    test('mass: kg -> lb', () {
      final result = convertUnit(1.0, _u(UnitQuantity.mass, 'kilograms'), _u(UnitQuantity.mass, 'pounds'));
      expect(result, closeTo(2.2046226, 1e-5));
    });

    test('temperature: 0 C -> 32 F', () {
      final result = convertUnit(0.0, _u(UnitQuantity.temperature, 'celsius'), _u(UnitQuantity.temperature, 'fahrenheit'));
      expect(result, closeTo(32.0, _epsilon));
    });

    test('temperature: 100 C -> 212 F', () {
      final result = convertUnit(100.0, _u(UnitQuantity.temperature, 'celsius'), _u(UnitQuantity.temperature, 'fahrenheit'));
      expect(result, closeTo(212.0, _epsilon));
    });

    test('speed: km/h -> m/s', () {
      final result = convertUnit(36.0, _u(UnitQuantity.speed, 'kilometersPerHour'), _u(UnitQuantity.speed, 'metersPerSecond'));
      expect(result, closeTo(10.0, _epsilon));
    });

    test('angle: 180 deg -> pi rad', () {
      final result = convertUnit(180.0, _u(UnitQuantity.angle, 'degree'), _u(UnitQuantity.angle, 'radians'));
      expect(result, closeTo(3.14159265, 1e-4));
    });

    test('torque: Nm -> lbf.in', () {
      final result = convertUnit(1.0, _u(UnitQuantity.torque, 'newtonMeter'), _u(UnitQuantity.torque, 'poundForceInch'));
      expect(result, closeTo(8.8507, 1e-3));
    });

    test('volume: ml -> us fl oz', () {
      final result = convertUnit(29.5735, _u(UnitQuantity.volume, 'milliliters'), _u(UnitQuantity.volume, 'usFluidOunces'));
      expect(result, closeTo(1.0, 1e-3));
    });

    group('spring rate (custom property)', () {
      test('500 lbs/in ≈ 87.56 N/mm', () {
        final result = convertUnit(500.0, _u(UnitQuantity.springRate, 'lbs/in'), _u(UnitQuantity.springRate, 'N/mm'));
        expect(result, closeTo(87.5635, 1e-3));
      });

      test('N/mm -> lbs/in is the inverse conversion', () {
        final result = convertUnit(87.5635, _u(UnitQuantity.springRate, 'N/mm'), _u(UnitQuantity.springRate, 'lbs/in'));
        expect(result, closeTo(500.0, 1e-2));
      });
    });

    group('round-trip precision', () {
      test('psi -> bar -> psi returns the original value', () {
        final psi = _u(UnitQuantity.pressure, 'psi');
        final bar = _u(UnitQuantity.pressure, 'bar');
        final converted = convertUnit(65.0, psi, bar);
        final roundTripped = convertUnit(converted, bar, psi);
        expect(roundTripped, closeTo(65.0, 1e-6));
      });

      test('mm -> in -> mm returns the original value', () {
        final mm = _u(UnitQuantity.length, 'millimeters');
        final inch = _u(UnitQuantity.length, 'inches');
        final converted = convertUnit(120.0, mm, inch);
        final roundTripped = convertUnit(converted, inch, mm);
        expect(roundTripped, closeTo(120.0, 1e-6));
      });
    });

    test('asserts on quantity mismatch', () {
      expect(
        () => convertUnit(1.0, _u(UnitQuantity.pressure, 'psi'), _u(UnitQuantity.length, 'millimeters')),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('toggleCycle', () {
    test('pressure cycle order matches the catalog: psi -> bar -> kPa', () {
      expect(toggleCycle(UnitQuantity.pressure), [
        _u(UnitQuantity.pressure, 'psi'),
        _u(UnitQuantity.pressure, 'bar'),
        _u(UnitQuantity.pressure, 'kiloPascal'),
      ]);
    });

    test('every quantity has a non-empty cycle', () {
      for (final quantity in UnitQuantity.values) {
        expect(toggleCycle(quantity), isNotEmpty);
      }
    });
  });

  group('formatConverted', () {
    test('rounds to 5 decimals, strips trailing zeros', () {
      expect(formatConverted(4.480519), '4.48052');
      expect(formatConverted(1.0), '1');
    });
  });
}
