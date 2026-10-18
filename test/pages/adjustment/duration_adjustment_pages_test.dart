import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/pages/adjustment/duration_adjustment_page.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/value_migration_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../value_migration_test_utils.dart';
import 'preset_key_test_utils.dart';

void main() {
  testWidgets('DurationAdjustmentPage edit returns equal adjustment when unchanged', (WidgetTester tester) async {
    final initial = DurationAdjustment(
      id: 'test-id',
      name: 'Test Duration',
      notes: 'Some notes',
      unit: AdjustmentUnit.fromLegacy('some unit'),
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
              final edited = await Navigator.push<AdjustmentEditResult<Adjustment>>(
                context,
                MaterialPageRoute(
                  builder: (context) => DurationAdjustmentPage.edit(adjustment: initial),
                ),
              );
              result = edited?.value as DurationAdjustment?;
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
              final edited = await Navigator.push<AdjustmentEditResult<Adjustment>>(
                context,
                MaterialPageRoute(
                  builder: (context) => DurationAdjustmentPage.edit(adjustment: initial),
                ),
              );
              result = edited?.value as DurationAdjustment?;
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
      unit: AdjustmentUnit.fromLegacy('hours'),
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
              final edited = await Navigator.push<AdjustmentEditResult<Adjustment>>(
                context,
                MaterialPageRoute(
                  builder: (context) => DurationAdjustmentPage.edit(adjustment: initial),
                ),
              );
              result = edited?.value as DurationAdjustment?;
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
    expect(result!.unit?.label, 'hours');
  });

  final preset = DurationAdjustment(name: 'Preset', notes: null, unit: null, presetKey: testPresetKey);
  presetKeyTests(
    template: () => DurationAdjustmentPage.template(adjustment: preset),
    edit: () => DurationAdjustmentPage.edit(adjustment: preset),
    add: () => DurationAdjustmentPage.add(),
  );

  group('recorded values on edit', () {
    const sheetTitle = 'Update recorded values';

    final ride = DurationAdjustment(
      id: 'ride',
      name: 'Ride time',
      notes: null,
      unit: null,
      max: const Duration(hours: 5),
    );

    AdjustmentEditResult<Adjustment> edited(Object? result) => result! as AdjustmentEditResult<Adjustment>;

    testWidgets('lowering the max below a recorded value offers Clamp', (tester) async {
      final result = await pushAndSave(
        tester,
        DurationAdjustmentPage.edit(adjustment: ride, migrationContext: ValueMigrationContext(ride)),
        repository: repositoryWithRecorded([recordedValue(const DurationValue(Duration(hours: 4)))]),
        interact: () => setDurationHours(tester, 'Max Duration (optional)', from: 5, to: 3),
        afterSave: () async {
          expect(find.text(sheetTitle), findsOneWidget);
          expect(find.text('Clamp'), findsOneWidget);
          await tester.tap(find.text('Update values'));
          await tester.pumpAndSettle();
        },
      );

      final migrations = edited(result).migrations;
      expect(migrations, hasLength(1));
      expect(migrations.single.apply(const DurationValue(Duration(hours: 4))), const DurationValue(Duration(hours: 3)));
    });

    testWidgets('lowering the max above every recorded value shows no sheet', (tester) async {
      final result = await pushAndSave(
        tester,
        DurationAdjustmentPage.edit(adjustment: ride, migrationContext: ValueMigrationContext(ride)),
        repository: repositoryWithRecorded([recordedValue(const DurationValue(Duration(hours: 2)))]),
        interact: () => setDurationHours(tester, 'Max Duration (optional)', from: 5, to: 3),
      );

      expect(find.text(sheetTitle), findsNothing);
      expect(edited(result).migrations, isEmpty);
      expect((edited(result).value as DurationAdjustment).max, const Duration(hours: 3));
    });
  });
}
