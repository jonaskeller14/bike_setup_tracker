import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/pages/adjustment/text_adjustment_page.dart';

void main() {
  testWidgets('TextAdjustmentPage edit returns equal adjustment when unchanged', (WidgetTester tester) async {
    final initial = TextAdjustment(
      id: 'test-id',
      name: 'Test Text',
      notes: 'Some notes',
      unit: 'some unit',
      category: AdjustmentCategory.component,
    );

    TextAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<TextAdjustment>(
                context,
                MaterialPageRoute(
                  builder: (context) => TextAdjustmentPage.edit(adjustment: initial, categories: AdjustmentCategory.values.toSet()),
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
