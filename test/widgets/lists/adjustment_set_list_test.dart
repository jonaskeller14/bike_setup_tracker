import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/lists/adjustment_set_list.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_boolean_adjustment.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_numerical_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final highlights = materialAppTheme.extension<ValueHighlightColors>()!;

  NumericalAdjustment numerical() => NumericalAdjustment(
    name: "Weight",
    notes: null,
    unit: null,
    min: 0,
    max: 100,
  );

  BooleanAdjustment boolean() => BooleanAdjustment(
    name: "Knee pads",
    notes: null,
    unit: null,
  );

  Widget buildList({
    required List<Adjustment> adjustments,
    required Map<String, dynamic> previousValues,
    required Map<String, dynamic> values,
    required Key formKey,
    bool prefillFromInitial = false,
  }) {
    return MaterialApp(
      theme: materialAppTheme,
      home: Scaffold(
        body: Form(
          key: formKey,
          child: AdjustmentSetList(
            adjustments: adjustments,
            initialAdjustmentValues: previousValues,
            adjustmentValues: values,
            prefillFromInitial: prefillFromInitial,
            onAdjustmentValueChanged: ({required Adjustment adjustment, required dynamic newValue}) =>
                values[adjustment.id] = newValue,
            removeFromAdjustmentValues: ({required Adjustment adjustment}) => values.remove(adjustment.id),
          ),
        ),
      ),
    );
  }

  /// Background fill of an adjustment row, i.e. its highlight state.
  Color? rowFill(WidgetTester tester, Type widgetType) {
    final container = tester.widget<Container>(
      find.descendant(of: find.byType(widgetType), matching: find.byType(Container)).first,
    );
    return (container.decoration as BoxDecoration?)?.color;
  }

  group("AdjustmentSetList without pre-fill", () {
    testWidgets("leaves a field with a previous value empty and valid", (WidgetTester tester) async {
      final adjustment = numerical();
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        buildList(
          adjustments: [adjustment],
          previousValues: {adjustment.id: 65.0},
          values: {},
          formKey: formKey,
        ),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
      expect(formKey.currentState!.validate(), isTrue);
      expect(rowFill(tester, SetNumericalAdjustmentWidget), isNull);
    });

    testWidgets("still rejects an out-of-range value", (WidgetTester tester) async {
      final adjustment = numerical();
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        buildList(
          adjustments: [adjustment],
          previousValues: {adjustment.id: 65.0},
          values: {},
          formKey: formKey,
        ),
      );

      await tester.enterText(find.byType(TextField), '150');
      expect(formKey.currentState!.validate(), isFalse);
    });

    testWidgets("highlights an entered value against the previous one and clears on reset", (
      WidgetTester tester,
    ) async {
      final adjustment = numerical();
      final values = <String, dynamic>{};
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        buildList(
          adjustments: [adjustment],
          previousValues: {adjustment.id: 65.0},
          values: values,
          formKey: formKey,
        ),
      );

      await tester.enterText(find.byType(TextField), '80');
      await tester.pump();
      expect(values[adjustment.id], 80.0);
      expect(rowFill(tester, SetNumericalAdjustmentWidget), highlights.changedFill);

      await tester.tap(find.byIcon(Icons.replay));
      await tester.pump();
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
      expect(values.containsKey(adjustment.id), isFalse);
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets("keeps a value with a previous value clearable", (WidgetTester tester) async {
      final adjustment = boolean();
      final values = <String, dynamic>{};
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        buildList(
          adjustments: [adjustment],
          previousValues: {adjustment.id: true},
          values: values,
          formKey: formKey,
        ),
      );

      expect(find.text("Set value"), findsOneWidget);
      expect(rowFill(tester, SetBooleanAdjustmentWidget), isNull);

      await tester.tap(find.text("Set value"));
      await tester.pump();
      expect(values[adjustment.id], false);
      expect(rowFill(tester, SetBooleanAdjustmentWidget), highlights.changedFill);

      await tester.tap(find.byIcon(Icons.replay));
      await tester.pump();
      expect(find.text("Set value"), findsOneWidget);
      expect(values.containsKey(adjustment.id), isFalse);
    });
  });

  group("AdjustmentSetList with pre-fill", () {
    testWidgets("pre-fills the previous value and requires it", (WidgetTester tester) async {
      final adjustment = numerical();
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        buildList(
          adjustments: [adjustment],
          previousValues: {adjustment.id: 65.0},
          values: {},
          formKey: formKey,
          prefillFromInitial: true,
        ),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, '65.0');

      await tester.enterText(find.byType(TextField), '');
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Please enter a value'), findsOneWidget);
    });
  });
}
