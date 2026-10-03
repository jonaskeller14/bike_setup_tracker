import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/display_adjustment/display_numerical_adjustment.dart';
import 'package:bike_setup_tracker/widgets/display_adjustment/display_step_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// These widgets render the value and its unit as separate widgets (see
/// ToggleableUnitValue, whose unit label is tappable when convertible), so the
/// value is asserted on its own. The point of these tests is the formatting: a
/// whole-number double 12.0 must read "12", never "12.0".
void main() {
  group('Display Widgets Robustness Tests', () {
    testWidgets('DisplayStepAdjustmentWidget shows the step value', (WidgetTester tester) async {
      final adjustment = StepAdjustment(
        id: 'step1',
        name: 'Step Adj',
        notes: '',
        unit: null,
        step: 1,
        min: 0,
        max: 10,
        visualization: StepAdjustmentVisualization.slider,
      );

      await tester.pumpWidget(MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: DisplayStepAdjustmentWidget(
            key: const ValueKey('int'),
            adjustment: adjustment,
            initialValue: const StepValue(5),
            value: const StepValue(6),
          ),
        ),
      ));
      // The value closes the `previous → value` line.
      expect(find.textContaining(RegExp(r'(^|\D)6$')), findsOneWidget);
    });

    testWidgets('DisplayNumericalAdjustmentWidget drops a trailing .0', (WidgetTester tester) async {
      final adjustment = NumericalAdjustment(
        id: 'num1',
        name: 'Num Adj',
        notes: '',
        unit: AdjustmentUnit.fromLegacy('mm'),
        min: 0,
        max: 100,
      );

      await tester.pumpWidget(MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: DisplayNumericalAdjustmentWidget(
            key: const ValueKey('double'),
            adjustment: adjustment,
            initialValue: const NumericalValue(10.5),
            value: const NumericalValue(12.0),
          ),
        ),
      ));
      expect(find.text('12'), findsOneWidget);
      expect(find.text('12.0'), findsNothing);
      expect(find.text('mm'), findsOneWidget);
    });
  });
}
