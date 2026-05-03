import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_numerical_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validValues = {"0.1", "-0.1", "-1", "1", ""};
  const invalidValues = {"1..1", "-1.1", "1.1", "."};

  Widget buildWidget({required double? initialValue, required String? value, required Key formKey}) {
    return MaterialApp(
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
              category: AdjustmentCategory.component,
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
}
