import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/pages/adjustment/step_adjustment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('Can create valid step adjustment', (WidgetTester tester) async {
    StepAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<StepAdjustment>(
                context,
                MaterialPageRoute(
                  builder: (context) => StepAdjustmentPage.add(),
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

    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), 'Brake Pad');
    await tester.enterText(fields.at(1), '1');
    await tester.enterText(fields.at(2), '0');
    await tester.enterText(fields.at(3), '10');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.name, 'Brake Pad');
    expect(result!.step, 1);
    expect(result!.min, 0);
    expect(result!.max, 10);
  });

  testWidgets('Negative min values work', (WidgetTester tester) async {
    StepAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<StepAdjustment>(
                context,
                MaterialPageRoute(
                  builder: (context) => StepAdjustmentPage.add(),
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

    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), 'Offset');
    await tester.enterText(fields.at(1), '5');
    await tester.enterText(fields.at(2), '-10');
    await tester.enterText(fields.at(3), '10');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.min, -10);
    expect(result!.max, 10);
  });

  testWidgets('Can edit existing adjustment', (WidgetTester tester) async {
    final initial = StepAdjustment(
      id: 'test-id',
      name: 'Original',
      notes: 'Some notes',
      unit: null,
      step: 5,
      min: 10,
      max: 100,
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

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Updated');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.id, 'test-id');
    expect(result!.name, 'Updated');
    expect(result!.step, 5);
    expect(result!.min, 10);
    expect(result!.max, 100);
  });

  testWidgets('Preview equals input when all fields valid', (WidgetTester tester) async {
    StepAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<StepAdjustment>(
                context,
                MaterialPageRoute(
                  builder: (context) => StepAdjustmentPage.add(),
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

    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), 'Tension');
    await tester.enterText(fields.at(1), '3');
    await tester.enterText(fields.at(2), '50');
    await tester.enterText(fields.at(3), '200');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.name, 'Tension');
    expect(result!.step, 3);
    expect(result!.min, 50);
    expect(result!.max, 200);
  });
}
