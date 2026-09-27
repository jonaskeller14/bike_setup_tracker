import 'dart:convert';

import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/rating/rating_entry.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Setup.adjustmentValuesFromJson with adjustment types', () {
    Map<String, AdjustmentValue> decode(dynamic value, AdjustmentType type) =>
        Setup.adjustmentValuesFromJson({'k': value}, adjustmentTypes: {'k': type});

    test('a text value that looks like a duration stays a String', () {
      expect(decode('01:30:00', AdjustmentType.text)['k'], TextValue.orNull('01:30:00'));
    });

    test('a duration string becomes a Duration', () {
      expect(decode('1:30:00.000000', AdjustmentType.duration)['k'], const DurationValue(Duration(hours: 1, minutes: 30)));
    });

    test('an unparseable duration string becomes null', () {
      expect(decode('soon', AdjustmentType.duration)['k'], isNull);
    });

    test('a legacy single-select categorical becomes a one-element list', () {
      expect(decode('Front', AdjustmentType.categorical)['k'], CategoricalValue(['Front']));
    });

    test('a categorical array becomes a categorical value', () {
      expect(decode(<dynamic>['A', 'B'], AdjustmentType.categorical)['k'], CategoricalValue(['A', 'B']));
    });

    test('empty text is dropped', () {
      expect(decode('', AdjustmentType.text), isEmpty);
    });

    test('an integral numerical value becomes a double', () {
      expect(decode(89, AdjustmentType.numerical)['k'], const NumericalValue(89.0));
    });

    test('a step value becomes an int', () {
      expect(decode(3, AdjustmentType.step)['k'], const StepValue(3));
    });

    test('a boolean stays a bool', () {
      expect(decode(true, AdjustmentType.boolean)['k'], const BooleanValue(true));
    });

    test('null is dropped', () {
      expect(decode(null, AdjustmentType.step), isEmpty);
    });

    test('a value whose shape does not fit its type falls back to the shape heuristic', () {
      expect(decode('abc', AdjustmentType.numerical)['k'], TextValue.orNull('abc'));
    });

    test('ids without a known type use the shape heuristic', () {
      final result = Setup.adjustmentValuesFromJson(
        {'known': '01:30:00', 'unknown': '01:30:00'},
        adjustmentTypes: {'known': AdjustmentType.text},
      );
      expect(result['known'], TextValue.orNull('01:30:00'));
      expect(result['unknown'], const DurationValue(Duration(hours: 1, minutes: 30)));
    });

    test('a JSON shape no value type fits is kept unresolved', () {
      final result = Setup.adjustmentValuesFromJson({'unknown': {'x': 1}});
      expect(result['unknown'], const UnresolvedValue('{"x":1}'));
    });
  });

  group('Setup.adjustmentValuesToJson', () {
    final values = <String, AdjustmentValue>{
      'bool': const BooleanValue(true),
      'step': const StepValue(3),
      'num': const NumericalValue(89.0),
      'text': TextValue.orNull('01:30:00')!,
      'cat': CategoricalValue(['A', 'B', 'A']),
      'dur': const DurationValue(Duration(hours: 1, minutes: 30)),
    };
    final types = {
      'bool': AdjustmentType.boolean,
      'step': AdjustmentType.step,
      'num': AdjustmentType.numerical,
      'text': AdjustmentType.text,
      'cat': AdjustmentType.categorical,
      'dur': AdjustmentType.duration,
    };

    test('keeps the backup JSON shapes', () {
      expect(Setup.adjustmentValuesToJson(values), {
        'bool': true,
        'step': 3,
        'num': 89.0,
        'text': '01:30:00',
        'cat': ['A', 'B', 'A'],
        'dur': '1:30:00.000000',
      });
    });

    test('round-trips through adjustmentValuesFromJson', () {
      final json = jsonDecode(jsonEncode(Setup.adjustmentValuesToJson(values))) as Map<String, dynamic>;
      expect(Setup.adjustmentValuesFromJson(json, adjustmentTypes: types), values);
    });

    test('exports an unresolved value as its decoded raw JSON', () {
      expect(
        Setup.adjustmentValuesToJson({'a': const UnresolvedValue('{"x":1}'), 'b': const UnresolvedValue('not json')}),
        {'a': {'x': 1}, 'b': 'not json'},
      );
    });
  });

  group('fromJson passes adjustment types through', () {
    test('Setup.fromJson decodes bike and person values by type', () {
      final setup = Setup.fromJson(
        json: {
          'version': 7,
          'id': 's1',
          'datetime': '2026-09-27T09:00:00.000Z',
          'bike': 'b1',
          'person': 'p1',
          'bikeAdjustmentValues': {'note': '0:10:00', 'cat': 'Front'},
          'personAdjustmentValues': {'weight': 72},
        },
        adjustmentTypes: {
          'note': AdjustmentType.text,
          'cat': AdjustmentType.categorical,
          'weight': AdjustmentType.numerical,
        },
      );

      expect(setup.bikeAdjustmentValues['note'], TextValue.orNull('0:10:00'));
      expect(setup.bikeAdjustmentValues['cat'], CategoricalValue(['Front']));
      expect(setup.personAdjustmentValues['weight'], isA<NumericalValue>());
    });

    test('RatingEntry.fromJson decodes metric values by type', () {
      final entry = RatingEntry.fromJson(
        json: {
          'version': 1,
          'id': 'r1',
          'bike': 'b1',
          'setupId': 's1',
          'dateTimeUTC': '2026-09-27T09:00:00.000Z',
          'metricValues': {'comment': '0:10:00', 'score': 4},
        },
        metricTypes: {'comment': AdjustmentType.text, 'score': AdjustmentType.numerical},
      );

      expect(entry.metricValues['comment'], TextValue.orNull('0:10:00'));
      expect(entry.metricValues['score'], const NumericalValue(4.0));
    });
  });
}
