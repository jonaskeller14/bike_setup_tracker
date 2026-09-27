import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/rating/rating_entry.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Setup.adjustmentValuesFromJson with adjustment types', () {
    Map<String, dynamic> decode(dynamic value, AdjustmentType type) =>
        Setup.adjustmentValuesFromJson({'k': value}, adjustmentTypes: {'k': type});

    test('a text value that looks like a duration stays a String', () {
      expect(decode('01:30:00', AdjustmentType.text)['k'], '01:30:00');
    });

    test('a duration string becomes a Duration', () {
      expect(decode('1:30:00.000000', AdjustmentType.duration)['k'], const Duration(hours: 1, minutes: 30));
    });

    test('an unparseable duration string becomes null', () {
      expect(decode('soon', AdjustmentType.duration)['k'], isNull);
    });

    test('a legacy single-select categorical becomes a one-element list', () {
      final value = decode('Front', AdjustmentType.categorical)['k'];
      expect(value, isA<List<String>>());
      expect(value, ['Front']);
    });

    test('a categorical array becomes List<String>', () {
      final value = decode(<dynamic>['A', 'B'], AdjustmentType.categorical)['k'];
      expect(value, isA<List<String>>());
      expect(value, ['A', 'B']);
    });

    test('empty text becomes null', () {
      final result = decode('', AdjustmentType.text);
      expect(result.containsKey('k'), isTrue);
      expect(result['k'], isNull);
    });

    test('an integral numerical value becomes a double', () {
      final value = decode(89, AdjustmentType.numerical)['k'];
      expect(value, isA<double>());
      expect(value, 89.0);
    });

    test('a step value becomes an int', () {
      final value = decode(3, AdjustmentType.step)['k'];
      expect(value, isA<int>());
      expect(value, 3);
    });

    test('a boolean stays a bool', () {
      expect(decode(true, AdjustmentType.boolean)['k'], true);
    });

    test('null stays null', () {
      expect(decode(null, AdjustmentType.step)['k'], isNull);
    });

    test('a value whose shape does not fit its type falls back to the shape heuristic', () {
      expect(decode('abc', AdjustmentType.numerical)['k'], 'abc');
    });

    test('ids without a known type use the shape heuristic', () {
      final result = Setup.adjustmentValuesFromJson(
        {'known': '01:30:00', 'unknown': '01:30:00'},
        adjustmentTypes: {'known': AdjustmentType.text},
      );
      expect(result['known'], '01:30:00');
      expect(result['unknown'], const Duration(hours: 1, minutes: 30));
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

      expect(setup.bikeAdjustmentValues['note'], '0:10:00');
      expect(setup.bikeAdjustmentValues['cat'], ['Front']);
      expect(setup.personAdjustmentValues['weight'], isA<double>());
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

      expect(entry.metricValues['comment'], '0:10:00');
      expect(entry.metricValues['score'], isA<double>());
    });
  });
}
