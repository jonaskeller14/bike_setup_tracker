import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/pages/adjustment/categorical_adjustment_page.dart';

void main() {
  testWidgets('CategoricalAdjustmentPage edit returns equal adjustment when unchanged', (WidgetTester tester) async {
    final initial = CategoricalAdjustment(
      id: 'test-id',
      name: 'Test Categorical',
      notes: 'Some notes',
      unit: 'some unit',
      options: {'Option 1', 'Option 2'},
      category: AdjustmentCategory.component,
    );

    CategoricalAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<CategoricalAdjustment>(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoricalAdjustmentPage.edit(adjustment: initial, categories: AdjustmentCategory.values.toSet()),
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
