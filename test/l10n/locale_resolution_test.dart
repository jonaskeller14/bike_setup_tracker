import 'dart:io';
import 'dart:ui';

import 'package:bike_setup_tracker/l10n/l10n.dart';
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

    test('keeps the region of the device locale', () {
      final locale = resolveAppLocale(deviceLocales: const [Locale('de', 'CH')]);
      expect(locale, const Locale('de', 'CH'));
    });

    test('an English device keeps its region', () {
      expect(resolveAppLocale(deviceLocales: const [Locale('en', 'AU')]), const Locale('en', 'AU'));
      expect(resolveAppLocale(deviceLocales: const [Locale('en', 'DE')]), const Locale('en', 'DE'));
    });

    test('override wins over the device language', () {
      expect(resolveAppLocale(override: 'en', deviceLocales: const [german]), english);
      expect(resolveAppLocale(override: 'de', deviceLocales: const [english]), german);
    });

    test('override takes the language only, the region stays the device\'s', () {
      final locale = resolveAppLocale(override: 'de', deviceLocales: const [Locale('en', 'AU')]);
      expect(locale, const Locale('de', 'AU'));
    });

    test('an unsupported override falls back to the device language', () {
      final locale = resolveAppLocale(override: 'xx', deviceLocales: const [german]);
      expect(locale, german);
    });

    test('uses the first supported device locale', () {
      final locale = resolveAppLocale(
        deviceLocales: const [Locale('xx'), german, english],
      );
      expect(locale, german);
    });

    test('an unsupported device language falls back to English in the device region', () {
      expect(resolveAppLocale(deviceLocales: const [Locale('xx')]), english);
      expect(resolveAppLocale(deviceLocales: const [Locale('xx', 'CH')]), const Locale('en', 'CH'));
    });

    test('no device locales falls back to English', () {
      expect(resolveAppLocale(deviceLocales: const []), english);
    });
  });

  test('the platform language lists name exactly the supported languages', () {
    final supported = AppLocalizations.supportedLocales.map((locale) => locale.languageCode).toSet();
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final iosLanguages = RegExp(r'<key>CFBundleLocalizations</key>\s*<array>(.*?)</array>', dotAll: true)
        .firstMatch(plist)!
        .group(1)!;
    final androidLanguages = File('android/app/src/main/res/xml/locales_config.xml').readAsStringSync();

    expect(RegExp(r'<string>(\w+)</string>').allMatches(iosLanguages).map((m) => m.group(1)).toSet(), supported);
    expect(RegExp(r'android:name="(\w+)"').allMatches(androidLanguages).map((m) => m.group(1)).toSet(), supported);
  });

  group('deviceRegionCode', () {
    test('is the region of the first device locale', () {
      expect(deviceRegionCode(const [Locale('en', 'AU'), Locale('de', 'DE')]), 'AU');
    });

    test('is null without a region or locales', () {
      expect(deviceRegionCode(const [german]), isNull);
      expect(deviceRegionCode(const []), isNull);
    });
  });

  group('keepRegionLocale', () {
    const supported = [german, english];

    test('keeps the region of a supported language', () {
      expect(keepRegionLocale(const Locale('en', 'GB'), supported), const Locale('en', 'GB'));
    });

    test('leaves an unsupported language to the default resolution', () {
      expect(keepRegionLocale(const Locale('xx', 'FR'), supported), isNull);
      expect(keepRegionLocale(null, supported), isNull);
    });
  });
}
