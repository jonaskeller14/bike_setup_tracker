import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  SfGlobalLocalizations.delegate,
];

/// For text that must not follow the app language: catalog errors for the YAML
/// authors, and search, which also matches the English names.
final AppLocalizations englishL10n = lookupAppLocalizations(const Locale('en'));

/// The localizations for the language `Intl.defaultLocale` currently names, for
/// model code that formats a value without a `BuildContext`.
AppLocalizations get currentL10n {
  final language = Intl.shortLocale(Intl.getCurrentLocale());
  final supported = AppLocalizations.supportedLocales.any((l) => l.languageCode == language);
  return supported ? lookupAppLocalizations(Locale(language)) : englishL10n;
}

/// Runs [body] with `Intl.defaultLocale` set to [l10n]'s language, for exports
/// whose model text (values, verdicts, interval units) reads the default locale.
T withLocaleOf<T>(AppLocalizations l10n, T Function() body) => Intl.withLocale(l10n.localeName, body) as T;

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
