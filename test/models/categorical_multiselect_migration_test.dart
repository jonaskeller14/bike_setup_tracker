import 'package:bike_setup_tracker/database/adjustment_value_codec.dart';
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
/// * A stray non-String never reaches a text field.
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
      final adj = CategoricalAdjustment.fromJson({
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
      final adj = CategoricalAdjustment.fromJson({
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

    test('still guards against an unknown future version', () {
      expect(() => Adjustment.fromJson(payload(3)), throwsException);
    });
  });

  group('encodeAdjustmentValue (every value is JSON since schema v11)', () {
    test('encodes a list as a JSON array', () {
      expect(encodeAdjustmentValue(['Open', 'Firm']), '["Open","Firm"]');
    });

    test('encodes a single-select one-element list as a JSON array', () {
      expect(encodeAdjustmentValue(['Open']), '["Open"]');
    });

    test('scalars are JSON-encoded (bool, int, double)', () {
      expect(encodeAdjustmentValue(true), 'true');
      expect(encodeAdjustmentValue(42), '42');
      expect(encodeAdjustmentValue(1.5), '1.5');
    });

    test('a text value is a *quoted* JSON string (never confused with a list)', () {
      expect(encodeAdjustmentValue('Open'), '"Open"');
      // Text that happens to look like a JSON array stays a JSON string.
      expect(encodeAdjustmentValue('["abc"]'), '"[\\"abc\\"]"');
    });

    test('a Duration is stored as integer microseconds', () {
      expect(encodeAdjustmentValue(const Duration(seconds: 10)), '10000000');
      expect(encodeAdjustmentValue(Duration.zero), '0');
    });
  });

  group('decodeAdjustmentValue (read path, keyed by type)', () {
    test('boolean', () {
      expect(decodeAdjustmentValue('true', AdjustmentType.boolean), true);
      expect(decodeAdjustmentValue('false', AdjustmentType.boolean), false);
    });

    test('numerical always decodes to double (even integer-valued)', () {
      expect(decodeAdjustmentValue('1.5', AdjustmentType.numerical), 1.5);
      final v = decodeAdjustmentValue('2', AdjustmentType.numerical);
      expect(v, isA<double>());
      expect(v, 2.0);
    });

    test('step decodes to int', () {
      expect(decodeAdjustmentValue('3', AdjustmentType.step), 3);
    });

    test('categorical decodes a JSON array to List<String>', () {
      expect(decodeAdjustmentValue('["Front","Rear"]', AdjustmentType.categorical), ['Front', 'Rear']);
      expect(decodeAdjustmentValue('["Open"]', AdjustmentType.categorical), ['Open']);
    });

    test('text decodes a quoted JSON string (JSON-looking text stays a String)', () {
      expect(decodeAdjustmentValue('"Open"', AdjustmentType.text), 'Open');
      final v = decodeAdjustmentValue('"[\\"abc\\"]"', AdjustmentType.text);
      expect(v, isA<String>());
      expect(v, '["abc"]');
    });

    test('duration reconstructs from integer microseconds', () {
      expect(decodeAdjustmentValue('10000000', AdjustmentType.duration), const Duration(seconds: 10));
    });

    test('encode → decode round-trips for every type', () {
      expect(decodeAdjustmentValue(encodeAdjustmentValue(true), AdjustmentType.boolean), true);
      expect(decodeAdjustmentValue(encodeAdjustmentValue(1.5), AdjustmentType.numerical), 1.5);
      expect(decodeAdjustmentValue(encodeAdjustmentValue(3), AdjustmentType.step), 3);
      expect(decodeAdjustmentValue(encodeAdjustmentValue(['a', 'b']), AdjustmentType.categorical), ['a', 'b']);
      expect(decodeAdjustmentValue(encodeAdjustmentValue('hi'), AdjustmentType.text), 'hi');
      expect(
        decodeAdjustmentValue(encodeAdjustmentValue(const Duration(minutes: 3)), AdjustmentType.duration),
        const Duration(minutes: 3),
      );
    });

    group('defensive fallback for a non-JSON (un-migrated legacy) row', () {
      test('categorical plain option string ⇒ wrapped', () {
        expect(decodeAdjustmentValue('Open', AdjustmentType.categorical), ['Open']);
      });
      test('text plain string ⇒ itself', () {
        expect(decodeAdjustmentValue('hello world', AdjustmentType.text), 'hello world');
      });
      test('duration legacy H:MM:SS string ⇒ parsed', () {
        expect(decodeAdjustmentValue('0:00:10.000000', AdjustmentType.duration), const Duration(seconds: 10));
      });
    });
  });

  group('decodeLegacyAdjustmentValue (pre-v11 reparse, migration only)', () {
    test('scalars reparse from their toString form', () {
      expect(decodeLegacyAdjustmentValue('true', AdjustmentType.boolean), true);
      expect(decodeLegacyAdjustmentValue('1.5', AdjustmentType.numerical), 1.5);
      expect(decodeLegacyAdjustmentValue('3', AdjustmentType.step), 3);
    });

    test('a categorical value was a plain option string ⇒ one-element list', () {
      expect(decodeLegacyAdjustmentValue('Open', AdjustmentType.categorical), ['Open']);
    });

    test('a JSON-looking option name is preserved whole (multi-select never shipped)', () {
      expect(decodeLegacyAdjustmentValue('[1,2]', AdjustmentType.categorical), ['[1,2]']);
    });

    test('text is identity, duration parses the H:MM:SS form', () {
      expect(decodeLegacyAdjustmentValue('some notes', AdjustmentType.text), 'some notes');
      expect(decodeLegacyAdjustmentValue('0:00:10.000000', AdjustmentType.duration), const Duration(seconds: 10));
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
        final migrated = encodeAdjustmentValue(decodeLegacyAdjustmentValue(raw, type));
        // The migrated value is valid JSON and decodes to the same in-memory value.
        expect(
          decodeAdjustmentValue(migrated, type),
          decodeLegacyAdjustmentValue(raw, type),
          reason: 'round-trip failed for $raw ($type)',
        );
      }
    });
  });

  group('categoricalValueAsList', () {
    test('null ⇒ null', () => expect(categoricalValueAsList(null), isNull));
    test('list passes through as List<String>', () => expect(categoricalValueAsList(['a', 'b']), ['a', 'b']));
    test('legacy String ⇒ one-element list', () => expect(categoricalValueAsList('Open'), ['Open']));
  });

  group('textValueAsString (never hand a List to a TextEditingController)', () {
    test('String passes through', () => expect(textValueAsString('hello'), 'hello'));
    test('null ⇒ null', () => expect(textValueAsString(null), isNull));
    test('a stray List is flattened to text rather than crashing', () {
      expect(textValueAsString(['a', 'b']), 'a, b');
    });
  });

  group('Setup.adjustmentValuesFromJson (backup import) preserves value shape', () {
    test('a JSON array becomes List<String> (categorical multi)', () {
      final result = Setup.adjustmentValuesFromJson({'k': ['Front', 'Rear']});
      expect(result['k'], isA<List<String>>());
      expect(result['k'], ['Front', 'Rear']);
    });

    test('a text value that happens to look like JSON stays a String', () {
      // In a backup this is a JSON *string* (quoted), so it is imported as a
      // Dart String and never confused with a categorical array.
      final result = Setup.adjustmentValuesFromJson({'k': '["abc"]'});
      expect(result['k'], isA<String>());
      expect(result['k'], '["abc"]');
    });
  });
}
