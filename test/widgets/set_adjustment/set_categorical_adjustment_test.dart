import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_categorical_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const options = {"Option #1", "Option #2", "Option #3"};
  final validOption = options.first;
  const invalidOption1 = "Invalid Option #1";
  const invalidOption2 = "Invalid Option #2";

  Widget buildWidget({required String? initialValue, required String? value, required Key formKey}) {
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: SetCategoricalAdjustmentWidget(
            key: ValueKey("CategoricalAdjustment #1"),
            initialValue: initialValue,
            value: value,
            onChanged: (_) {},
            adjustment: CategoricalAdjustment(name: "CategoricalAdjustment #1", notes: null, unit: null, options: options, category: AdjustmentCategory.component),
          ),
        ),
      ),
    );
  }

  group("SetCategoricalAdjustmentWidget/Build with invalid values", () {
    testWidgets('Invalid initialValue', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(initialValue: invalidOption1, value: validOption, formKey: formKey));
      expect(formKey.currentState!.validate(), isTrue);
      expect(find.text(validOption), findsOneWidget);
      expect(find.text("Please select"), findsNothing);
    });

    testWidgets('Invalid value #1', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(initialValue: null, value: invalidOption1, formKey: formKey));
      expect(formKey.currentState!.validate(), isTrue);
      expect(find.text(invalidOption1), findsNothing);
      expect(find.text("Please select"), findsOneWidget);
    });

    testWidgets('Invalid value #2', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(initialValue: validOption, value: invalidOption1, formKey: formKey));
      expect(formKey.currentState!.validate(), isTrue);
      expect(find.text(invalidOption1), findsNothing);
      expect(find.text("Please select"), findsOneWidget);
    });

    testWidgets('SetCategoricalAdjustmentWidget/invalid initialValue and value', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(buildWidget(initialValue: invalidOption1, value: invalidOption2, formKey: formKey));
      expect(formKey.currentState!.validate(), isTrue);
      expect(find.text(invalidOption2), findsNothing);
      expect(find.text("Please select"), findsOneWidget);
    });
  });
}
