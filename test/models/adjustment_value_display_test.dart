import 'package:bike_setup_tracker/l10n/adjustment_value_text.dart';
import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/german_l10n.dart';

void main() {
  group('AdjustmentValue.display', () {
    group('TextValue', () {
      test('non-empty string', () => expect(TextValue.orNull('hello')!.displayText(englishL10n), 'hello'));
    });

    group('BooleanValue', () {
      test('true returns On', () => expect(const BooleanValue(true).displayText(englishL10n), 'On'));
      test('false returns Off', () => expect(const BooleanValue(false).displayText(englishL10n), 'Off'));
    });

    group('NumericalValue', () {
      String display(double value) => NumericalValue(value).displayText(englishL10n);

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

    group('NumericalValue in German', () {
      String display(double value) => NumericalValue(value).displayText(germanL10n);

      test('1.5', () => expect(display(1.5), '1,5'));
      test('-1.5', () => expect(display(-1.5), '-1,5'));
      test('1.0', () => expect(display(1.0), '1'));
      test('1000.5 has no thousands separator', () => expect(display(1000.5), '1000,5'));
      test('1.123456 rounds to 5 decimals', () => expect(display(1.123456), '1,12346'));

      test('does not change what is stored', () {
        expect(const NumericalValue(1.5).encode(), '1.5');
      });
    });

    group('StepValue', () {
      test('0', () => expect(const StepValue(0).displayText(englishL10n), '0'));
      test('42', () => expect(const StepValue(42).displayText(englishL10n), '42'));
      test('-42', () => expect(const StepValue(-42).displayText(englishL10n), '-42'));
      test('1000', () => expect(const StepValue(1000).displayText(englishL10n), '1000'));
    });

    group('DurationValue', () {
      test('zero', () => expect(const DurationValue(Duration.zero).displayText(englishL10n), '00:00:00'));
      test(
        '1h 30m 5s',
        () => expect(const DurationValue(Duration(hours: 1, minutes: 30, seconds: 5)).displayText(englishL10n), '01:30:05'),
      );
      test('hours > 24', () => expect(const DurationValue(Duration(hours: 100)).displayText(englishL10n), '100:00:00'));
      test('seconds only', () => expect(const DurationValue(Duration(seconds: 9)).displayText(englishL10n), '00:00:09'));
    });

    group('CategoricalValue (multi-select)', () {
      test('joins values with a comma', () => expect(CategoricalValue(const ['Front', 'Rear']).displayText(englishL10n), 'Front, Rear'));
      test('single-element list shows just the value', () => expect(CategoricalValue(const ['Front']).displayText(englishL10n), 'Front'));
      test('empty list returns dash', () => expect(CategoricalValue(const []).displayText(englishL10n), '-'));
    });

    group('CategoricalValue (counted, grouped rendering)', () {
      test('groups repeats with a count suffix', () {
        expect(CategoricalValue(const ['Bar', 'Bar', 'Gel', 'Gel', 'Gel']).displayText(englishL10n), 'Bar (2), Gel (3)');
      });
      test('omits (1) for a non-repeated element', () => expect(CategoricalValue(const ['Bottle']).displayText(englishL10n), 'Bottle'));
      test('mixes repeated and single-count elements', () {
        expect(CategoricalValue(const ['Bar', 'Bar', 'Bottle']).displayText(englishL10n), 'Bar (2), Bottle');
      });
      test('preserves first-occurrence order, not sorted', () {
        expect(CategoricalValue(const ['Gel', 'Bar', 'Gel', 'Bar']).displayText(englishL10n), 'Gel (2), Bar (2)');
      });
    });
  });
}
