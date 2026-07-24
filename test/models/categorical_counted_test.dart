import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:flutter_test/flutter_test.dart';

/// Coverage for the counted / quantity categorical mode: `multiSelect` and
/// `counted` are independent bools giving four valid states (see
/// doc/20260724_categorical_counted_selection_concept.md).
void main() {
  const options = {'Bar', 'Gel', 'Bottle'};

  CategoricalAdjustment build({bool multiSelect = false, bool counted = false}) => CategoricalAdjustment(
        id: 'adj1',
        name: 'Nutrition',
        notes: null,
        unit: null,
        options: options,
        multiSelect: multiSelect,
        counted: counted,
      );

  group('isValidValue — four-state validation', () {
    test('(false,false) single: one distinct option is valid', () {
      expect(build().isValidValue(['Bar']), isTrue);
    });

    test('(false,false) single: repeats are invalid', () {
      expect(build().isValidValue(['Bar', 'Bar']), isFalse);
    });

    test('(false,false) single: >1 distinct option is invalid', () {
      expect(build().isValidValue(['Bar', 'Gel']), isFalse);
    });

    test('(true,false) multi: distinct options are valid', () {
      expect(build(multiSelect: true).isValidValue(['Bar', 'Gel']), isTrue);
    });

    test('(true,false) multi: repeats are invalid', () {
      expect(build(multiSelect: true).isValidValue(['Bar', 'Bar', 'Gel']), isFalse);
    });

    test('(false,true) counted-single: repeats of one option are valid', () {
      expect(build(counted: true).isValidValue(['Bar', 'Bar', 'Bar', 'Bar']), isTrue);
    });

    test('(false,true) counted-single: >1 distinct option is invalid even if counted', () {
      expect(build(counted: true).isValidValue(['Bar', 'Gel']), isFalse);
    });

    test('(true,true) counted-multi: repeats across multiple options are valid', () {
      expect(build(multiSelect: true, counted: true).isValidValue(['Bar', 'Bar', 'Gel', 'Gel', 'Gel']), isTrue);
    });

    test('empty value is always invalid', () {
      expect(build(multiSelect: true, counted: true).isValidValue(<String>[]), isFalse);
    });

    test('an option outside the option set is always invalid', () {
      expect(build(multiSelect: true, counted: true).isValidValue(['Unknown']), isFalse);
    });
  });

  group('formatValue — count-grouped rendering', () {
    test('groups repeats into "Element (N)"', () {
      expect(Adjustment.formatValue(['Bar', 'Bar', 'Gel', 'Gel', 'Gel']), 'Bar (2), Gel (3)');
    });

    test('a single occurrence omits the count', () {
      expect(Adjustment.formatValue(['Bottle']), 'Bottle');
    });
  });

  group('JSON version', () {
    test('counted adjustment serializes to version 3', () {
      expect(build(counted: true).toJson()['version'], 3);
    });

    test('counted+multi adjustment also serializes to version 3', () {
      expect(build(multiSelect: true, counted: true).toJson()['version'], 3);
    });

    test('toJson always carries the counted flag', () {
      expect(build(counted: true).toJson()['counted'], true);
      expect(build(counted: false).toJson()['counted'], false);
    });

    test('fromJson round-trips counted', () {
      final original = build(multiSelect: true, counted: true);
      final restored = CategoricalAdjustment.fromJson(original.toJson());
      expect(restored, equals(original));
      expect(restored.counted, isTrue);
    });

    test('legacy json without a counted key defaults to false', () {
      final adj = CategoricalAdjustment.fromJson({
        'version': 1,
        'id': 'adj1',
        'name': 'Mode',
        'notes': null,
        'unit': null,
        'options': ['Open', 'Firm'],
      });
      expect(adj.counted, isFalse);
    });
  });
}
