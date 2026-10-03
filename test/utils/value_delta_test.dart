import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/utils/value_delta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatValueDelta', () {
    test('signs the difference of ordered values', () {
      expect(formatValueDelta(const StepValue(8), const StepValue(10)), '+2');
      expect(formatValueDelta(const StepValue(-4), const StepValue(-9)), '−5');
      expect(formatValueDelta(const NumericalValue(23.5), const NumericalValue(22)), '−1.5');
      expect(formatValueDelta(const NumericalValue(0.1), const NumericalValue(0.3)), '+0.2');
      expect(formatValueDelta(const StepValue(3), const StepValue(3)), '±0');
    });

    test('drops zero hours from a duration difference', () {
      expect(
        formatValueDelta(
          const DurationValue(Duration(minutes: 1, seconds: 32)),
          const DurationValue(Duration(minutes: 1, seconds: 27)),
        ),
        '−00:05',
      );
      expect(
        formatValueDelta(const DurationValue(Duration.zero), const DurationValue(Duration(hours: 1, seconds: 1))),
        '+01:00:01',
      );
    });

    test('has no delta for unordered values or a missing side', () {
      expect(formatValueDelta(const BooleanValue(false), const BooleanValue(true)), isNull);
      expect(formatValueDelta(CategoricalValue(const ['Soft']), CategoricalValue(const ['Hard'])), isNull);
      expect(formatValueDelta(TextValue.orNull('a'), TextValue.orNull('b')), isNull);
      expect(formatValueDelta(null, const StepValue(2)), isNull);
      expect(formatValueDelta(const StepValue(2), null), isNull);
    });
  });
}
