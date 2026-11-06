import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _identifier = RegExp(r'[A-Za-z_][A-Za-z0-9_]*');

void main() {
  test('every key of app_en.arb is used in lib/', () {
    final arb = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>;
    final keys = arb.keys.where((key) => !key.startsWith('@'));

    final identifiers = <String>{};
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = file.path.replaceAll(r'\', '/');
      if (!path.endsWith('.dart') || path.startsWith('lib/l10n/app_localizations')) continue;
      identifiers.addAll(_identifier.allMatches(file.readAsStringSync()).map((match) => match[0]!));
    }

    expect(keys.where((key) => !identifiers.contains(key)), isEmpty, reason: 'ARB keys no code refers to');
  });
}
