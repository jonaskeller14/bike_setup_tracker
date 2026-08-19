import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/setup_comparison.dart' as comparison;
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/widgets/display_adjustment/display_adjustment_diff.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DisplayAdjustmentDiff rowFor({
    required Adjustment adjustment,
    required dynamic valueA,
    required dynamic valueB,
  }) {
    return DisplayAdjustmentDiff(
      groupId: 'fork',
      row: comparison.SetupAdjustmentComparison(
        adjustmentA: adjustment,
        adjustmentB: adjustment,
        valueA: comparison.SetupComparisonSideValue(
          value: valueA,
          provenance: comparison.SetupComparisonValueProvenance.explicit,
        ),
        valueB: comparison.SetupComparisonSideValue(
          value: valueB,
          provenance: comparison.SetupComparisonValueProvenance.explicit,
        ),
        isDifferent: valueA != valueB,
      ),
    );
  }

  Widget host(Widget child) => MaterialApp(
    theme: materialAppTheme,
    home: Scaffold(body: SizedBox(width: 390, child: child)),
  );

  testWidgets('shows adjustment notes from the info tooltip instead of inline', (tester) async {
    final adjustment = StepAdjustment(
      id: 'rebound',
      name: 'Rebound',
      notes: 'Turn clockwise from fully open',
      unit: const CustomUnit('clicks'),
      min: 0,
      max: 20,
      step: 1,
      visualization: StepAdjustmentVisualization.slider,
    );
    await tester.pumpWidget(host(rowFor(adjustment: adjustment, valueA: 2, valueB: 4)));

    expect(find.text('Turn clockwise from fully open'), findsNothing);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Turn clockwise from fully open'), findsOneWidget);
  });

  testWidgets('tapping setup A unit converts both comparison values', (tester) async {
    final adjustment = NumericalAdjustment(
      id: 'pressure',
      name: 'Pressure',
      notes: null,
      unit: const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi'),
    );
    await tester.pumpWidget(host(rowFor(adjustment: adjustment, valueA: 65.0, valueB: 80.0)));

    final panelA = find.byKey(const Key('compare-panel-a-fork-pressure'));
    await tester.tap(find.descendant(of: panelA, matching: find.text('psi')));
    await tester.pump();

    expect(find.text('bar'), findsNWidgets(2));
    expect(find.text('= 65 psi'), findsOneWidget);
    expect(find.text('= 80 psi'), findsOneWidget);
  });

  testWidgets('matches value and unit typography to adjustment display widgets', (tester) async {
    final numerical = NumericalAdjustment(
      id: 'pressure',
      name: 'Pressure',
      notes: null,
      unit: const CustomUnit('psi'),
    );
    final text = TextAdjustment(
      id: 'compound',
      name: 'Compound',
      notes: null,
      unit: const CustomUnit('grade'),
    );

    await tester.pumpWidget(
      host(
        Column(
          children: [
            rowFor(adjustment: numerical, valueA: 65, valueB: 70),
            rowFor(adjustment: text, valueA: 'Soft', valueB: 'Firm'),
          ],
        ),
      ),
    );

    final numericalValue = tester.widget<SelectableText>(find.widgetWithText(SelectableText, '65'));
    final textValue = tester.widget<SelectableText>(find.widgetWithText(SelectableText, 'Soft'));
    final numericalUnit = tester.widget<Text>(find.text(' psi').first);
    final textUnit = tester.widget<Text>(find.text(' grade').first);

    expect(numericalValue.style?.fontFamily, 'monospace');
    expect(numericalValue.style?.fontWeight, FontWeight.bold);
    expect(textValue.style?.fontFamily, isNot('monospace'));
    expect(textValue.style?.fontWeight, FontWeight.bold);
    expect(numericalUnit.style?.fontFamily, isNot('monospace'));
    expect(numericalUnit.style?.fontWeight, isNot(FontWeight.bold));
    expect(textUnit.style?.fontFamily, isNot('monospace'));
    expect(textUnit.style?.fontWeight, isNot(FontWeight.bold));
  });
}
