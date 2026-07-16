import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:flutter_test/flutter_test.dart';

/// SAG is a *subtype* of the numerical fundamental type, not a new one: it is
/// persisted as `type: numerical` with a `subtype` discriminator so that code
/// paths (and app versions) that don't know about sag keep treating it as the
/// plain percentage adjustment it fundamentally is.
/// See doc/20260715_sag_adjustment_type.md.
void main() {
  SagAdjustment build({double? travel = 160}) => SagAdjustment(
        id: 'sag1',
        name: 'SAG',
        notes: null,
        referenceTravelMm: travel,
      );

  group('persisted shape', () {
    test('serializes as a numerical carrying a sag subtype', () {
      final json = build().toJson();
      expect(json['type'], AdjustmentType.numerical.name);
      expect(json['subtype'], 'sag');
      expect(json['version'], 2);
      expect(json['referenceTravelMm'], 160);
    });

    test('is fixed to the 0..100 % value range', () {
      final adjustment = build();
      expect(adjustment.unit!.label, '%');
      expect(adjustment.min, 0);
      expect(adjustment.max, 100);
      final json = adjustment.toJson();
      expect(json['unit'], '%');
      expect(json['min'], 0);
      expect(json['max'], 100);
    });

    test('stores a plain double percent, exactly like its parent type', () {
      expect(build().isValidValue(28.0), isTrue);
      expect(build().isValidValue(101.0), isFalse);
      expect(build().isValidValue(-1.0), isFalse);
    });
  });

  group('decoding', () {
    test('round-trips through the Adjustment envelope', () {
      final original = build();
      final restored = Adjustment.fromJson(original.toJson());
      expect(restored, isA<SagAdjustment>());
      expect(restored, equals(original));
      expect((restored as SagAdjustment).referenceTravelMm, 160);
    });

    test('round-trips an unknown travel', () {
      final restored = Adjustment.fromJson(build(travel: null).toJson());
      expect(restored, equals(build(travel: null)));
      expect((restored as SagAdjustment).referenceTravelMm, isNull);
    });

    test('a sag payload decodes to a SagAdjustment via NumericalAdjustment.fromJson', () {
      expect(NumericalAdjustment.fromJson(build().toJson()), isA<SagAdjustment>());
    });

    test('an unknown future subtype degrades to a plain numerical instead of throwing', () {
      final adjustment = Adjustment.fromJson({
        'version': 2,
        'type': 'numerical',
        'subtype': 'tirePressure',
        'id': 'adj1',
        'name': 'Pressure',
        'notes': null,
        'unit': 'pressure:psi',
        'min': 0.0,
        'max': 300.0,
        'tireWidthMm': 61.0,
      });
      expect(adjustment, isA<NumericalAdjustment>());
      expect(adjustment, isNot(isA<SagAdjustment>()));
      expect((adjustment as NumericalAdjustment).max, 300.0);
    });

    test('a subtype-less numerical payload stays a plain numerical', () {
      final adjustment = Adjustment.fromJson({
        'version': 2,
        'type': 'numerical',
        'id': 'adj1',
        'name': 'SAG',
        'notes': null,
        'unit': '%',
        'min': 0.0,
        'max': 100.0,
      });
      expect(adjustment, isNot(isA<SagAdjustment>()));
    });

    test('guards against an unknown future version', () {
      expect(
        () => SagAdjustment.fromJson({'version': 3, 'id': 'a', 'name': 'n', 'notes': null}),
        throwsException,
      );
    });
  });

  group('mm derivation', () {
    test('converts between percent and the absolute reading', () {
      final adjustment = build(travel: 160);
      expect(adjustment.toMillimeters(25), closeTo(40, 1e-9));
      expect(adjustment.fromMillimeters(40), closeTo(25, 1e-9));
    });

    test('yields null without a usable travel', () {
      expect(build(travel: null).toMillimeters(25), isNull);
      expect(build(travel: null).fromMillimeters(40), isNull);
      expect(build(travel: 0).toMillimeters(25), isNull);
    });
  });

  group('copying', () {
    test('deepCopy keeps the sag type and travel but takes a fresh id', () {
      final copy = build().deepCopy();
      expect(copy, isA<SagAdjustment>());
      expect(copy.referenceTravelMm, 160);
      expect(copy.id, isNot('sag1'));
    });

    test('copyWith cannot silently downgrade a sag to a plain numerical', () {
      final copy = build().copyWith(name: 'Rear SAG', referenceTravelMm: 65.0);
      expect(copy, isA<SagAdjustment>());
      expect(copy.name, 'Rear SAG');
      expect(copy.referenceTravelMm, 65.0);
      expect(copy.id, 'sag1');
    });

    test('equality distinguishes travel and rejects a same-field numerical', () {
      expect(build(travel: 160), isNot(equals(build(travel: 150))));
      expect(
        build(),
        isNot(equals(NumericalAdjustment(
          id: 'sag1',
          name: 'SAG',
          notes: null,
          unit: const CustomUnit('%'),
          min: 0,
          max: 100,
        ))),
      );
    });
  });
}
