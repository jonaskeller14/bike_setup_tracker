import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/utils/localized_number.dart';
import 'package:bike_setup_tracker/utils/number_input_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/german_l10n.dart';

void main() {
  group('formatLocalizedDouble', () {
    test('uses the decimal separator of the locale', () {
      expect(formatLocalizedDouble(2.5, locale: 'en'), '2.5');
      expect(formatLocalizedDouble(2.5, locale: 'de'), '2,5');
    });

    test('keeps the sign', () {
      expect(formatLocalizedDouble(-0.3, locale: 'en'), '-0.3');
      expect(formatLocalizedDouble(-0.3, locale: 'de'), '-0,3');
    });

    test('shows up to five decimals without trailing zeros', () {
      expect(formatLocalizedDouble(1.0, locale: 'de'), '1');
      expect(formatLocalizedDouble(1.10, locale: 'de'), '1,1');
      expect(formatLocalizedDouble(1.123456, locale: 'de'), '1,12346');
    });

    test('never groups thousands, so the text stays parsable', () {
      expect(formatLocalizedDouble(1234.5, locale: 'en'), '1234.5');
      expect(formatLocalizedDouble(1234.5, locale: 'de'), '1234,5');
      expect(formatLocalizedDouble(1234.5, fractionDigits: 1, locale: 'de'), '1234,5');
      expect(parseLocalizedDouble(formatLocalizedDouble(1234.5, locale: 'de')), 1234.5);
    });

    test('fractionDigits matches toStringAsFixed', () {
      for (final (value, digits) in [(2.5, 2), (1.005, 2), (2.675, 2), (-0.04, 1), (1234.5678, 0), (0.1, 4)]) {
        final expected = value.toStringAsFixed(digits);
        expect(formatLocalizedDouble(value, fractionDigits: digits, locale: 'en'), expected);
        expect(formatLocalizedDouble(value, fractionDigits: digits, locale: 'de'), expected.replaceFirst('.', ','));
      }
    });

    test('defaults to the current locale and follows a language switch', () {
      expect(formatLocalizedDouble(2.5, locale: englishL10n.localeName), '2.5');
      expect(formatLocalizedDouble(2.5, locale: germanL10n.localeName), '2,5');
      expect(formatLocalizedDouble(2.5, fractionDigits: 2, locale: germanL10n.localeName), '2,50');
      expect(formatLocalizedDouble(2.5, locale: englishL10n.localeName), '2.5');
    });

    test('an explicit locale wins over the current one', () {
      expect(formatLocalizedDouble(2.5, locale: 'en'), '2.5');
    });
  });

  group('formatEditableDouble', () {
    test('is empty for no value', () => expect(formatEditableDouble(null, locale: englishL10n.localeName), ''));

    test('has the same shape as toString', () {
      expect(formatEditableDouble(2.0, locale: 'en'), '2.0');
      expect(formatEditableDouble(2.0, locale: 'de'), '2,0');
      expect(formatEditableDouble(-0.5, locale: 'de'), '-0,5');
    });

    test('keeps more digits than display text', () {
      expect(formatEditableDouble(47.376887123, locale: 'de'), '47,376887123');
    });

    test('reads back as the same number in every language', () {
      for (final value in [0.0, 2.5, -0.3, 1234.5, 47.376887123, 0.1 + 0.2, 1e-7]) {
        for (final locale in ['en', 'de']) {
          expect(parseLocalizedDouble(formatEditableDouble(value, locale: locale)), value, reason: '$value in $locale');
        }
      }
    });
  });

  group('localizeDecimalSeparator', () {
    test('leaves a whole number alone', () => expect(localizeDecimalSeparator('55', locale: 'de'), '55'));

    test('replaces the separator', () => expect(localizeDecimalSeparator('52.5', locale: 'de'), '52,5'));
  });
}
