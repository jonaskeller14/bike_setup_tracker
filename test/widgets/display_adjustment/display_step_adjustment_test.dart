import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/display_adjustment/display_step_adjustment.dart';
import 'package:bike_setup_tracker/widgets/display_adjustment/step_pips.dart';
import 'package:bike_setup_tracker/widgets/set_adjustment/set_step_adjustment_dial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  StepAdjustment rebound(StepAdjustmentVisualization visualization) => StepAdjustment(
    id: 'rebound',
    name: 'Rebound',
    notes: null,
    unit: null,
    step: 1,
    min: 0,
    max: 12,
    visualization: visualization,
  );

  Future<void> pump(WidgetTester tester, StepAdjustment adjustment, {StepValue? previous, StepValue? value}) {
    return tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: DisplayStepAdjustmentWidget(
            key: const ValueKey('rebound'),
            adjustment: adjustment,
            initialValue: previous,
            value: value,
          ),
        ),
      ),
    );
  }

  /// The plain text of the `previous → value` line.
  String valueLine(WidgetTester tester) => tester
      .widgetList<RichText>(find.byType(RichText))
      .map((text) => text.text.toPlainText())
      .firstWhere((text) => text.contains('10'));

  testWidgets('shows the previous value, the delta and the pips of a change', (tester) async {
    await pump(
      tester,
      rebound(StepAdjustmentVisualization.slider),
      previous: const StepValue(8),
      value: const StepValue(10),
    );

    expect(valueLine(tester), startsWith('8'));
    expect(find.text('+2'), findsOneWidget);
    expect(find.byType(StepPips), findsOneWidget);
  });

  testWidgets('shows only the value when nothing changed', (tester) async {
    await pump(
      tester,
      rebound(StepAdjustmentVisualization.slider),
      previous: const StepValue(10),
      value: const StepValue(10),
    );

    expect(valueLine(tester), startsWith('10'));
    expect(find.text('±0'), findsNothing);
  });

  testWidgets('shows no knob, even for a visualization with a dial', (tester) async {
    await pump(
      tester,
      rebound(StepAdjustmentVisualization.minusButtonValuePlusButtonCounterclockwiseDial),
      value: const StepValue(10),
    );
    expect(find.byType(RotaryKnob), findsNothing);
  });
}
