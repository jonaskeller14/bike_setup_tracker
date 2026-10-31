import 'package:bike_setup_tracker/l10n/app_language.dart';
import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLanguage', () {
    test('offers exactly the languages the app is translated into', () {
      expect(
        AppLanguage.values.map((language) => language.name).toSet(),
        AppLocalizations.supportedLocales.map((locale) => locale.languageCode).toSet(),
      );
    });

    test('reads a stored code back, and null or an unknown code as no choice', () {
      expect(AppLanguage.fromCode('de'), AppLanguage.de);
      expect(AppLanguage.fromCode(null), isNull);
      expect(AppLanguage.fromCode('fr'), isNull);
    });
  });
}
