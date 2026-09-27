import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/rating/rating_entry.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Setup typed values', () {
    late Setup setup;

    setUp(() {
      setup =
          Setup(
              datetime: DateTime.utc(2026, 9, 27),
              datetimeLocal: DateTime(2026, 9, 27),
              tags: {},
              bike: 'b1',
              person: 'p1',
              bikeAdjustmentValues: {
                'bool': true,
                'step': 3,
                'num': 89.5,
                'text': 'Soft',
                'cat': ['Front', 'Rear'],
                'dur': const Duration(minutes: 1, seconds: 30),
                'empty': '',
                'absent': null,
              },
              personAdjustmentValues: {'weight': 72.0},
            )
            ..previousBikeAdjustmentValues = {'step': 2}
            ..previousPersonAdjustmentValues = {'weight': 71.0};
    });

    test('bikeValue wraps each runtime type in its AdjustmentValue', () {
      expect(setup.bikeValue('bool'), const BooleanValue(true));
      expect(setup.bikeValue('step'), const StepValue(3));
      expect(setup.bikeValue('num'), const NumericalValue(89.5));
      expect(setup.bikeValue('text'), TextValue.orNull('Soft'));
      expect(setup.bikeValue('cat'), CategoricalValue(['Front', 'Rear']));
      expect(setup.bikeValue('dur'), const DurationValue(Duration(minutes: 1, seconds: 30)));
    });

    test('absent, null and empty text values are null', () {
      expect(setup.bikeValue('missing'), isNull);
      expect(setup.bikeValue('absent'), isNull);
      expect(setup.bikeValue('empty'), isNull);
    });

    test('person and previous values read their own maps', () {
      expect(setup.personValue('weight'), const NumericalValue(72.0));
      expect(setup.personValue('step'), isNull);
      expect(setup.previousBikeValue('step'), const StepValue(2));
      expect(setup.previousPersonValue('weight'), const NumericalValue(71.0));
    });

    test('value entries skip absent values and keep order', () {
      expect(setup.bikeValueEntries.map((e) => e.key), ['bool', 'step', 'num', 'text', 'cat', 'dur']);
      expect(setup.bikeValueEntries.firstWhere((e) => e.key == 'cat').value, CategoricalValue(['Front', 'Rear']));
      expect(setup.personValueEntries.single.value, const NumericalValue(72.0));
    });
  });

  group('RatingEntry typed values', () {
    final entry = RatingEntry(
      bike: 'b1',
      setupId: 's1',
      dateTimeUTC: DateTime.utc(2026, 9, 27),
      dateTimeLocal: DateTime(2026, 9, 27),
      metricValues: {
        'grip': 4,
        'feel': ['Plush'],
        'note': '',
      },
    );

    test('metricValue wraps runtime values', () {
      expect(entry.metricValue('grip'), const StepValue(4));
      expect(entry.metricValue('feel'), CategoricalValue(['Plush']));
      expect(entry.metricValue('note'), isNull);
      expect(entry.metricValue('missing'), isNull);
    });

    test('metricValueEntries skips absent values', () {
      expect(entry.metricValueEntries.map((e) => e.key), ['grip', 'feel']);
    });
  });
}
