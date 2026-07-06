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

  group('encodeAdjustmentValue', () {
    test('encodes a list as a JSON array', () {
      expect(encodeAdjustmentValue(['Open', 'Firm']), '["Open","Firm"]');
    });

    test('encodes a single-select one-element list as a JSON array', () {
      expect(encodeAdjustmentValue(['Open']), '["Open"]');
    });

    test('leaves non-list (scalar) values as their string form', () {
      expect(encodeAdjustmentValue(true), 'true');
      expect(encodeAdjustmentValue(42), '42');
    });
  });

  group('decodeCategoricalValue', () {
    test('multi: JSON array ⇒ list', () {
      expect(decodeCategoricalValue('["Open","Firm"]', multiSelect: true), ['Open', 'Firm']);
    });

    test('multi: defensive wrap of a non-array', () {
      expect(decodeCategoricalValue('Open', multiSelect: true), ['Open']);
    });

    test('single: new one-element array ⇒ that element', () {
      expect(decodeCategoricalValue('["Open"]', multiSelect: false), ['Open']);
    });

    test('single: legacy plain string ⇒ wrapped', () {
      expect(decodeCategoricalValue('Open', multiSelect: false), ['Open']);
    });

    test('single: legacy JSON-looking option name is preserved, not split', () {
      // The pathological case: an option literally named "[1,2]". A multi-element
      // array under a single-select adjustment can only be such a legacy value.
      expect(decodeCategoricalValue('[1,2]', multiSelect: false), ['[1,2]']);
    });

    test('encode → decode round-trips for single and multi', () {
      expect(decodeCategoricalValue(encodeAdjustmentValue(['Open']), multiSelect: false), ['Open']);
      expect(decodeCategoricalValue(encodeAdjustmentValue(['Open', 'Firm']), multiSelect: true), ['Open', 'Firm']);
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
