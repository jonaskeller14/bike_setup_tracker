import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdjustmentValue.display', () {
    group('TextValue', () {
      test('non-empty string', () => expect(TextValue.orNull('hello')!.display, 'hello'));
    });

    group('BooleanValue', () {
      test('true returns On', () => expect(const BooleanValue(true).display, 'On'));
      test('false returns Off', () => expect(const BooleanValue(false).display, 'Off'));
    });

    group('NumericalValue', () {
      String display(double value) => NumericalValue(value).display;

      test('0.0', () => expect(display(0.0), '0'));
      test('1.0', () => expect(display(1.0), '1'));
      test('-1.0', () => expect(display(-1.0), '-1'));
      test('1000.0', () => expect(display(1000.0), '1000'));
      test('0.1', () => expect(display(0.1), '0.1'));
      test('1.5', () => expect(display(1.5), '1.5'));
      test('-1.5', () => expect(display(-1.5), '-1.5'));
      test('1.12345 (5 decimals)', () => expect(display(1.12345), '1.12345'));
      test('1.123456 rounds to 5 decimals', () => expect(display(1.123456), '1.12346'));
      test('1.10 strips trailing zero', () => expect(display(1.10), '1.1'));
      test('0.00 strips trailing zeros', () => expect(display(0.00), '0'));
    });

    group('StepValue', () {
      test('0', () => expect(const StepValue(0).display, '0'));
      test('42', () => expect(const StepValue(42).display, '42'));
      test('-42', () => expect(const StepValue(-42).display, '-42'));
      test('1000', () => expect(const StepValue(1000).display, '1000'));
    });

    group('DurationValue', () {
      test('zero', () => expect(const DurationValue(Duration.zero).display, '00:00:00'));
      test(
        '1h 30m 5s',
        () => expect(const DurationValue(Duration(hours: 1, minutes: 30, seconds: 5)).display, '01:30:05'),
      );
      test('hours > 24', () => expect(const DurationValue(Duration(hours: 100)).display, '100:00:00'));
      test('seconds only', () => expect(const DurationValue(Duration(seconds: 9)).display, '00:00:09'));
    });

    group('CategoricalValue (multi-select)', () {
      test('joins values with a comma', () => expect(CategoricalValue(['Front', 'Rear']).display, 'Front, Rear'));
      test('single-element list shows just the value', () => expect(CategoricalValue(['Front']).display, 'Front'));
      test('empty list returns dash', () => expect(CategoricalValue([]).display, '-'));
    });

    group('CategoricalValue (counted, grouped rendering)', () {
      test('groups repeats with a count suffix', () {
        expect(CategoricalValue(['Bar', 'Bar', 'Gel', 'Gel', 'Gel']).display, 'Bar (2), Gel (3)');
      });
      test('omits (1) for a non-repeated element', () => expect(CategoricalValue(['Bottle']).display, 'Bottle'));
      test('mixes repeated and single-count elements', () {
        expect(CategoricalValue(['Bar', 'Bar', 'Bottle']).display, 'Bar (2), Bottle');
      });
      test('preserves first-occurrence order, not sorted', () {
        expect(CategoricalValue(['Gel', 'Bar', 'Gel', 'Bar']).display, 'Gel (2), Bar (2)');
      });
    });
  });
}
