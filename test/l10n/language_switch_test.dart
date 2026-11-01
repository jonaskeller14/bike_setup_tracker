import 'package:bike_setup_tracker/l10n/adjustment_value_text.dart';
import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/l10n/task_threshold_text.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/task/task_threshold/task_threshold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../goldens/support/localized_test_app.dart';

/// A language switch reaches a page through `context.l10n` alone: nothing marks
/// the tree dirty, and `Intl.defaultLocale` stays untouched.
void main() {
  testWidgets('a const page with model text follows a language switch', (tester) async {
    Future<void> pump(Locale locale) => tester.pumpWidget(localizedTestApp(locale: locale, home: const _ModelTextPage()));

    await pump(const Locale('en'));
    expect(find.text('On'), findsOneWidget);
    expect(find.text('2.5'), findsOneWidget);
    expect(find.text('1,500 rides'), findsOneWidget);
    expect(find.text('December'), findsOneWidget);

    await pump(const Locale('de'));
    await tester.pump();
    expect(find.text('An'), findsOneWidget);
    expect(find.text('2,5'), findsOneWidget);
    expect(find.text('1.500 Fahrten'), findsOneWidget);
    expect(find.text('Dezember'), findsOneWidget);
    expect(Intl.defaultLocale, isNull);
  });
}

class _ModelTextPage extends StatelessWidget {
  const _ModelTextPage();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Column(
        children: [
          Text(const BooleanValue(true).displayText(l10n)),
          Text(const NumericalValue(2.5).displayText(l10n)),
          Text(const ActivityCountThreshold(1500).toDisplayValue(l10n)),
          Text(DateFormat('MMMM', l10n.localeName).format(DateTime(2025, 12, 9))),
        ],
      ),
    );
  }
}
