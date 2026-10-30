import 'package:bike_setup_tracker/widgets/setup_guide_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('guideSignedDelta', () {
    test('rounds to one decimal and spells out the sign', () {
      expect(guideSignedDelta(1.5), '+1.5');
      expect(guideSignedDelta(-1.54), '-1.5');
    });

    test('drops the decimal of a whole number', () {
      expect(guideSignedDelta(2), '+2');
      expect(guideSignedDelta(-2.04), '-2');
    });

    test('rounds a tiny difference to an unsigned zero', () {
      expect(guideSignedDelta(0.04), '+0');
      expect(guideSignedDelta(-0.04), '+0');
    });

    test('uses a decimal comma in German', () {
      expect(Intl.withLocale('de', () => guideSignedDelta(-1.5)), '-1,5');
    });
  });
}
