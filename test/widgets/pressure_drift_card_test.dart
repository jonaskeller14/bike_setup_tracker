import 'package:bike_setup_tracker/widgets/pressure_drift_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('formatPressure', () {
    test('uses fewer decimals for larger values', () {
      expect(formatPressure(120.4), '120');
      expect(formatPressure(85.44), '85.4');
      expect(formatPressure(5.125), '5.13');
    });

    test('uses a decimal comma in German', () {
      expect(Intl.withLocale('de', () => formatPressure(120.4)), '120');
      expect(Intl.withLocale('de', () => formatPressure(85.44)), '85,4');
      expect(Intl.withLocale('de', () => formatPressure(5.125)), '5,13');
    });
  });

  group('signedPressure', () {
    test('spells out the sign', () {
      expect(signedPressure(0.5), '+0.50');
      expect(signedPressure(-0.5), '-0.50');
      expect(Intl.withLocale('de', () => signedPressure(-0.5)), '-0,50');
    });
  });

  group('signedPercent', () {
    test('drops the decimal from 10 % on', () {
      expect(signedPercent(0.055), '+5.5 %');
      expect(signedPercent(-0.12), '-12 %');
    });

    test('uses a decimal comma in German', () {
      expect(Intl.withLocale('de', () => signedPercent(0.055)), '+5,5 %');
    });
  });
}
