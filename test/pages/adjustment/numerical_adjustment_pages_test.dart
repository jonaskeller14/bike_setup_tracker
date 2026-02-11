import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/pages/adjustment/numerical_adjustment_page.dart';

void main() {
  testWidgets('NumericalAdjustmentPage edit returns equal adjustment when unchanged', (WidgetTester tester) async {
    final initial = NumericalAdjustment(
      id: 'test-id',
      name: 'Test Numerical',
      notes: 'Some notes',
      unit: 'mm',
      min: 0,
      max: 100,
      category: AdjustmentCategory.component,
    );

    NumericalAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<NumericalAdjustment>(
                context,
                MaterialPageRoute(
                  builder: (context) => NumericalAdjustmentPage.edit(adjustment: initial, categories: AdjustmentCategory.values.toSet()),
                ),
              );
            },
            child: const Text('Open Page'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Page'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result, equals(initial));
  });
}
