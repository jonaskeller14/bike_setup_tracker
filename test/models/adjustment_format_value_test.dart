import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Adjustment.formatValue', () {
    group('null', () {
      test('returns dash', () => expect(Adjustment.formatValue(null), '-'));
    });

    group('String', () {
      test('empty string', () => expect(Adjustment.formatValue(''), ''));
      test('non-empty string', () => expect(Adjustment.formatValue('hello'), 'hello'));
    });

    group('bool', () {
      test('true returns On', () => expect(Adjustment.formatValue(true), 'On'));
      test('false returns Off', () => expect(Adjustment.formatValue(false), 'Off'));
    });

    group('double', () {
      test('0.0', () => expect(Adjustment.formatValue(0.0), '0'));
      test('1.0', () => expect(Adjustment.formatValue(1.0), '1'));
      test('-1.0', () => expect(Adjustment.formatValue(-1.0), '-1'));
      test('1000.0', () => expect(Adjustment.formatValue(1000.0), '1000'));
      test('0.1', () => expect(Adjustment.formatValue(0.1), '0.1'));
      test('1.5', () => expect(Adjustment.formatValue(1.5), '1.5'));
      test('-1.5', () => expect(Adjustment.formatValue(-1.5), '-1.5'));
      test('1.12345 (5 decimals)', () => expect(Adjustment.formatValue(1.12345), '1.12345'));
      test('1.123456 rounds to 5 decimals', () => expect(Adjustment.formatValue(1.123456), '1.12346'));
      test('1.10 strips trailing zero', () => expect(Adjustment.formatValue(1.10), '1.1'));
      test('0.00 strips trailing zeros', () => expect(Adjustment.formatValue(0.00), '0'));
    });

    group('int', () {
      test('0', () => expect(Adjustment.formatValue(0), '0'));
      test('42', () => expect(Adjustment.formatValue(42), '42'));
      test('-42', () => expect(Adjustment.formatValue(-42), '-42'));
      test('1000', () => expect(Adjustment.formatValue(1000), '1000'));
    });

    group('Duration', () {
      test('zero', () => expect(Adjustment.formatValue(Duration.zero), '00:00:00'));
      test('1h 30m 5s', () => expect(Adjustment.formatValue(const Duration(hours: 1, minutes: 30, seconds: 5)), '01:30:05'));
      test('hours > 24', () => expect(Adjustment.formatValue(const Duration(hours: 100)), '100:00:00'));
      test('seconds only', () => expect(Adjustment.formatValue(const Duration(seconds: 9)), '00:00:09'));
    });

    group('List (multi-select categorical)', () {
      test('joins values with a comma', () => expect(Adjustment.formatValue(['Front', 'Rear']), 'Front, Rear'));
      test('single-element list shows just the value', () => expect(Adjustment.formatValue(['Front']), 'Front'));
      test('empty list returns dash', () => expect(Adjustment.formatValue(<String>[]), '-'));
      test('formats elements individually', () => expect(Adjustment.formatValue([1, 2]), '1, 2'));
    });
  });
}
