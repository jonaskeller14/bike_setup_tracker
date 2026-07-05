import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/pages/adjustment/duration_adjustment_page.dart';
import 'package:bike_setup_tracker/theme.dart';
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
        theme: materialAppTheme,
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

  testWidgets('Can create duration adjustment without bounds', (WidgetTester tester) async {
    DurationAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<DurationAdjustment>(
                context,
                MaterialPageRoute(
                  builder: (context) => DurationAdjustmentPage.add(),
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

    await tester.enterText(find.byType(TextFormField).at(0), 'Break Duration');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.name, 'Break Duration');
    expect(result!.min, isNull);
    expect(result!.max, isNull);
  });

  testWidgets('Can edit duration adjustment with bounds', (WidgetTester tester) async {
    final initial = DurationAdjustment(
      id: 'test-id',
      name: 'Original',
      notes: 'Some notes',
      unit: null,
      min: const Duration(hours: 1),
      max: const Duration(hours: 10),
    );

    DurationAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
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

    // Change name
    await tester.enterText(find.byType(TextFormField).at(0), 'Updated');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.id, 'test-id');
    expect(result!.name, 'Updated');
    expect(result!.min, const Duration(hours: 1));
    expect(result!.max, const Duration(hours: 10));
  });

  testWidgets('Notes field updates correctly', (WidgetTester tester) async {
    DurationAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<DurationAdjustment>(
                context,
                MaterialPageRoute(
                  builder: (context) => DurationAdjustmentPage.add(),
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

    await tester.enterText(find.byType(TextFormField).at(0), 'Service Interval');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show Additional Fields'));
    await tester.pumpAndSettle();

    // Notes field is last
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.last, 'Based on manufacturer recommendations');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.notes, 'Based on manufacturer recommendations');
  });

  testWidgets('Empty notes results in null', (WidgetTester tester) async {
    DurationAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<DurationAdjustment>(
                context,
                MaterialPageRoute(
                  builder: (context) => DurationAdjustmentPage.add(),
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

    await tester.enterText(find.byType(TextFormField).at(0), 'Test Duration');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.notes, isNull);
  });

  testWidgets('Unit is preserved from original adjustment', (WidgetTester tester) async {
    final initial = DurationAdjustment(
      id: 'test-id',
      name: 'Original',
      notes: null,
      unit: 'hours',
      min: const Duration(hours: 1),
      max: const Duration(hours: 5),
    );

    DurationAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
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

    await tester.enterText(find.byType(TextFormField).at(0), 'Modified');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.unit, 'hours');
  });
}
