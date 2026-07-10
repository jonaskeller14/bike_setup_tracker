import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/pages/adjustment/numerical_adjustment_page.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('NumericalAdjustmentPage edit returns equal adjustment when unchanged', (WidgetTester tester) async {
    final initial = NumericalAdjustment(
      id: 'test-id',
      name: 'Test Numerical',
      notes: 'Some notes',
      unit: AdjustmentUnit.fromLegacy('mm'),
      min: 0,
      max: 100,
    );

    EditResult<Adjustment>? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<EditResult<Adjustment>>(
                context,
                MaterialPageRoute(
                  builder: (context) => NumericalAdjustmentPage.edit(adjustment: initial),
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
    expect(result!.value, equals(initial));
    expect(result!.conversions, isEmpty);
  });

  testWidgets('Can create numerical adjustment without bounds', (WidgetTester tester) async {
    NumericalAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<NumericalAdjustment>(
                context,
                MaterialPageRoute(
                  builder: (context) => NumericalAdjustmentPage.add(),
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

    await tester.enterText(find.byType(TextFormField).at(0), 'Pressure');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.name, 'Pressure');
    expect(result!.min, double.negativeInfinity);
    expect(result!.max, double.infinity);
  });

  testWidgets('Bounds are optional', (WidgetTester tester) async {
    NumericalAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<NumericalAdjustment>(
                context,
                MaterialPageRoute(
                  builder: (context) => NumericalAdjustmentPage.add(),
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

    await tester.enterText(find.byType(TextFormField).at(0), 'Unbounded');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show Additional Fields'));
    await tester.pumpAndSettle();

    // Leave min/max empty
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.min, double.negativeInfinity);
    expect(result!.max, double.infinity);
  });

  testWidgets('Can edit existing adjustment', (WidgetTester tester) async {
    final initial = NumericalAdjustment(
      id: 'test-id',
      name: 'Original',
      notes: 'Some notes',
      unit: AdjustmentUnit.fromLegacy('psi'),
      min: 10.0,
      max: 100.0,
    );

    EditResult<Adjustment>? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<EditResult<Adjustment>>(
                context,
                MaterialPageRoute(
                  builder: (context) => NumericalAdjustmentPage.edit(adjustment: initial),
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
    final adjustment = result!.value as NumericalAdjustment;
    expect(adjustment.id, 'test-id');
    expect(adjustment.name, 'Updated');
    expect(adjustment.min, 10.0);
    expect(adjustment.max, 100.0);
  });

  testWidgets('Unit field is preserved', (WidgetTester tester) async {
    NumericalAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<NumericalAdjustment>(
                context,
                MaterialPageRoute(
                  builder: (context) => NumericalAdjustmentPage.add(),
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

    await tester.enterText(find.byType(TextFormField).at(0), 'Weight');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('unit_picker_field')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('kg'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.unit, const KnownUnit(quantity: UnitQuantity.mass, unitId: 'kilograms'));
  });

  testWidgets('Preview equals input', (WidgetTester tester) async {
    NumericalAdjustment? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<NumericalAdjustment>(
                context,
                MaterialPageRoute(
                  builder: (context) => NumericalAdjustmentPage.add(),
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

    await tester.enterText(find.byType(TextFormField).at(0), 'Volume');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.name, 'Volume');
  });
}
