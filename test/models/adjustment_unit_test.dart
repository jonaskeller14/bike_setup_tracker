import 'package:bike_setup_tracker/models/adjustment/adjustment_unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdjustmentUnit.decode (strict, no aliasing)', () {
    test('null returns null', () => expect(AdjustmentUnit.decode(null), isNull));
    test('empty string returns null', () => expect(AdjustmentUnit.decode(''), isNull));

    test('canonical known-unit string decodes to KnownUnit', () {
      expect(
        AdjustmentUnit.decode('pressure:psi'),
        const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi'),
      );
    });

    test('plain legacy spelling without prefix stays CustomUnit', () {
      expect(AdjustmentUnit.decode('psi'), const CustomUnit('psi'));
    });

    test('unknown quantity prefix stays CustomUnit', () {
      expect(AdjustmentUnit.decode('foo:bar'), const CustomUnit('foo:bar'));
    });

    test('known quantity but unknown unitId stays CustomUnit', () {
      expect(AdjustmentUnit.decode('pressure:unknown'), const CustomUnit('pressure:unknown'));
    });

    test('string with only a colon stays CustomUnit', () {
      expect(AdjustmentUnit.decode(':'), const CustomUnit(':'));
    });

    test('opaque custom label stays CustomUnit', () {
      expect(AdjustmentUnit.decode('clicks'), const CustomUnit('clicks'));
    });

    test('spring rate custom-property unit decodes to KnownUnit', () {
      expect(
        AdjustmentUnit.decode('springRate:lbs/in'),
        const KnownUnit(quantity: UnitQuantity.springRate, unitId: 'lbs/in'),
      );
    });
  });

  group('AdjustmentUnit.fromLegacy (migration/import alias normalization)', () {
    test('null returns null', () => expect(AdjustmentUnit.fromLegacy(null), isNull));
    test('empty string returns null', () => expect(AdjustmentUnit.fromLegacy(''), isNull));
    test('whitespace-only string returns null', () => expect(AdjustmentUnit.fromLegacy('   '), isNull));

    test('already-canonical string decodes strictly first', () {
      expect(
        AdjustmentUnit.fromLegacy('pressure:psi'),
        const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi'),
      );
    });

    for (final entry in <(String, UnitQuantity, String)>[
      ('psi', UnitQuantity.pressure, 'psi'),
      ('PSI', UnitQuantity.pressure, 'psi'),
      ('bar', UnitQuantity.pressure, 'bar'),
      ('kpa', UnitQuantity.pressure, 'kiloPascal'),
      ('mm', UnitQuantity.length, 'millimeters'),
      ('cm', UnitQuantity.length, 'centimeters'),
      ('in', UnitQuantity.length, 'inches'),
      ('inch', UnitQuantity.length, 'inches'),
      ('kg', UnitQuantity.mass, 'kilograms'),
      ('g', UnitQuantity.mass, 'grams'),
      ('lb', UnitQuantity.mass, 'pounds'),
      ('lbs', UnitQuantity.mass, 'pounds'),
      ('°c', UnitQuantity.temperature, 'celsius'),
      ('°f', UnitQuantity.temperature, 'fahrenheit'),
      ('km/h', UnitQuantity.speed, 'kilometersPerHour'),
      ('kph', UnitQuantity.speed, 'kilometersPerHour'),
      ('KPH', UnitQuantity.speed, 'kilometersPerHour'),
      ('kmh', UnitQuantity.speed, 'kilometersPerHour'),
      ('mph', UnitQuantity.speed, 'milesPerHour'),
      ('m/s', UnitQuantity.speed, 'metersPerSecond'),
      ('°', UnitQuantity.angle, 'degree'),
      ('deg', UnitQuantity.angle, 'degree'),
      ('nm', UnitQuantity.torque, 'newtonMeter'),
      ('n·m', UnitQuantity.torque, 'newtonMeter'),
      ('n-m', UnitQuantity.torque, 'newtonMeter'),
      ('ml', UnitQuantity.volume, 'milliliters'),
      ('fl oz', UnitQuantity.volume, 'usFluidOunces'),
      ('oz', UnitQuantity.volume, 'usFluidOunces'),
      ('n/mm', UnitQuantity.springRate, 'N/mm'),
      ('lbs/in', UnitQuantity.springRate, 'lbs/in'),
      ('lb/in', UnitQuantity.springRate, 'lbs/in'),
    ]) {
      final (spelling, quantity, unitId) = entry;
      test('"$spelling" maps to $quantity/$unitId', () {
        expect(AdjustmentUnit.fromLegacy(spelling), KnownUnit(quantity: quantity, unitId: unitId));
      });
    }

    test('bare "c" is intentionally left ambiguous (stays custom)', () {
      expect(AdjustmentUnit.fromLegacy('c'), const CustomUnit('c'));
    });

    test('bare "f" is intentionally left ambiguous (stays custom)', () {
      expect(AdjustmentUnit.fromLegacy('f'), const CustomUnit('f'));
    });

    test('unrecognized spelling stays CustomUnit, trimmed', () {
      expect(AdjustmentUnit.fromLegacy('  Klicks  '), const CustomUnit('Klicks'));
    });

    test('blessed custom label stays CustomUnit', () {
      expect(AdjustmentUnit.fromLegacy('%'), const CustomUnit('%'));
    });
  });

  group('encode/decode round-trip', () {
    for (final quantity in UnitQuantity.values) {
      for (final entry in unitCatalog[quantity]!) {
        final unit = KnownUnit(quantity: quantity, unitId: entry.unitId);
        test('${unit.encode()} round-trips', () {
          expect(AdjustmentUnit.decode(unit.encode()), unit);
        });
      }
    }

    test('CustomUnit round-trips through encode/decode', () {
      const unit = CustomUnit('clicks');
      expect(AdjustmentUnit.decode(unit.encode()), unit);
    });
  });

  group('label', () {
    test('KnownUnit label comes from the catalog', () {
      expect(const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi').label, 'psi');
      expect(const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'kiloPascal').label, 'kPa');
    });

    test('CustomUnit label is the raw string', () {
      expect(const CustomUnit('clicks').label, 'clicks');
    });
  });

  group('equality', () {
    test('KnownUnit equality is value-based', () {
      expect(
        const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi'),
        const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi'),
      );
      expect(
        const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi'),
        isNot(const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'bar')),
      );
    });

    test('CustomUnit equality is value-based', () {
      expect(const CustomUnit('clicks'), const CustomUnit('clicks'));
      expect(const CustomUnit('clicks'), isNot(const CustomUnit('turns')));
    });

    test('KnownUnit and CustomUnit are never equal', () {
      expect(
        const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi'),
        isNot(const CustomUnit('pressure:psi')),
      );
    });
  });
}
