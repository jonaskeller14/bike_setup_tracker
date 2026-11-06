import 'package:bike_setup_tracker/l10n/catalog_labels.dart';
import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/models/component/preset_spec_keys.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/german_l10n.dart';

void main() {
  group('SpecKey', () {
    final key = PresetSpecKeys.eyeToEyeMm;

    test('format stays language-neutral for catalog labels and stored notes', () {
      expect(key.format(52.5), '52.5 mm');
    });

    test('display follows the app language', () {
      expect(key.display(52.5, englishL10n), '52.5 mm');
      expect(key.display(52.5, germanL10n), '52,5 mm');
    });

    test('display drops the decimals of a whole number, like format', () {
      expect(key.display(55.0, englishL10n), key.format(55.0));
      expect(key.display(55.0, germanL10n), '55 mm');
    });
  });
}
