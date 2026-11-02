import 'dart:ui';

import 'package:bike_setup_tracker/l10n/locale_resolution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const english = Locale('en');
  const german = Locale('de');

  group('resolveAppLocale', () {
    test('follows a German device', () {
      final locale = resolveAppLocale(deviceLocales: const [german]);
      expect(locale, german);
    });

    test('drops the region of the device locale', () {
      final locale = resolveAppLocale(deviceLocales: const [Locale('de', 'CH')]);
      expect(locale, german);
    });

    test('override wins over the device language', () {
      expect(resolveAppLocale(override: 'en', deviceLocales: const [german]), english);
      expect(resolveAppLocale(override: 'de', deviceLocales: const [english]), german);
    });

    test('an unsupported override falls back to the device language', () {
      final locale = resolveAppLocale(override: 'fr', deviceLocales: const [german]);
      expect(locale, german);
    });

    test('uses the first supported device locale', () {
      final locale = resolveAppLocale(
        deviceLocales: const [Locale('fr'), german, english],
      );
      expect(locale, german);
    });

    test('an unsupported device language falls back to English', () {
      final locale = resolveAppLocale(deviceLocales: const [Locale('fr')]);
      expect(locale, english);
    });

    test('no device locales falls back to English', () {
      expect(resolveAppLocale(deviceLocales: const []), english);
    });
  });
}
