import 'package:flutter/widgets.dart';

import '../models/app_settings.dart';
import 'app_localizations.dart';

const _fallbackLocale = Locale('en');

/// The device's region: a region is a device-wide setting, so the first locale
/// speaks for all of them.
String? deviceRegionCode(List<Locale> deviceLocales) =>
    deviceLocales.isEmpty ? null : deviceLocales.first.countryCode;

Locale resolveAppLocale({
  String? override, // lang = override ?? supported device language ?? english
  required List<Locale> deviceLocales,
}) {
  final supported = AppLocalizations.supportedLocales.map((locale) => locale.languageCode).toSet();
  // The region comes from the device whatever the language, so an English
  // phone in Australia gets Australian dates and a Monday week start.
  final region = deviceRegionCode(deviceLocales);
  // A stored code the app no longer supports falls through to the system language.
  if (override != null && supported.contains(override)) return Locale(override, region);
  for (final deviceLocale in deviceLocales) {
    if (supported.contains(deviceLocale.languageCode)) return Locale(deviceLocale.languageCode, region);
  }
  return Locale(_fallbackLocale.languageCode, region);
}

/// Flutter's default resolution would turn `en_AU` back into `en`, because only
/// languages are listed as supported. The strings are per language; the region
/// is for the Material and calendar data that have regional variants.
Locale? keepRegionLocale(Locale? locale, Iterable<Locale> supportedLocales) {
  if (locale == null) return null;
  final supported = supportedLocales.any((supportedLocale) => supportedLocale.languageCode == locale.languageCode);
  return supported ? locale : null;
}

Locale appLocaleOf(AppSettings settings) => resolveAppLocale(
  override: settings.localeCode,
  deviceLocales: WidgetsBinding.instance.platformDispatcher.locales,
);
