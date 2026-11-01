import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The German texts address the reader with du (CONTEXT.md). Both messages
/// below say "they" about parts of a component, not "you".
const _thirdPerson = {'carryOverBodyApply', 'subcomponentsSheetCaption'};

void main() {
  test('app_de.arb never addresses the reader with Sie or Ihr', () {
    final arb = jsonDecode(File('lib/l10n/app_de.arb').readAsStringSync()) as Map<String, dynamic>;
    final formal = RegExp(
      r'\b[A-ZÄÖÜ][a-zäöüß]+(en|et|t) Sie\b'
      r'|\b(wenn|dass|ob|wie|falls|sobald|damit|bevor|nachdem) Sie\b'
      r'|\b(Ihr|Ihre|Ihren|Ihrem|Ihrer|Ihres|Ihnen)\b',
    );

    final offenders = [
      for (final entry in arb.entries)
        if (!entry.key.startsWith('@') && !_thirdPerson.contains(entry.key) && formal.hasMatch(entry.value as String))
          entry.key,
    ];

    expect(offenders, isEmpty, reason: 'formal address in these messages');
  });
}
