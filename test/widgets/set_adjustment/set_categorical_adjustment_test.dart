import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_categorical_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const options = {"Option #1", "Option #2", "Option #3"};
  final validOption = options.first;
  const invalidOption1 = "Invalid Option #1";

  Widget buildWidget({
    required List<String>? initialValue,
    required List<String>? value,
    required Key formKey,
    bool multiSelect = false,
  }) {
    return MaterialApp(
      theme: materialAppTheme,
      home: Scaffold(
        body: Form(
          key: formKey,
          child: SetCategoricalAdjustmentWidget(
            key: const ValueKey("CategoricalAdjustment #1"),
            initialValue: initialValue,
            value: value,
            onChanged: (_) {},
            adjustment: CategoricalAdjustment(
              name: "CategoricalAdjustment #1",
              notes: null,
              unit: null,
              options: options,
              multiSelect: multiSelect,
            ),
          ),
        ),
      ),
    );
  }

  group("SetCategoricalAdjustmentWidget/field display & validation", () {
    testWidgets('valid value renders and validates', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      // A dangling *initialValue* (previous value) does not affect validity —
      // only the current value is validated.
      await tester.pumpWidget(buildWidget(initialValue: [invalidOption1], value: [validOption], formKey: formKey));
      expect(formKey.currentState!.validate(), isTrue);
      expect(find.text(validOption), findsOneWidget);
      expect(find.text("Please select"), findsNothing);
    });

    testWidgets('a dangling value is invalid and not shown in the field', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(initialValue: null, value: [invalidOption1], formKey: formKey));
      expect(formKey.currentState!.validate(), isFalse);
      expect(find.text(invalidOption1), findsNothing);
      expect(find.text("Please select"), findsOneWidget);
      await tester.pump();
      expect(find.text('Contains options that no longer exist'), findsOneWidget);
    });

    testWidgets('a dangling value with a valid previous value is still invalid', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(initialValue: [validOption], value: [invalidOption1], formKey: formKey));
      expect(formKey.currentState!.validate(), isFalse);
      expect(find.text(invalidOption1), findsNothing);
      expect(find.text("Please select"), findsOneWidget);
    });

    testWidgets('single-select rejects more than one selected option', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(
        initialValue: null,
        value: ["Option #1", "Option #2"],
        formKey: formKey,
      ));
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Only one option can be selected'), findsOneWidget);
    });
  });

  group("SetCategoricalAdjustmentWidget/multi-select", () {
    testWidgets('shows selected options comma-separated in option order', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      // Passed out of order; the field should render them in option order.
      await tester.pumpWidget(buildWidget(
        initialValue: null,
        value: const ["Option #3", "Option #1"],
        formKey: formKey,
        multiSelect: true,
      ));
      expect(find.text("Option #1, Option #3"), findsOneWidget);
      expect(find.text("Please select"), findsNothing);
    });

    testWidgets('multiple valid options are allowed', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(
        initialValue: null,
        value: const ["Option #1", "Option #2"],
        formKey: formKey,
        multiSelect: true,
      ));
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('ignores dangling values in the field but flags them invalid', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(
        initialValue: null,
        value: const ["Option #2", invalidOption1],
        formKey: formKey,
        multiSelect: true,
      ));
      // Only the still-valid option is shown; the dangling one surfaces in the sheet.
      expect(find.text("Option #2"), findsOneWidget);
      expect(find.text(invalidOption1), findsNothing);
      // ...but the dangling value still makes the field invalid.
      expect(formKey.currentState!.validate(), isFalse);
    });
  });
}
