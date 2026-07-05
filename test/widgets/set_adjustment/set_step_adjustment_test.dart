import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_step_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validValue = 5.0;
  const invalidValue = 0.0;

  Widget buildWidget({required double? initialValue, required double? value, required Key formKey}) {
    return MaterialApp(
      theme: materialAppTheme,
      home: Scaffold(
        body: Form(
          key: formKey,
          child: SetStepAdjustmentWidget(
            key: const ValueKey("StepAdjustment #1"),
            initialValue: initialValue,
            value: value,
            onChanged: (_) {},
            onChangedEnd: (_) {},
            adjustment: StepAdjustment(
              name: "StepAdjustment #1", 
              notes: null, 
              unit: null,
              step: 1,
              min: 5,
              max: 10,
              visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
            ),
          ),
        ),
      ),
    );
  }

  group("SetStepAdjustmentWidget", () {
    testWidgets('Invalid initialValue', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(initialValue: invalidValue, value: null, formKey: formKey));
      expect(formKey.currentState!.validate(), isTrue);
      expect(find.text("Set value"), findsOneWidget);
    });

    testWidgets('Invalid value', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(initialValue: null, value: invalidValue, formKey: formKey));
      expect(formKey.currentState!.validate(), isTrue);
      expect(find.text("Set value"), findsNothing);
    });

    testWidgets('Valid value', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(initialValue: null, value: validValue, formKey: formKey));
      expect(formKey.currentState!.validate(), isTrue);
      expect(find.text("Set value"), findsNothing);
    });
  });
}
