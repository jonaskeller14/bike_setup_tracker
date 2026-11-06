import 'package:bike_setup_tracker/l10n/adjustment_value_text.dart';
import 'package:bike_setup_tracker/l10n/entity_names.dart';
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

import '../goldens/support/localized_test_app.dart';
import '../support/german_l10n.dart';

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

  group('model text follows the language passed in', () {
    test('boolean values', () {
      expect(const BooleanValue(true).displayText(englishL10n), 'On');
      expect(const BooleanValue(true).displayText(germanL10n), 'An');
      expect(const BooleanValue(false).displayText(germanL10n), 'Aus');
    });

    test('the unnamed setup', () {
      final setup = Setup(
        datetime: DateTime.utc(2026),
        datetimeLocal: DateTime(2026),
        tags: const {},
        bike: 'b',
        person: null,
        bikeAdjustmentValues: const {},
        personAdjustmentValues: const {},
      );
      expect(setup.label(englishL10n), 'Unnamed Setup');
      expect(setup.label(germanL10n), 'Unbenanntes Setup');
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
