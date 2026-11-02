import 'package:flutter/widgets.dart';

import '../models/app_settings.dart';
import 'app_localizations.dart';

const _fallbackLocale = Locale('en');

Locale resolveAppLocale({
  String? override, // lang = override ?? supported device language ?? english
  required List<Locale> deviceLocales,
}) {
  final supported = AppLocalizations.supportedLocales.map((locale) => locale.languageCode).toSet();
  // A stored code the app no longer supports falls through to the system language.
  if (override != null && supported.contains(override)) return Locale(override);
  for (final deviceLocale in deviceLocales) {
    if (supported.contains(deviceLocale.languageCode)) return Locale(deviceLocale.languageCode);
  }
  return _fallbackLocale;
}

Locale appLocaleOf(AppSettings settings) => resolveAppLocale(
  override: settings.localeCode,
  deviceLocales: WidgetsBinding.instance.platformDispatcher.locales,
);
