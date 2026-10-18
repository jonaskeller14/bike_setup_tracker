import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/app_settings.dart';
import 'package:bike_setup_tracker/pages/adjustment/step_adjustment_page.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/value_migration_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../value_migration_test_utils.dart';
import 'preset_key_test_utils.dart';

void main() {
  Widget wrap(Widget child) {
    return ChangeNotifierProvider<AppSettings>(create: (_) => AppSettings(), child: child);
  }

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
              final edited = await Navigator.push<AdjustmentEditResult<Adjustment>>(
                context,
                MaterialPageRoute(
                  builder: (context) => StepAdjustmentPage.edit(adjustment: initial),
                ),
              );
              result = edited?.value as StepAdjustment?;
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
              final edited = await Navigator.push<AdjustmentEditResult<Adjustment>>(
                context,
                MaterialPageRoute(
                  builder: (context) => StepAdjustmentPage.edit(adjustment: initial),
                ),
              );
              result = edited?.value as StepAdjustment?;
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
              final edited = await Navigator.push<AdjustmentEditResult<Adjustment>>(
                context,
                MaterialPageRoute(
                  builder: (context) => StepAdjustmentPage.edit(adjustment: initial),
                ),
              );
              result = edited?.value as StepAdjustment?;
            },
            child: const Text('Open Page'),
          ),
        ),
      ),
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
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('DialStyle')), findsNothing);
  });

  final preset = StepAdjustment(
    name: 'Preset',
    notes: null,
    unit: null,
    step: 1,
    min: 0,
    max: 10,
    visualization: StepAdjustmentVisualization.slider,
    presetKey: testPresetKey,
  );
  presetKeyTests(
    template: () => StepAdjustmentPage.template(adjustment: preset),
    edit: () => StepAdjustmentPage.edit(adjustment: preset),
    add: () => StepAdjustmentPage.add(),
    fillAdd: (tester) async {
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(1), '1');
      await tester.enterText(fields.at(2), '0');
      await tester.enterText(fields.at(3), '10');
    },
  );

  group('recorded values on edit', () {
    const sheetTitle = 'Update recorded values';

    final clicks = StepAdjustment(
      id: 'clicks',
      name: 'Rebound',
      notes: null,
      unit: null,
      step: 1,
      min: 0,
      max: 12,
      visualization: StepAdjustmentVisualization.slider,
    );

    Future<void> setStep(WidgetTester tester, String step) async {
      await tester.enterText(find.widgetWithText(TextFormField, 'Step'), step);
      await tester.pumpAndSettle();
    }

    AdjustmentEditResult<Adjustment> edited(Object? result) => result! as AdjustmentEditResult<Adjustment>;

    testWidgets('a step change that puts values off the grid offers Snap', (tester) async {
      final result = await pushAndSave(
        tester,
        StepAdjustmentPage.edit(adjustment: clicks, migrationContext: ValueMigrationContext(clicks)),
        repository: repositoryWithRecorded([recordedValue(const StepValue(4))]),
        interact: () => setStep(tester, '3'),
        afterSave: () async {
          expect(find.text(sheetTitle), findsOneWidget);
          expect(find.text('Snap'), findsOneWidget);
          await tester.tap(find.text('Update values'));
          await tester.pumpAndSettle();
        },
      );

      final migrations = edited(result).migrations;
      expect(migrations, hasLength(1));
      expect(migrations.single.adjustmentId, 'clicks');
      expect(migrations.single.apply(const StepValue(4)), const StepValue(3));
    });

    testWidgets('a step change that keeps values on the grid shows no sheet', (tester) async {
      final result = await pushAndSave(
        tester,
        StepAdjustmentPage.edit(adjustment: clicks, migrationContext: ValueMigrationContext(clicks)),
        repository: repositoryWithRecorded([recordedValue(const StepValue(4))]),
        interact: () => setStep(tester, '2'),
      );

      expect(find.text(sheetTitle), findsNothing);
      expect(edited(result).migrations, isEmpty);
      expect((edited(result).value as StepAdjustment).step, 2);
    });

    testWidgets('cancelling the sheet keeps the page open', (tester) async {
      final result = await pushAndSave(
        tester,
        StepAdjustmentPage.edit(adjustment: clicks, migrationContext: ValueMigrationContext(clicks)),
        repository: repositoryWithRecorded([recordedValue(const StepValue(4))]),
        interact: () => setStep(tester, '3'),
        afterSave: () async {
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
        },
      );

      expect(result, isNull);
      expect(find.text('Edit Step Adjustment'), findsOneWidget);
    });

    testWidgets('a rename does not look values up', (tester) async {
      final repository = repositoryWithRecorded();
      await pushAndSave(
        tester,
        StepAdjustmentPage.edit(adjustment: clicks, migrationContext: ValueMigrationContext(clicks)),
        repository: repository,
        interact: () => enterName(tester, 'Renamed'),
      );

      verifyNever(() => repository.recordedValues(any()));
    });
  });
}
