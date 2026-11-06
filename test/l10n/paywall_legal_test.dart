import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/l10n/markup_text.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tags = <String, TextSpan Function(String)>{
    'store': (text) => TextSpan(text: text, style: const TextStyle(color: Color(0xFF000001))),
    'terms': (text) => TextSpan(text: text, style: const TextStyle(color: Color(0xFF000002))),
    'privacy': (text) => TextSpan(text: text, style: const TextStyle(color: Color(0xFF000003))),
  };

  /// The link texts of a legal note, by the color the tags gave them.
  Map<int, String> linksOf(String message) {
    final span = markupTextSpan(message, tags: tags);
    return {
      for (final child in span.children!.cast<TextSpan>())
        if (child.style?.color != null) child.style!.color!.toARGB32() & 0xFF: child.text!,
    };
  }

  group('paywall legal note', () {
    for (final locale in AppLocalizations.supportedLocales) {
      test('marks the store, terms and privacy links in $locale', () {
        final l10n = lookupAppLocalizations(locale);

        for (final message in [l10n.paywallLegalTrial('€9.99', '/ year', 'Stores'), l10n.paywallLegalAuto('Stores')]) {
          final links = linksOf(message);
          expect(links.keys, [1, 2, 3], reason: message);
          expect(links[1], 'Stores');
          expect(markupTextSpan(message, tags: tags).toPlainText(), isNot(contains('<')), reason: 'tags are consumed');
        }
      });
    }

    test('keeps the price and the links in English as before', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final plain = markupTextSpan(en.paywallLegalTrial('€9.99', '/ year', 'App Store settings'), tags: tags).toPlainText();

      expect(
        plain,
        '7 days free, then €9.99/ year. Cancel before the trial ends to avoid a charge. '
        'Manage or cancel anytime in your App Store settings. '
        'By subscribing you agree to Terms of Use and Privacy Policy.',
      );
    });

    test('reads in German with the links on the declined words', () {
      final de = lookupAppLocalizations(const Locale('de'));
      final links = linksOf(de.paywallLegalAuto('App-Store-Einstellungen'));

      expect(links[1], 'App-Store-Einstellungen');
      expect(links[2], 'Nutzungsbedingungen');
      expect(links[3], 'Datenschutzerklärung');
    });
  });
}
