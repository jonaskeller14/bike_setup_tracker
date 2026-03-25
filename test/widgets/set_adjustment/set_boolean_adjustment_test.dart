import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_boolean_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildWidget({required bool? initialValue, required bool? value, required Key formKey}) {
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: SetBooleanAdjustmentWidget(
            key: ValueKey("BooleanAdjustment #1"),
            initialValue: initialValue,
            value: value,
            onChanged: (_) {},
            adjustment: BooleanAdjustment(
              name: "BooleanAdjustment #1", 
              notes: null,
              unit: null,
              category: AdjustmentCategory.component
            ),
          ),
        ),
      ),
    );
  }

  group("SetBooleanAdjustmentWidget/Validation and Placeholder for null values", () {
    testWidgets('initialValue: null, value: null', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(initialValue: null, value: null, formKey: formKey));
      expect(formKey.currentState!.validate(), isTrue);
      expect(find.text("Set value"), findsOneWidget);
    });

    testWidgets('initialValue: true, value: null', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(initialValue: true, value: null, formKey: formKey));
      expect(formKey.currentState!.validate(), isTrue);
      expect(find.text("Set value"), findsOneWidget);
    });

    testWidgets('initialValue: true, value: false', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(initialValue: true, value: false, formKey: formKey));
      expect(formKey.currentState!.validate(), isTrue);
      expect(find.text("Set value"), findsNothing);
    });
  });
}
