import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_categorical_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const options = {"Option #1", "Option #2", "Option #3"};
  final validOption = options.first;
  const invalidOption1 = "Invalid Option #1";
  const invalidOption2 = "Invalid Option #2";

  testWidgets('SetCategoricalAdjustmentWidget/invalid initialValue', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SetCategoricalAdjustmentWidget(
          key: ValueKey("CategoricalAdjustment #1"),
          initialValue: invalidOption1,
          value: validOption,
          onChanged: (_) {},
          adjustment: CategoricalAdjustment(name: "CategoricalAdjustment #1", notes: null, unit: null, options: options),
        ),
      ),
    ));
    expect(find.text(validOption), findsOneWidget);
    expect(find.text("Please select"), findsNothing);
  });
  testWidgets('SetCategoricalAdjustmentWidget/invalid value', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SetCategoricalAdjustmentWidget(
          key: ValueKey("CategoricalAdjustment #1"),
          initialValue: null,
          value: invalidOption1,
          onChanged: (_) {},
          adjustment: CategoricalAdjustment(name: "CategoricalAdjustment #1", notes: null, unit: null, options: options),
        ),
      ),
    ));
    expect(find.text(invalidOption1), findsNothing);
    expect(find.text("Please select"), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SetCategoricalAdjustmentWidget(
          key: ValueKey("CategoricalAdjustment #1"),
          initialValue: validOption,
          value: invalidOption1,
          onChanged: (_) {},
          adjustment: CategoricalAdjustment(name: "CategoricalAdjustment #1", notes: null, unit: null, options: options),
        ),
      ),
    ));
    expect(find.text(invalidOption1), findsNothing);
    expect(find.text("Please select"), findsOneWidget);
  });
  testWidgets('SetCategoricalAdjustmentWidget/invalid initialValue and value', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SetCategoricalAdjustmentWidget(
          key: ValueKey("CategoricalAdjustment #1"),
          initialValue: invalidOption1,
          value: invalidOption2,
          onChanged: (_) {},
          adjustment: CategoricalAdjustment(name: "CategoricalAdjustment #1", notes: null, unit: null, options: options),
        ),
      ),
    ));
    expect(find.text(invalidOption2), findsNothing);
    expect(find.text("Please select"), findsOneWidget);
  });
}