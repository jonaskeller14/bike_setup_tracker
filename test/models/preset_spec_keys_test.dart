import 'package:bike_setup_tracker/models/component/preset_spec_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('SpecKey', () {
    final key = PresetSpecKeys.eyeToEyeMm;

    test('format stays language-neutral for catalog labels and stored notes', () {
      expect(Intl.withLocale('de', () => key.format(52.5)), '52.5 mm');
    });

    test('display follows the app language', () {
      expect(key.display(52.5), '52.5 mm');
      expect(Intl.withLocale('de', () => key.display(52.5)), '52,5 mm');
    });

    test('display drops the decimals of a whole number, like format', () {
      expect(key.display(55.0), key.format(55.0));
      expect(Intl.withLocale('de', () => key.display(55.0)), '55 mm');
    });
  });
}
