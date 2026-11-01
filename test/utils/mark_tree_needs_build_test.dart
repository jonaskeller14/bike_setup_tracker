import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/utils/mark_tree_needs_build.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../goldens/support/localized_test_app.dart';

void main() {
  tearDown(() => Intl.defaultLocale = null);

  testWidgets('rebuilds a page that only reads Intl.defaultLocale after a language switch', (tester) async {
    Intl.defaultLocale = 'en';
    // A const subtree with no inherited dependency: nothing rebuilds it on its own.
    await tester.pumpWidget(localizedTestApp(home: const _OnOffText()));
    expect(find.text('On'), findsOneWidget);

    Intl.defaultLocale = 'de';
    await tester.pump();
    expect(find.text('On'), findsOneWidget, reason: 'nothing marked the page dirty');

    markTreeNeedsBuild(tester.element(find.byType(MaterialApp)));
    await tester.pump();
    expect(find.text('An'), findsOneWidget);
  });
}

class _OnOffText extends StatelessWidget {
  const _OnOffText();

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(currentL10n.valueOn));
}
