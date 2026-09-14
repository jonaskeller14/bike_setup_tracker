import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_step_adjustment.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_step_adjustment_dial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';

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

  group("Dial color tinting", () {
    Widget buildTinted({
      required StepAdjustmentVisualization visualization,
      required StepAdjustmentDialColor dialColor,
    }) {
      return MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: SetStepAdjustmentWidget(
            key: const ValueKey("StepAdjustment #1"),
            initialValue: null,
            value: validValue,
            onChanged: (_) {},
            onChangedEnd: (_) {},
            adjustment: StepAdjustment(
              name: "StepAdjustment #1",
              notes: null,
              unit: null,
              step: 1,
              min: 5,
              max: 10,
              visualization: visualization,
              dialColor: dialColor,
            ),
          ),
        ),
      );
    }

    Color buttonBackground(WidgetTester tester) {
      final button = tester.widget<FilledButton>(find.byType(FilledButton).first);
      return button.style!.backgroundColor!.resolve(<WidgetState>{})!;
    }

    Color primaryOf(WidgetTester tester) {
      final context = tester.element(find.byType(SetStepAdjustmentWidget));
      return Theme.of(context).colorScheme.primary;
    }

    testWidgets('buttons take the dial color when the visualization has a dial', (WidgetTester tester) async {
      await tester.pumpWidget(buildTinted(
        visualization: StepAdjustmentVisualization.minusButtonValuePlusButtonClockwiseDial,
        dialColor: StepAdjustmentDialColor.orange,
      ));

      final context = tester.element(find.byType(SetStepAdjustmentWidget));
      final expected = resolveDialColor(context, StepAdjustmentDialColor.orange);
      expect(expected, isNot(primaryOf(tester)));
      expect(buttonBackground(tester), expected);
    });

    testWidgets('buttons stay primary when the visualization has no dial', (WidgetTester tester) async {
      await tester.pumpWidget(buildTinted(
        visualization: StepAdjustmentVisualization.minusButtonValuePlusButton,
        dialColor: StepAdjustmentDialColor.orange,
      ));

      expect(buttonBackground(tester), primaryOf(tester));
    });

    testWidgets('the slider thumb and track take the dial color only with a dial', (WidgetTester tester) async {
      await tester.pumpWidget(buildTinted(
        visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
        dialColor: StepAdjustmentDialColor.green,
      ));

      final context = tester.element(find.byType(SetStepAdjustmentWidget));
      final dialTint = resolveDialColor(context, StepAdjustmentDialColor.green);
      final withDial = tester.widget<SfSliderTheme>(find.byType(SfSliderTheme));
      expect(withDial.data.activeTrackColor, dialTint);
      expect(
        tester.widget<SfSlider>(find.byType(SfSlider)).thumbShape,
        isA<CustomValueThumbShape>().having((s) => s.primaryColor, 'primaryColor', dialTint),
      );

      await tester.pumpWidget(buildTinted(
        visualization: StepAdjustmentVisualization.slider,
        dialColor: StepAdjustmentDialColor.green,
      ));

      final withoutDial = tester.widget<SfSliderTheme>(find.byType(SfSliderTheme));
      expect(withoutDial.data.activeTrackColor, primaryOf(tester));
    });
  });
}
