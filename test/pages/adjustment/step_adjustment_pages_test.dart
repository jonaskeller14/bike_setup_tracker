import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/pages/adjustment/step_adjustment_page.dart';

void main() {
  testWidgets('StepAdjustmentPage edit returns equal adjustment when unchanged', (WidgetTester tester) async {
    final initial = StepAdjustment(
      id: 'test-id',
      name: 'Test Step',
      notes: 'Some notes',
      unit: 'clicks',
      step: 1,
      min: 0,
      max: 10,
      visualization: StepAdjustmentVisualization.slider,
    );

    StepAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<StepAdjustment>(
                context,
                MaterialPageRoute(
                  builder: (context) => StepAdjustmentPage.edit(adjustment: initial),
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
