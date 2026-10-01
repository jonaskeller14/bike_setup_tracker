import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:flutter_test/flutter_test.dart';

/// Migration / robustness coverage for multi-select categorical values.
///
/// The invariants under test:
/// * JSON `version` is a *guard* — 2 only when `multiSelect` is used, so old app
///   builds refuse (not silently drop) multi-select data across cloud sync.
/// * The stored value round-trips as the canonical `List<String>`, with legacy
///   single `String` values (and even JSON-looking option names) preserved.
void main() {
  const options = {'Open', 'Firm', 'Locked'};

  CategoricalAdjustment build({required bool multiSelect}) => CategoricalAdjustment(
        id: 'adj1',
        name: 'Mode',
        notes: null,
        unit: null,
        options: options,
        multiSelect: multiSelect,
      );

  group('JSON version guard', () {
    test('single-select stays version 1 (readable by old builds)', () {
      expect(build(multiSelect: false).toJson()['version'], 1);
    });

    test('multi-select bumps to version 2 (refused by old builds)', () {
      expect(build(multiSelect: true).toJson()['version'], 2);
    });

    test('toJson always carries the multiSelect flag', () {
      expect(build(multiSelect: true).toJson()['multiSelect'], true);
      expect(build(multiSelect: false).toJson()['multiSelect'], false);
    });
  });

  group('CategoricalAdjustment.fromJson', () {
    test('legacy v1 without multiSelect key ⇒ single-select', () {
      final adj = CategoricalAdjustment.fromJson(const {
        'version': 1,
        'id': 'adj1',
        'name': 'Mode',
        'notes': null,
        'unit': null,
        'options': ['Open', 'Firm'],
      });
      expect(adj.multiSelect, isFalse);
    });

    test('v1 with an explicit multiSelect key is honoured', () {
      final adj = CategoricalAdjustment.fromJson(const {
        'version': 1,
        'id': 'adj1',
        'name': 'Mode',
        'notes': null,
        'unit': null,
        'options': ['Open', 'Firm'],
        'multiSelect': true,
      });
      expect(adj.multiSelect, isTrue);
    });

    test('v2 multi-select round-trips through toJson/fromJson', () {
      final original = build(multiSelect: true);
      final restored = CategoricalAdjustment.fromJson(original.toJson());
      expect(restored, equals(original));
      expect(restored.multiSelect, isTrue);
    });
  });

  group('Adjustment.fromJson envelope', () {
    Map<String, dynamic> payload(int version) => {
          'version': version,
          'type': 'categorical',
          'id': 'adj1',
          'name': 'Mode',
          'notes': null,
          'unit': null,
          'options': ['Open', 'Firm'],
          'multiSelect': true,
        };

    test('accepts version 2 categorical', () {
      final adj = Adjustment.fromJson(payload(2)) as CategoricalAdjustment;
      expect(adj.multiSelect, isTrue);
    });

    test('accepts legacy version 1', () {
      expect(() => Adjustment.fromJson(payload(1)), returnsNormally);
    });

    test('accepts version 3 (counted)', () {
      expect(() => Adjustment.fromJson(payload(3)), returnsNormally);
    });

    test('still guards against an unknown future version', () {
      expect(() => Adjustment.fromJson(payload(4)), throwsException);
    });
  });

  group('AdjustmentValue.encode (every value is JSON since schema v11)', () {
    test('encodes a list as a JSON array', () {
      expect(CategoricalValue(const ['Open', 'Firm']).encode(), '["Open","Firm"]');
    });

    test('encodes a single-select one-element list as a JSON array', () {
      expect(CategoricalValue(const ['Open']).encode(), '["Open"]');
    });

    test('scalars are JSON-encoded (bool, int, double)', () {
      expect(const BooleanValue(true).encode(), 'true');
      expect(const StepValue(42).encode(), '42');
      expect(const NumericalValue(1.5).encode(), '1.5');
    });

    test('a text value is a *quoted* JSON string (never confused with a list)', () {
      expect(TextValue.orNull('Open')!.encode(), '"Open"');
      // Text that happens to look like a JSON array stays a JSON string.
      expect(TextValue.orNull('["abc"]')!.encode(), '"[\\"abc\\"]"');
    });

    test('a Duration is stored as integer microseconds', () {
      expect(const DurationValue(Duration(seconds: 10)).encode(), '10000000');
      expect(const DurationValue(Duration.zero).encode(), '0');
    });
  });

  group('AdjustmentValue.decode (read path, keyed by type)', () {
    test('boolean', () {
      expect(AdjustmentValue.decode('true', AdjustmentType.boolean), const BooleanValue(true));
      expect(AdjustmentValue.decode('false', AdjustmentType.boolean), const BooleanValue(false));
    });

    test('numerical always decodes to double (even integer-valued)', () {
      expect(AdjustmentValue.decode('1.5', AdjustmentType.numerical), const NumericalValue(1.5));
      expect(AdjustmentValue.decode('2', AdjustmentType.numerical), const NumericalValue(2.0));
    });

    test('step decodes to int', () {
      expect(AdjustmentValue.decode('3', AdjustmentType.step), const StepValue(3));
    });

    test('categorical decodes a JSON array', () {
      expect(AdjustmentValue.decode('["Front","Rear"]', AdjustmentType.categorical), CategoricalValue(const ['Front', 'Rear']));
      expect(AdjustmentValue.decode('["Open"]', AdjustmentType.categorical), CategoricalValue(const ['Open']));
    });

    test('text decodes a quoted JSON string (JSON-looking text stays text)', () {
      expect(AdjustmentValue.decode('"Open"', AdjustmentType.text), TextValue.orNull('Open'));
      expect(AdjustmentValue.decode('"[\\"abc\\"]"', AdjustmentType.text), TextValue.orNull('["abc"]'));
    });

    test('duration reconstructs from integer microseconds', () {
      expect(AdjustmentValue.decode('10000000', AdjustmentType.duration), const DurationValue(Duration(seconds: 10)));
    });

    test('encode → decode round-trips for every type', () {
      for (final (value, type) in <(AdjustmentValue, AdjustmentType)>[
        (const BooleanValue(true), AdjustmentType.boolean),
        (const NumericalValue(1.5), AdjustmentType.numerical),
        (const StepValue(3), AdjustmentType.step),
        (CategoricalValue(const ['a', 'b']), AdjustmentType.categorical),
        (TextValue.orNull('hi')!, AdjustmentType.text),
        (const DurationValue(Duration(minutes: 3)), AdjustmentType.duration),
      ]) {
        expect(AdjustmentValue.decode(value.encode(), type), value);
      }
    });

    group('defensive fallback for a non-JSON (un-migrated legacy) row', () {
      test('categorical plain option string ⇒ wrapped', () {
        expect(AdjustmentValue.decode('Open', AdjustmentType.categorical), CategoricalValue(const ['Open']));
      });
      test('text plain string ⇒ itself', () {
        expect(AdjustmentValue.decode('hello world', AdjustmentType.text), TextValue.orNull('hello world'));
      });
      test('duration legacy H:MM:SS string ⇒ parsed', () {
        expect(
          AdjustmentValue.decode('0:00:10.000000', AdjustmentType.duration),
          const DurationValue(Duration(seconds: 10)),
        );
      });
    });
  });

  group('AdjustmentValue.decodeLegacy (pre-v11 reparse, migration only)', () {
    test('scalars reparse from their toString form', () {
      expect(AdjustmentValue.decodeLegacy('true', AdjustmentType.boolean), const BooleanValue(true));
      expect(AdjustmentValue.decodeLegacy('1.5', AdjustmentType.numerical), const NumericalValue(1.5));
      expect(AdjustmentValue.decodeLegacy('3', AdjustmentType.step), const StepValue(3));
    });

    test('a categorical value was a plain option string ⇒ one-element list', () {
      expect(AdjustmentValue.decodeLegacy('Open', AdjustmentType.categorical), CategoricalValue(const ['Open']));
    });

    test('a JSON-looking option name is preserved whole (multi-select never shipped)', () {
      expect(AdjustmentValue.decodeLegacy('[1,2]', AdjustmentType.categorical), CategoricalValue(const ['[1,2]']));
    });

    test('text is identity, duration parses the H:MM:SS form', () {
      expect(AdjustmentValue.decodeLegacy('some notes', AdjustmentType.text), TextValue.orNull('some notes'));
      expect(
        AdjustmentValue.decodeLegacy('0:00:10.000000', AdjustmentType.duration),
        const DurationValue(Duration(seconds: 10)),
      );
    });

    test('legacy → re-encode → new-decode round-trips (the migration path)', () {
      for (final (raw, type) in <(String, AdjustmentType)>[
        ('true', AdjustmentType.boolean),
        ('1.5', AdjustmentType.numerical),
        ('3', AdjustmentType.step),
        ('Open', AdjustmentType.categorical),
        ('[1,2]', AdjustmentType.categorical),
        ('free text', AdjustmentType.text),
        ('0:00:10.000000', AdjustmentType.duration),
      ]) {
        final legacy = AdjustmentValue.decodeLegacy(raw, type)!;
        // The migrated value is valid JSON and decodes to the same in-memory value.
        expect(AdjustmentValue.decode(legacy.encode(), type), legacy, reason: 'round-trip failed for $raw ($type)');
      }
    });
  });

  group('Setup.adjustmentValuesFromJson (backup import) preserves value shape', () {
    test('a JSON array becomes a categorical value', () {
      final result = Setup.adjustmentValuesFromJson({'k': ['Front', 'Rear']}, adjustmentTypes: {'k': AdjustmentType.categorical});
      expect(result['k'], CategoricalValue(const ['Front', 'Rear']));
    });

    test('a text value that happens to look like JSON stays text', () {
      // In a backup this is a JSON *string* (quoted), so it is imported as
      // text and never confused with a categorical array.
      final result = Setup.adjustmentValuesFromJson({'k': '["abc"]'}, adjustmentTypes: {'k': AdjustmentType.text});
      expect(result['k'], TextValue.orNull('["abc"]'));
    });
  });
}
