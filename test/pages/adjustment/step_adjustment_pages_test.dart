import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/pages/adjustment/step_adjustment_page.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Widget wrap(Widget child, [AppSettings? appSettings]) {
    return appSettings == null
        ? ChangeNotifierProvider<AppSettings>(create: (_) => AppSettings(), child: child)
        : ChangeNotifierProvider<AppSettings>.value(value: appSettings, child: child);
  }

  AppSettings settingsWithDialStyle() => AppSettings()..enableStepDialColorSize = true;

  testWidgets('StepAdjustmentPage edit returns equal adjustment when unchanged', (WidgetTester tester) async {
    final initial = StepAdjustment(
      id: 'test-id',
      name: 'Test Step',
      notes: 'Some notes',
      unit: AdjustmentUnit.fromLegacy('clicks'),
      step: 1,
      min: 0,
      max: 10,
      visualization: StepAdjustmentVisualization.slider,
    );

    StepAdjustment? result;

    await tester.pumpWidget(wrap(
      MaterialApp(
        theme: materialAppTheme,
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
    ));

    await tester.tap(find.text('Open Page'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result, equals(initial));
  });

  testWidgets('Can create valid step adjustment', (WidgetTester tester) async {
    StepAdjustment? result;

    await tester.pumpWidget(wrap(
      MaterialApp(
        theme: materialAppTheme,
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
    ));

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

    await tester.pumpWidget(wrap(
      MaterialApp(
        theme: materialAppTheme,
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
    ));

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

    await tester.pumpWidget(wrap(
      MaterialApp(
        theme: materialAppTheme,
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
    ));

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

    await tester.pumpWidget(wrap(
      MaterialApp(
        theme: materialAppTheme,
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
    ));

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

  testWidgets('Dial visualization renders the dial field and taps cycle its style', (WidgetTester tester) async {
    final appSettings = settingsWithDialStyle();
    final initial = StepAdjustment(
      id: 'test-id',
      name: 'Rebound',
      notes: null,
      unit: null,
      step: 1,
      min: 0,
      max: 20,
      visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
    );

    StepAdjustment? result;

    await tester.pumpWidget(wrap(
      MaterialApp(
        theme: materialAppTheme,
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
      appSettings,
    ));

    await tester.tap(find.text('Open Page'));
    await tester.pumpAndSettle();

    final dial = find.byKey(const ValueKey('DialStyle'));
    expect(dial, findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(dial);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.dialColor, StepAdjustmentDialColor.red);
    expect(result!.dialSize, StepAdjustmentDialSize.normal);
  });

  testWidgets('Dial field is hidden for visualizations without a dial', (WidgetTester tester) async {
    final appSettings = settingsWithDialStyle();
    final initial = StepAdjustment(
      id: 'test-id',
      name: 'Rebound',
      notes: null,
      unit: null,
      step: 1,
      min: 0,
      max: 20,
      visualization: StepAdjustmentVisualization.slider,
    );

    await tester.pumpWidget(wrap(
      MaterialApp(
        theme: materialAppTheme,
        home: StepAdjustmentPage.edit(adjustment: initial),
      ),
      appSettings,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('DialStyle')), findsNothing);
  });

  testWidgets('Dial field is hidden while the feature flag is off', (WidgetTester tester) async {
    final initial = StepAdjustment(
      id: 'test-id',
      name: 'Rebound',
      notes: null,
      unit: null,
      step: 1,
      min: 0,
      max: 20,
      visualization: StepAdjustmentVisualization.sliderWithCounterclockwiseDial,
    );

    await tester.pumpWidget(wrap(
      MaterialApp(
        theme: materialAppTheme,
        home: StepAdjustmentPage.edit(adjustment: initial),
      ),
      AppSettings()..enableStepDialColorSize = false,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('DialStyle')), findsNothing);
  });
}
