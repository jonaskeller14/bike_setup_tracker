import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/setup.dart';
import 'package:bike_setup_tracker/pages/adjustment/adjustment_page.dart';
import 'package:bike_setup_tracker/pages/adjustment/numerical_adjustment_page.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/dialogs/confirmation.dart';
import 'package:bike_setup_tracker/widgets/dialogs/discard_changes.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_numerical_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../goldens/support/localized_test_app.dart';

void main() {
  const de = Locale('de');

  Widget page(Widget home, {Locale locale = de}) => localizedTestApp(theme: materialAppTheme, locale: locale, home: home);

  group('adjustment forms', () {
    testWidgets('the numerical form is German, with a German error', (tester) async {
      await tester.pumpWidget(page(NumericalAdjustmentPage.add()));

      expect(find.text('Numerische Einstellung hinzufügen'), findsOneWidget);
      expect(find.text('Name der Einstellung'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(find.text('Name ist erforderlich'), findsOneWidget);
    });

    testWidgets('a rider attribute is called an attribute, not an adjustment', (tester) async {
      await tester.pumpWidget(page(NumericalAdjustmentPage.add(term: AdjustmentTerm.attribute)));

      expect(find.text('Numerisches Attribut hinzufügen'), findsOneWidget);
      expect(find.text('Name des Attributs'), findsOneWidget);
    });

    testWidgets('the numerical form keeps its English wording', (tester) async {
      await tester.pumpWidget(page(NumericalAdjustmentPage.add(term: AdjustmentTerm.attribute), locale: const Locale('en')));

      expect(find.text('Add Numerical Attribute'), findsOneWidget);
      expect(find.text('Attribute Name'), findsOneWidget);
    });
  });

  testWidgets('a value above the maximum is reported in German, with the unit', (tester) async {
    Intl.defaultLocale = 'de';
    addTearDown(() => Intl.defaultLocale = null);
    final formKey = GlobalKey<FormState>();
    final adjustment = NumericalAdjustment(
      name: 'Pressure',
      notes: null,
      unit: AdjustmentUnit.fromLegacy('psi'),
      min: 0,
      max: 100,
    );
    await tester.pumpWidget(
      page(
        Scaffold(
          body: Form(
            key: formKey,
            child: SetNumericalAdjustmentWidget(
              key: const ValueKey('Pressure'),
              adjustment: adjustment,
              initialValue: null,
              value: null,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '120');
    await tester.pump();
    expect(find.text('Max. 100 psi'), findsOneWidget);
  });

  group('dialogs', () {
    testWidgets('the discard dialog is German', (tester) async {
      await tester.pumpWidget(
        page(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showDiscardChangesDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Änderungen verwerfen?'), findsOneWidget);
      expect(find.text('Abbrechen'), findsOneWidget);
    });

    testWidgets('the confirmation dialog falls back to German defaults', (tester) async {
      await tester.pumpWidget(
        page(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showConfirmationDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Bist du sicher?'), findsOneWidget);
      expect(find.text('Weiter'), findsOneWidget);
    });
  });

  group('model text follows Intl.defaultLocale', () {
    test('boolean values', () {
      expect(const BooleanValue(true).display, 'On');
      Intl.withLocale('de', () {
        expect(const BooleanValue(true).display, 'An');
        expect(const BooleanValue(false).display, 'Aus');
      });
    });

    test('the unnamed setup', () {
      expect(Setup.namePlaceholder, 'Unnamed Setup');
      Intl.withLocale('de', () => expect(Setup.namePlaceholder, 'Unbenanntes Setup'));
    });

    test('a language the app does not support falls back to English', () {
      Intl.withLocale('fr', () => expect(const BooleanValue(true).display, 'On'));
    });
  });

  test('pluralized setup counts read naturally in both languages', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final german = lookupAppLocalizations(de);
    expect(en.setupAdjustmentCount(0), 'No adjustments yet.');
    expect(en.setupAdjustmentCount(1), '1 adjustment');
    expect(en.setupAdjustmentCount(3), '3 adjustments');
    expect(german.setupAdjustmentCount(1), '1 Einstellung');
    expect(german.setupAttributeCount(2), '2 Attribute');
    expect(en.compareValuesDiffer(1, 4), '1/4 values differs');
    expect(en.compareValuesDiffer(2, 4), '2/4 values differ');
    expect(german.compareValuesDiffer(2, 4), '2/4 Werte weichen ab');
  });
}
