import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/pages/adjustment/duration_adjustment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DurationAdjustmentPage edit returns equal adjustment when unchanged', (WidgetTester tester) async {
    final initial = DurationAdjustment(
      id: 'test-id',
      name: 'Test Duration',
      notes: 'Some notes',
      unit: 'some unit',
      min: const Duration(minutes: 1),
      max: const Duration(minutes: 10),
    );

    DurationAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<DurationAdjustment>(
                context,
                MaterialPageRoute(
                  builder: (context) => DurationAdjustmentPage.edit(adjustment: initial),
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
