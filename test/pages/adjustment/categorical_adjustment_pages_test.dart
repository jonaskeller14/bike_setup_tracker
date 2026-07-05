import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/pages/adjustment/categorical_adjustment_page.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CategoricalAdjustmentPage edit returns equal adjustment when unchanged', (WidgetTester tester) async {
    final initial = CategoricalAdjustment(
      id: 'test-id',
      name: 'Test Categorical',
      notes: 'Some notes',
      unit: 'some unit',
      options: {'Option 1', 'Option 2'},
    );

    CategoricalAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<CategoricalAdjustment>(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoricalAdjustmentPage.edit(adjustment: initial),
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
