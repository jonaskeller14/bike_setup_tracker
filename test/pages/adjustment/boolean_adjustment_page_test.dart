import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/pages/adjustment/boolean_adjustment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BooleanAdjustmentPage edit returns equal adjustment when unchanged', (WidgetTester tester) async {
    final initial = BooleanAdjustment(
      id: 'test-id',
      name: 'Test Boolean',
      notes: 'Some notes',
      unit: 'some unit',
      category: AdjustmentCategory.component,
    );

    BooleanAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<BooleanAdjustment>(
                context,
                MaterialPageRoute(
                  builder: (context) => BooleanAdjustmentPage.edit(adjustment: initial, categories: AdjustmentCategory.values.toSet()),
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
