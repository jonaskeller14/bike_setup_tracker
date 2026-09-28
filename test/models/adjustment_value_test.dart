import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Every value kind with its stored encoding, display text and type.
  final samples = <(AdjustmentValue, String, String, AdjustmentType)>[
    (const BooleanValue(true), 'true', 'On', AdjustmentType.boolean),
    (const BooleanValue(false), 'false', 'Off', AdjustmentType.boolean),
    (const StepValue(-3), '-3', '-3', AdjustmentType.step),
    (const NumericalValue(89.0), '89.0', '89', AdjustmentType.numerical),
    (const NumericalValue(1.123456), '1.123456', '1.12346', AdjustmentType.numerical),
    (TextValue.orNull('01:30:00')!, '"01:30:00"', '01:30:00', AdjustmentType.text),
    (TextValue.orNull('["abc"]')!, r'"[\"abc\"]"', '["abc"]', AdjustmentType.text),
    (CategoricalValue(['Front']), '["Front"]', 'Front', AdjustmentType.categorical),
    (CategoricalValue(['A', 'B', 'A']), '["A","B","A"]', 'A (2), B', AdjustmentType.categorical),
    (
      const DurationValue(Duration(hours: 1, minutes: 2, seconds: 3)),
      '3723000000',
      '01:02:03',
      AdjustmentType.duration,
    ),
  ];

  group('encode/decode', () {
    for (final (value, encoded, _, type) in samples) {
      test('$value round-trips', () {
        expect(AdjustmentValue.decode(value.encode(), type), value);
      });

      test('$value encodes as $encoded', () {
        expect(value.encode(), encoded);
      });
    }

    test('JSON null decodes to null', () {
      for (final type in AdjustmentType.values) {
        expect(AdjustmentValue.decode('null', type), isNull);
      }
    });

    test('empty text decodes to null', () {
      expect(AdjustmentValue.decode('""', AdjustmentType.text), isNull);
      expect(AdjustmentValue.decode('', AdjustmentType.text), isNull);
    });

    test('a JSON integer decodes to a double for numerical', () {
      expect(AdjustmentValue.decode('89', AdjustmentType.numerical), const NumericalValue(89.0));
    });

    test('a scalar categorical decodes to a one-element list', () {
      expect(AdjustmentValue.decode('"Front"', AdjustmentType.categorical), CategoricalValue(['Front']));
    });

    group('a JSON shape that does not fit the type stays unresolved', () {
      for (final (raw, type) in [
        ('5', AdjustmentType.text),
        ('"true"', AdjustmentType.boolean),
        ('"3"', AdjustmentType.step),
        ('[1]', AdjustmentType.numerical),
        ('{"x":1}', AdjustmentType.categorical),
        ('"1:00:00.000000"', AdjustmentType.duration),
      ]) {
        test('$raw as ${type.name}', () => expect(AdjustmentValue.decode(raw, type), UnresolvedValue(raw)));
      }
    });

    group('legacy plain strings', () {
      test('boolean', () => expect(AdjustmentValue.decode('True', AdjustmentType.boolean), const BooleanValue(true)));
      test('step', () => expect(AdjustmentValue.decode('4 clicks', AdjustmentType.step), isNull));
      test('numerical', () => expect(AdjustmentValue.decode('1.5x', AdjustmentType.numerical), isNull));
      test(
        'categorical',
        () => expect(AdjustmentValue.decode('Open', AdjustmentType.categorical), CategoricalValue(['Open'])),
      );
      test(
        'text',
        () => expect(AdjustmentValue.decode('plain notes', AdjustmentType.text), TextValue.orNull('plain notes')),
      );
      test('duration', () {
        expect(
          AdjustmentValue.decode('1:02:03.000000', AdjustmentType.duration),
          const DurationValue(Duration(hours: 1, minutes: 2, seconds: 3)),
        );
      });
    });

    test('UnresolvedValue round-trips byte-identically', () {
      for (final raw in ['{"x": [1, 2]}', 'not json', '"01:30:00"', '']) {
        expect(UnresolvedValue(raw).encode(), raw);
      }
    });
  });

  group('equality', () {
    test('categorical compares by content', () {
      final a = CategoricalValue(['Front']);
      final b = CategoricalValue(['Front']);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('categorical is order-sensitive', () {
      expect(CategoricalValue(['A', 'B']), isNot(CategoricalValue(['B', 'A'])));
    });

    test('counted categorical compares by counts', () {
      expect(CategoricalValue(['A', 'A']), isNot(CategoricalValue(['A'])));
    });

    test('different kinds are never equal', () {
      expect(const StepValue(1), isNot(const NumericalValue(1.0)));
      expect(TextValue.orNull('Front'), isNot(CategoricalValue(['Front'])));
      expect(const UnresolvedValue('"Front"'), isNot(TextValue.orNull('Front')));
    });

    test('categorical options are unmodifiable', () {
      final source = ['Front'];
      final value = CategoricalValue(source);
      source.add('Rear');
      expect(value.options, ['Front']);
      expect(() => value.options.add('Rear'), throwsUnsupportedError);
    });
  });

  group('display', () {
    for (final (value, _, display, _) in samples) {
      test('$value displays as $display', () {
        expect(value.display, display);
      });
    }

    test('counted categorical', () => expect(CategoricalValue(['A', 'A', 'B']).display, 'A (2), B'));
    test('empty categorical', () => expect(CategoricalValue([]).display, '-'));
    test('unresolved shows raw', () => expect(const UnresolvedValue('{"x":1}').display, '{"x":1}'));
  });

  group('asNum', () {
    test('step', () => expect(const StepValue(3).asNum, 3));
    test('numerical', () => expect(const NumericalValue(1.5).asNum, 1.5));
    test('boolean', () => expect(const BooleanValue(true).asNum, 1));
    test('duration in seconds', () => expect(const DurationValue(Duration(milliseconds: 1500)).asNum, 1.5));
    test('text', () => expect(TextValue.orNull('x')!.asNum, isNull));
    test('categorical', () => expect(CategoricalValue(['A']).asNum, isNull));
    test('unresolved', () => expect(const UnresolvedValue('1').asNum, isNull));
  });

  group('matches', () {
    for (final (value, _, _, type) in samples) {
      test('$value matches only $type', () {
        for (final other in AdjustmentType.values) {
          expect(value.matches(other), other == type);
        }
      });
    }

    test('unresolved matches nothing', () {
      for (final type in AdjustmentType.values) {
        expect(const UnresolvedValue('1').matches(type), isFalse);
      }
    });
  });

  group('decodeLegacy', () {
    test('boolean', () => expect(AdjustmentValue.decodeLegacy('true', AdjustmentType.boolean), const BooleanValue(true)));
    test('step', () => expect(AdjustmentValue.decodeLegacy('3', AdjustmentType.step), const StepValue(3)));
    test('numerical', () => expect(AdjustmentValue.decodeLegacy('1.5', AdjustmentType.numerical), const NumericalValue(1.5)));
    test('unparseable scalar is absent', () {
      expect(AdjustmentValue.decodeLegacy('4 clicks', AdjustmentType.step), isNull);
      expect(AdjustmentValue.decodeLegacy('1.5x', AdjustmentType.numerical), isNull);
      expect(AdjustmentValue.decodeLegacy('soon', AdjustmentType.duration), isNull);
    });
    test('a JSON-looking categorical is one option', () {
      expect(AdjustmentValue.decodeLegacy('[1,2]', AdjustmentType.categorical), CategoricalValue(['[1,2]']));
    });
    test('empty text is absent', () => expect(AdjustmentValue.decodeLegacy('', AdjustmentType.text), isNull));
  });
}
