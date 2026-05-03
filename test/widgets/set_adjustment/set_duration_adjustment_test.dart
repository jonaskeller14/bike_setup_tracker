import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_duration_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final validValue = const Duration(hours: 2);
  // final invalidValue = const Duration(hours: 4);

  Widget buildWidget({required Duration? initialValue, required Duration? value, required Key formKey}) {
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: SetDurationAdjustmentWidget(
            key: const ValueKey("DurationAdjustment #1"),
            initialValue: initialValue,
            value: value,
            onChanged: (_) {},
            adjustment: DurationAdjustment(
              name: "DurationAdjustment #1", 
              notes: null,
              unit: null,
              min: const Duration(hours: 1),
              max: const Duration(hours: 2),
              category: AdjustmentCategory.component
            ),
          ),
        ),
      ),
    );
  }

  group("SetDurationAdjustmentWidget", () {
    testWidgets("Form Validation with valid values", (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(initialValue: null, value: validValue, formKey: formKey));
      expect(formKey.currentState!.validate(), isTrue);
    });

    // testWidgets("Form Validation with invalid values", (WidgetTester tester) async {
    //   final formKey = GlobalKey<FormState>();
    //   await tester.pumpWidget(buildWidget(initialValue: null, value: invalidValue, formKey: formKey));
    //   expect(formKey.currentState!.validate(), isFalse); //FIXME: implement formfield in SetDurationAdjustnetWidget
    // });
  });
}
