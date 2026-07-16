import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/display_adjustment/display_numerical_adjustment.dart';
import 'package:bike_setup_tracker/widgets/display_adjustment/display_step_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// These widgets render the value and its unit as separate widgets (see
/// ToggleableUnitValue, whose unit label is tappable when convertible), so the
/// value is asserted on its own. The point of these tests is the formatting: an
/// int 6 and a double 6.0 must both read "6", never "6.0".
void main() {
  group('Display Widgets Robustness Tests', () {
    testWidgets('DisplayStepAdjustmentWidget handles int and double values', (WidgetTester tester) async {
      final adjustment = StepAdjustment(
        id: 'step1',
        name: 'Step Adj',
        notes: '',
        unit: AdjustmentUnit.fromLegacy('clicks'),
        step: 1,
        min: 0,
        max: 10,
        visualization: StepAdjustmentVisualization.slider,
      );

      // Test with int
      await tester.pumpWidget(MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: DisplayStepAdjustmentWidget(
            key: const ValueKey('int'),
            adjustment: adjustment,
            initialValue: 5,
            value: 6,
          ),
        ),
      ));
      expect(find.text('6'), findsOneWidget);
      expect(find.textContaining('clicks'), findsWidgets);

      // Test with double (robustness check)
      await tester.pumpWidget(MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: DisplayStepAdjustmentWidget(
            key: const ValueKey('double'),
            adjustment: adjustment,
            initialValue: 5.0,
            value: 6.0,
          ),
        ),
      ));
      expect(find.text('6'), findsOneWidget);
      expect(find.text('6.0'), findsNothing);
      expect(find.textContaining('clicks'), findsWidgets);
    });

    testWidgets('DisplayNumericalAdjustmentWidget handles int and double values', (WidgetTester tester) async {
      final adjustment = NumericalAdjustment(
        id: 'num1',
        name: 'Num Adj',
        notes: '',
        unit: AdjustmentUnit.fromLegacy('mm'),
        min: 0,
        max: 100,
      );

      // Test with double
      await tester.pumpWidget(MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: DisplayNumericalAdjustmentWidget(
            key: const ValueKey('double'),
            adjustment: adjustment,
            initialValue: 10.5,
            value: 12.0,
          ),
        ),
      ));
      expect(find.text('12'), findsOneWidget);
      expect(find.text('12.0'), findsNothing);
      expect(find.text('mm'), findsOneWidget);

      // Test with int (robustness check)
      await tester.pumpWidget(MaterialApp(
        theme: materialAppTheme,
        home: Scaffold(
          body: DisplayNumericalAdjustmentWidget(
            key: const ValueKey('int'),
            adjustment: adjustment,
            initialValue: 10,
            value: 12,
          ),
        ),
      ));
      expect(find.text('12'), findsOneWidget);
      expect(find.text('mm'), findsOneWidget);
    });
  });
}
