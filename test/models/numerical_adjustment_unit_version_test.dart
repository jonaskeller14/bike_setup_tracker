import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:flutter_test/flutter_test.dart';

/// JSON version guard for the structured-unit change on NumericalAdjustment.
///
/// v2 switched `unit` from a plain label ("psi") to the canonical
/// AdjustmentUnit encoding ("pressure:psi"). The version was bumped so an older
/// app build hard-rejects a newer backup (throws) instead of silently importing
/// the canonical string as a raw custom label. See the risk table in
/// doc/20260709_adjustment_unit_conversion_implementation.md.
void main() {
  NumericalAdjustment build({AdjustmentUnit? unit}) => NumericalAdjustment(
        id: 'adj1',
        name: 'Pressure',
        notes: null,
        unit: unit,
        min: 0,
        max: 300,
      );

  group('JSON version guard', () {
    test('toJson always stamps version 2', () {
      expect(build().toJson()['version'], 2);
      expect(build(unit: const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi')).toJson()['version'], 2);
    });

    test('a KnownUnit serializes to its canonical encoding, not a raw label', () {
      final json = build(unit: const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi')).toJson();
      expect(json['unit'], 'pressure:psi');
    });
  });

  group('NumericalAdjustment.fromJson', () {
    test('v2 round-trips a structured unit through toJson/fromJson', () {
      final original = build(unit: const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi'));
      final restored = NumericalAdjustment.fromJson(original.toJson());
      expect(restored, equals(original));
      expect(restored.unit, isA<KnownUnit>());
    });

    test('still accepts a legacy v1 payload (custom unit label)', () {
      final adj = NumericalAdjustment.fromJson({
        'version': 1,
        'id': 'adj1',
        'name': 'Clicks',
        'notes': null,
        'unit': 'clicks',
        'min': 0.0,
        'max': 20.0,
      });
      expect(adj.unit, isA<CustomUnit>());
      expect(adj.unit!.label, 'clicks');
    });

    test('guards against an unknown future version', () {
      expect(
        () => NumericalAdjustment.fromJson({'version': 3, 'id': 'a', 'name': 'n', 'notes': null, 'unit': null}),
        throwsException,
      );
    });
  });

  group('Adjustment.fromJson envelope', () {
    Map<String, dynamic> payload(int version) => {
          'version': version,
          'type': 'numerical',
          'id': 'adj1',
          'name': 'Pressure',
          'notes': null,
          'unit': 'pressure:psi',
          'min': 0.0,
          'max': 300.0,
        };

    test('accepts version 2 numerical', () {
      final adj = Adjustment.fromJson(payload(2)) as NumericalAdjustment;
      expect(adj.unit, isA<KnownUnit>());
    });

    test('accepts legacy version 1', () {
      expect(() => Adjustment.fromJson(payload(1)), returnsNormally);
    });
  });
}
