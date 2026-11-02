import 'package:flutter/widgets.dart';

import '../models/app_settings.dart';
import 'app_localizations.dart';

const _fallbackLocale = Locale('en');

Locale resolveAppLocale({
  required bool enabled, // if false --> english
  String? override, // lang = override ?? supported device language ?? english
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

Locale appLocaleOf(AppSettings settings) => resolveAppLocale(
  enabled: settings.enableLanguageSelection,
  override: settings.localeCode,
  deviceLocales: WidgetsBinding.instance.platformDispatcher.locales,
);
