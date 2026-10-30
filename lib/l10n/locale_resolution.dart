import 'dart:ui';

import 'app_localizations.dart';

const _fallbackLocale = Locale('en');

/// The language the app UI runs in.
///
/// While [enabled] is false the app stays English even on a German device, so a
/// half-translated UI never reaches users. Otherwise an [override] wins, then
/// the first supported device language, then English.
Locale resolveAppLocale({
  required bool enabled,
  String? override,
  required List<Locale> deviceLocales,
}) {
  if (!enabled) return _fallbackLocale;

  final supported = AppLocalizations.supportedLocales.map((locale) => locale.languageCode).toSet();
  // A stored code the app no longer supports falls through to the system language.
  if (override != null && supported.contains(override)) return Locale(override);
  for (final deviceLocale in deviceLocales) {
    if (supported.contains(deviceLocale.languageCode)) return Locale(deviceLocale.languageCode);
  }
  return _fallbackLocale;
}
