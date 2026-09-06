import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_numerical_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validValues = {"0.1", "-0.1", "-1", "1", ""};
  const invalidValues = {"1..1", "-1.1", "1.1", "."};

  Widget buildWidget({required double? initialValue, required String? value, required Key formKey}) {
    return MaterialApp(
      theme: materialAppTheme,
      home: Scaffold(
        body: Form(
          key: formKey,
          child: SetNumericalAdjustmentWidget(
            key: const ValueKey("NumericalAdjustment #1"),
            initialValue: initialValue,
            value: value,
            onChanged: (_) {},
            adjustment: NumericalAdjustment(
              name: "NumericalAdjustment #1",
              notes: null,
              unit: null,
              min: -1,
              max: 1,
            ),
          ),
        ),
      ),
    );
  }

  group("SetNumericalAdjustmentWidget", () {
    testWidgets("Form Validation with valid values", (WidgetTester tester) async {
      for (final value in validValues) {
        final formKey = GlobalKey<FormState>();
        await tester.pumpWidget(buildWidget(initialValue: null, value: value, formKey: formKey));
        expect(formKey.currentState!.validate(), isTrue);
      }
    });

    testWidgets("Form Validation with invalid values", (WidgetTester tester) async {
      for (final value in invalidValues) {
        final formKey = GlobalKey<FormState>();
        await tester.pumpWidget(buildWidget(initialValue: null, value: value, formKey: formKey));
        expect(formKey.currentState!.validate(), isFalse);
      }
    });
  });

  group("SetNumericalAdjustmentWidget unit toggle", () {
    // A pressure adjustment stored in psi, toggle cycle psi → bar → kPa.
    NumericalAdjustment pressureAdjustment({double? min, double? max}) => NumericalAdjustment(
          name: "Fork pressure",
          notes: null,
          unit: const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi'),
          min: min,
          max: max,
        );

    Widget buildPressure({
      required NumericalAdjustment adjustment,
      required double? initialValue,
      required String? value,
      required ValueChanged<String> onChanged,
      required Key formKey,
    }) {
      return MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: Form(
            key: formKey,
            child: SetNumericalAdjustmentWidget(
              key: const ValueKey("Pressure"),
              adjustment: adjustment,
              initialValue: initialValue,
              value: value,
              onChanged: onChanged,
            ),
          ),
        ),
      );
    }

    testWidgets("custom-unit adjustment does not toggle", (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: materialAppTheme,
          home: Scaffold(
            body: Form(
              key: formKey,
              child: SetNumericalAdjustmentWidget(
                key: const ValueKey("Clicks"),
                adjustment: NumericalAdjustment(
                  name: "Rebound",
                  notes: null,
                  unit: const CustomUnit('clicks'),
                  min: 0,
                  max: 20,
                ),
                initialValue: null,
                value: '5',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('clicks'), findsOneWidget);
      // Tapping the (non-convertible) unit changes nothing.
      await tester.tap(find.text('clicks'));
      await tester.pumpAndSettle();
      expect(find.text('clicks'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '5');
    });

    testWidgets("toggle converts displayed text and reports storage-unit value", (tester) async {
      final formKey = GlobalKey<FormState>();
      String? reported;
      await tester.pumpWidget(buildPressure(
        adjustment: pressureAdjustment(),
        initialValue: null,
        value: '65',
        onChanged: (v) => reported = v,
        formKey: formKey,
      ));

      // Starts in the storage unit (psi), no equivalent helper shown.
      expect(find.text('psi'), findsOneWidget);

      // Toggle psi → bar by tapping the unit label.
      await tester.tap(find.text('psi'));
      await tester.pumpAndSettle();

      // Displayed text is now in bar (65 psi ≈ 4.48 bar).
      final field = tester.widget<TextField>(find.byType(TextField));
      final displayed = double.parse(field.controller!.text);
      expect(displayed, closeTo(4.48, 0.01));
      expect(find.text('bar'), findsOneWidget);

      // Helper shows the stored equivalent in psi.
      expect(find.text('= 65 psi'), findsOneWidget);

      // A fresh edit in bar reports the storage-unit (psi) value.
      await tester.enterText(find.byType(TextField), '5');
      await tester.pump();
      expect(double.parse(reported!), closeTo(72.52, 0.05)); // 5 bar ≈ 72.5 psi
    });

    testWidgets("validation messages use converted bounds after toggle", (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildPressure(
        adjustment: pressureAdjustment(min: 0, max: 100), // psi bounds
        initialValue: 50,
        value: '65',
        onChanged: (_) {},
        formKey: formKey,
      ));

      // Toggle to bar: 100 psi ≈ 6.89 bar is the max in the active unit.
      await tester.tap(find.text('psi'));
      await tester.pumpAndSettle();

      // 8 bar exceeds the 100 psi (≈6.89 bar) maximum.
      await tester.enterText(find.byType(TextField), '8');
      expect(formKey.currentState!.validate(), isFalse);

      // 5 bar is within bounds.
      await tester.enterText(find.byType(TextField), '5');
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets("reset shows converted initial value in the active unit", (tester) async {
      final formKey = GlobalKey<FormState>();
      String? reported;
      await tester.pumpWidget(buildPressure(
        adjustment: pressureAdjustment(),
        initialValue: 65, // stored in psi
        value: '10',
        onChanged: (v) => reported = v,
        formKey: formKey,
      ));

      await tester.tap(find.text('psi'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.replay));
      await tester.pumpAndSettle();

      // Field shows the initial value converted into bar (65 psi ≈ 4.48 bar)…
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(double.parse(field.controller!.text), closeTo(4.48, 0.01));
      // …while the reported storage value is the exact stored initial (psi).
      expect(double.parse(reported!), closeTo(65, 0.0001));
    });
  });

  group("SetNumericalAdjustmentWidget reset button visibility", () {
    Widget buildWidget({required double? initialValue, required String? value, bool optional = false}) {
      return MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: SetNumericalAdjustmentWidget(
            key: const ValueKey("NumericalAdjustment #1"),
            initialValue: initialValue,
            value: value,
            onChanged: (_) {},
            optional: optional,
            adjustment: NumericalAdjustment(
              name: "NumericalAdjustment #1",
              notes: null,
              unit: null,
              min: -10,
              max: 10,
            ),
          ),
        ),
      );
    }

    testWidgets("hidden when current value equals initial value", (tester) async {
      await tester.pumpWidget(buildWidget(initialValue: 5, value: '5'));
      expect(find.byIcon(Icons.replay), findsNothing);
    });

    testWidgets("hidden when '5' vs '5.0' (equal parsed value, different text)", (tester) async {
      await tester.pumpWidget(buildWidget(initialValue: 5, value: '5.0'));
      expect(find.byIcon(Icons.replay), findsNothing);
    });

    testWidgets("shown when current value differs from initial value", (tester) async {
      await tester.pumpWidget(buildWidget(initialValue: 5, value: '6'));
      expect(find.byIcon(Icons.replay), findsOneWidget);
    });

    testWidgets("hidden for an optional field left empty", (tester) async {
      await tester.pumpWidget(buildWidget(initialValue: 5, value: '', optional: true));
      expect(find.byIcon(Icons.replay), findsNothing);
    });

    testWidgets("shown for an optional field with a value entered", (tester) async {
      await tester.pumpWidget(buildWidget(initialValue: 5, value: '6', optional: true));
      expect(find.byIcon(Icons.replay), findsOneWidget);
    });
  });
}
