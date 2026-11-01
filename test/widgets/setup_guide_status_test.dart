import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/widgets/setup_guide_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/german_l10n.dart';

void main() {
  group('guideSignedDelta', () {
    test('rounds to one decimal and spells out the sign', () {
      expect(guideSignedDelta(1.5, englishL10n), '+1.5');
      expect(guideSignedDelta(-1.54, englishL10n), '-1.5');
    });

    test('drops the decimal of a whole number', () {
      expect(guideSignedDelta(2, englishL10n), '+2');
      expect(guideSignedDelta(-2.04, englishL10n), '-2');
    });

    test('rounds a tiny difference to an unsigned zero', () {
      expect(guideSignedDelta(0.04, englishL10n), '+0');
      expect(guideSignedDelta(-0.04, englishL10n), '+0');
    });

    test('uses a decimal comma in German', () {
      expect(guideSignedDelta(-1.5, germanL10n), '-1,5');
    });
  });
}
