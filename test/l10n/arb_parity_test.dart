import 'dart:convert';
import 'dart:io';

import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _readArb(String locale) {
  final file = File('lib/l10n/app_$locale.arb');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Map<String, String> _messages(Map<String, dynamic> arb) => {
  for (final entry in arb.entries)
    if (!entry.key.startsWith('@')) entry.key: entry.value as String,
};

/// Names of the ICU arguments in [message], including those inside the
/// branches of plural/select expressions but not the branch selectors.
Set<String> _placeholders(String message) {
  final names = <String>{};

  int closingBrace(String text, int open) {
    var depth = 0;
    for (var i = open; i < text.length; i++) {
      if (text[i] == '{') depth++;
      if (text[i] == '}' && --depth == 0) return i;
    }
    throw FormatException('Unbalanced braces in "$message"');
  }

  void scan(String text) {
    var i = 0;
    while (i < text.length) {
      if (text[i] != '{') {
        i++;
        continue;
      }
      final end = closingBrace(text, i);
      final inner = text.substring(i + 1, end);
      final parts = inner.split(',');
      names.add(parts.first.trim());
      if (parts.length > 2 && const {'plural', 'select', 'selectordinal'}.contains(parts[1].trim())) {
        final branches = inner.substring(inner.indexOf(',', inner.indexOf(',') + 1) + 1);
        var j = 0;
        while (j < branches.length) {
          if (branches[j] != '{') {
            j++;
            continue;
          }
          final branchEnd = closingBrace(branches, j);
          scan(branches.substring(j + 1, branchEnd));
          j = branchEnd + 1;
        }
      }
      i = end + 1;
    }
  }

  scan(message);
  return names;
}

void main() {
  final en = _readArb('en');
  final enMessages = _messages(en);
  // A regional file such as app_pt_PT.arb only holds the strings that differ
  // from its language, so it can't be complete, only consistent.
  final translations = {
    for (final locale in AppLocalizations.supportedLocales)
      if (locale.languageCode != 'en') locale: _messages(_readArb(locale.toString())),
  };

  group('ARB parity', () {
    test('every English key has a description', () {
      for (final key in enMessages.keys) {
        final meta = en['@$key'] as Map<String, dynamic>?;
        expect(meta?['description'], isA<String>(), reason: '"$key" needs a @$key description');
      }
    });

    for (final MapEntry(key: locale, value: messages) in translations.entries) {
      group('$locale', () {
        test('has every English key', () {
          if (locale.countryCode != null) return;
          expect(enMessages.keys.toSet().difference(messages.keys.toSet()), isEmpty);
        });

        test('has no key English lacks', () {
          expect(messages.keys.toSet().difference(enMessages.keys.toSet()), isEmpty);
        });

        test('uses the English placeholders', () {
          for (final key in enMessages.keys.where(messages.containsKey)) {
            expect(
              _placeholders(messages[key]!),
              _placeholders(enMessages[key]!),
              reason: 'Placeholders of "$key" differ between app_en.arb and app_$locale.arb',
            );
          }
        });

        test('has no empty message', () {
          expect(messages.entries.where((e) => e.value.trim().isEmpty).map((e) => e.key), isEmpty);
        });
      });
    }
  });

  group('placeholder extraction', () {
    test('plain text has none', () {
      expect(_placeholders('Cancel'), isEmpty);
    });

    test('finds simple arguments', () {
      expect(_placeholders('Delete {name} from {bike}?'), {'name', 'bike'});
    });

    test('reads plural arguments but not branch text', () {
      expect(
        _placeholders('{count, plural, =0{No days} one{{count} day} other{{count} days}}'),
        {'count'},
      );
    });

    test('finds arguments nested in select branches', () {
      expect(
        _placeholders('{kind, select, bike{Bike {name}} other{Item}}'),
        {'kind', 'name'},
      );
    });
  });
}
