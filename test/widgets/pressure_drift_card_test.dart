import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/widgets/pressure_drift_card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/german_l10n.dart';

void main() {
  group('formatPressure', () {
    test('uses fewer decimals for larger values', () {
      expect(formatPressure(120.4, englishL10n), '120');
      expect(formatPressure(85.44, englishL10n), '85.4');
      expect(formatPressure(5.125, englishL10n), '5.13');
    });

    test('uses a decimal comma in German', () {
      expect(formatPressure(120.4, germanL10n), '120');
      expect(formatPressure(85.44, germanL10n), '85,4');
      expect(formatPressure(5.125, germanL10n), '5,13');
    });
  });

  group('signedPressure', () {
    test('spells out the sign', () {
      expect(signedPressure(0.5, englishL10n), '+0.50');
      expect(signedPressure(-0.5, englishL10n), '-0.50');
      expect(signedPressure(-0.5, germanL10n), '-0,50');
    });
  });

  group('signedPercent', () {
    test('drops the decimal from 10 % on', () {
      expect(signedPercent(0.055, englishL10n), '+5.5 %');
      expect(signedPercent(-0.12, englishL10n), '-12 %');
    });

    test('uses a decimal comma in German', () {
      expect(signedPercent(0.055, germanL10n), '+5,5 %');
    });
  });
}
