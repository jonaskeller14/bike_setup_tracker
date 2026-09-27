import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/display_adjustment/display_adjustment_list.dart';
import 'package:bike_setup_tracker/widgets/display_adjustment/display_dangling_adjustment.dart';
import 'package:bike_setup_tracker/widgets/display_adjustment/display_sag_adjustment.dart';
import 'package:bike_setup_tracker/widgets/display_adjustment/display_step_adjustment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final rebound = StepAdjustment(
    id: 'rebound',
    name: 'Rebound',
    notes: null,
    unit: null,
    step: 1,
    min: 0,
    max: 20,
    visualization: StepAdjustmentVisualization.slider,
  );
  final sag = SagAdjustment(id: 'sag', name: 'SAG', notes: null, referenceTravelMm: 160);

  Widget harness(List<Adjustment> adjustments, Map<String, AdjustmentValue> values) => MaterialApp(
    theme: materialAppTheme,
    home: Scaffold(
      body: AdjustmentDisplayList(
        adjustments: adjustments,
        initialAdjustmentValues: const {},
        adjustmentValues: values,
      ),
    ),
  );

  testWidgets('renders each adjustment with its matching value widget', (tester) async {
    await tester.pumpWidget(
      harness([rebound, sag], {rebound.id: const StepValue(7), sag.id: const NumericalValue(25)}),
    );

    expect(find.byType(DisplayStepAdjustmentWidget), findsOneWidget);
    expect(find.byType(DisplaySagAdjustmentWidget), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('an absent value still renders the adjustment row', (tester) async {
    await tester.pumpWidget(harness([rebound], const {}));

    expect(find.byType(DisplayStepAdjustmentWidget), findsOneWidget);
    expect(find.byType(DisplayDanglingAdjustmentWidget), findsNothing);
  });

  testWidgets('a value that does not match its adjustment type asserts', (tester) async {
    await tester.pumpWidget(harness([rebound], {rebound.id: const NumericalValue(7.5)}));

    expect(tester.takeException(), isAssertionError);
  });
}
