import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
