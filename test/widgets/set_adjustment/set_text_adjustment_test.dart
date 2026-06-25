import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_text_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validValue = "Valid Value";
  final invalidValue = Duration.zero.toString();

  Widget buildWidget({required String? initialValue, required String? value, required Key formKey}) {
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: SetTextAdjustmentWidget(
            key: const ValueKey("TextAdjustment #1"),
            initialValue: initialValue,
            value: value,
            onChanged: (_) {},
            adjustment: TextAdjustment(
              name: "TextAdjustment #1", 
              notes: null, 
              unit: null
            ),
          ),
        ),
      ),
    );
  }

  group("SetTextAdjustmentWidget", () {
    testWidgets("Form Validation with valid value", (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(initialValue: null, value: validValue, formKey: formKey));
      expect(formKey.currentState!.validate(), isTrue);
    });
    testWidgets("Form Validation with invalid value", (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(initialValue: null, value: invalidValue, formKey: formKey));
      expect(formKey.currentState!.validate(), isFalse);
    });
  });
}