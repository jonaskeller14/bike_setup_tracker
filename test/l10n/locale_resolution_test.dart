import 'dart:ui';

import 'package:bike_setup_tracker/l10n/locale_resolution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const english = Locale('en');
  const german = Locale('de');

  group('resolveAppLocale', () {
    test('flag off forces English even on a German device', () {
      final locale = resolveAppLocale(enabled: false, deviceLocales: const [german]);
      expect(locale, english);
    });

    test('flag off ignores a stored override', () {
      final locale = resolveAppLocale(enabled: false, override: 'de', deviceLocales: const [german]);
      expect(locale, english);
    });

    test('flag on follows a German device', () {
      final locale = resolveAppLocale(enabled: true, deviceLocales: const [german]);
      expect(locale, german);
    });

    test('flag on drops the region of the device locale', () {
      final locale = resolveAppLocale(enabled: true, deviceLocales: const [Locale('de', 'CH')]);
      expect(locale, german);
    });

    test('override wins over the device language', () {
      expect(resolveAppLocale(enabled: true, override: 'en', deviceLocales: const [german]), english);
      expect(resolveAppLocale(enabled: true, override: 'de', deviceLocales: const [english]), german);
    });

    test('an unsupported override falls back to the device language', () {
      final locale = resolveAppLocale(enabled: true, override: 'fr', deviceLocales: const [german]);
      expect(locale, german);
    });

    test('uses the first supported device locale', () {
      final locale = resolveAppLocale(
        enabled: true,
        deviceLocales: const [Locale('fr'), german, english],
      );
      expect(locale, german);
    });

    test('an unsupported device language falls back to English', () {
      final locale = resolveAppLocale(enabled: true, deviceLocales: const [Locale('fr')]);
      expect(locale, english);
    });

    test('no device locales falls back to English', () {
      expect(resolveAppLocale(enabled: true, deviceLocales: const []), english);
    });
  });
}
