import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/pages/adjustment/numerical_adjustment_page.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/value_migration_actions.dart';
import 'package:bike_setup_tracker/utils/value_migration_proposal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../value_migration_test_utils.dart';
import 'preset_key_test_utils.dart';

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

    AdjustmentEditResult<Adjustment>? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<AdjustmentEditResult<Adjustment>>(
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
    expect(result!.migrations, isEmpty);
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

    AdjustmentEditResult<Adjustment>? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<AdjustmentEditResult<Adjustment>>(
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

  final preset = NumericalAdjustment(
    name: 'Preset',
    notes: null,
    unit: const KnownUnit(quantity: UnitQuantity.mass, unitId: 'kilograms'),
    min: 0,
    presetKey: testPresetKey,
  );
  presetKeyTests(
    template: () => NumericalAdjustmentPage.template(adjustment: preset),
    edit: () => NumericalAdjustmentPage.edit(adjustment: preset),
    add: () => NumericalAdjustmentPage.add(),
  );

  testWidgets('presetKey survives a unit change on edit', (tester) async {
    final saved = savedAdjustment(await pushAndSave(
      tester,
      NumericalAdjustmentPage.edit(adjustment: preset),
      repository: repositoryWithRecorded(),
      interact: () async {
        await tester.tap(find.byKey(const Key('unit_picker_field')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('lb'));
        await tester.pumpAndSettle();
      },
    ));
    expect(saved.unit, isNot(preset.unit));
    expect(saved.presetKey, testPresetKey);
  });

  group('recorded values on edit', () {
    const psi = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi');
    const bar = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'bar');
    const sheetTitle = 'Update recorded values';

    final pressure = NumericalAdjustment(
      id: 'pressure',
      name: 'Pressure',
      notes: null,
      unit: psi,
      min: 0,
      max: 100,
    );

    Future<void> setMax(WidgetTester tester, String max) async {
      await tester.enterText(find.widgetWithText(TextFormField, 'Max Value (optional)'), max);
      await tester.pumpAndSettle();
    }

    Future<void> pickUnit(WidgetTester tester, String label) async {
      await tester.tap(find.byKey(const Key('unit_picker_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    AdjustmentEditResult<Adjustment> edited(Object? result) => result! as AdjustmentEditResult<Adjustment>;

    testWidgets('narrowing the range without recorded values saves without a sheet', (tester) async {
      final result = await pushAndSave(
        tester,
        NumericalAdjustmentPage.edit(adjustment: pressure, migrationContext: ValueMigrationContext(pressure)),
        repository: repositoryWithRecorded(),
        interact: () => setMax(tester, '50'),
      );

      expect(find.text(sheetTitle), findsNothing);
      expect(edited(result).migrations, isEmpty);
      expect((edited(result).value as NumericalAdjustment).max, 50);
    });

    testWidgets('narrowing the range with values outside it shows the sheet and clamps', (tester) async {
      final result = await pushAndSave(
        tester,
        NumericalAdjustmentPage.edit(adjustment: pressure, migrationContext: ValueMigrationContext(pressure)),
        repository: repositoryWithRecorded([recordedValue(const NumericalValue(80))]),
        interact: () => setMax(tester, '50'),
        afterSave: () async {
          expect(find.text(sheetTitle), findsOneWidget);
          await tester.tap(find.text('Update values'));
          await tester.pumpAndSettle();
        },
      );

      final migrations = edited(result).migrations;
      expect(migrations, hasLength(1));
      expect(migrations.single.adjustmentId, 'pressure');
      expect(migrations.single.apply(const NumericalValue(80)), const NumericalValue(50));
    });

    testWidgets('narrowing the range keeps values that still fit without a sheet', (tester) async {
      final result = await pushAndSave(
        tester,
        NumericalAdjustmentPage.edit(adjustment: pressure, migrationContext: ValueMigrationContext(pressure)),
        repository: repositoryWithRecorded([recordedValue(const NumericalValue(20))]),
        interact: () => setMax(tester, '50'),
      );

      expect(find.text(sheetTitle), findsNothing);
      expect(edited(result).migrations, isEmpty);
    });

    testWidgets('a unit change with values offers Convert and returns the conversion', (tester) async {
      final result = await pushAndSave(
        tester,
        NumericalAdjustmentPage.edit(adjustment: pressure, migrationContext: ValueMigrationContext(pressure)),
        repository: repositoryWithRecorded([recordedValue(const NumericalValue(10))]),
        interact: () => pickUnit(tester, 'bar'),
        afterSave: () async {
          expect(find.text(sheetTitle), findsOneWidget);
          expect(find.text('Convert'), findsOneWidget);
          await tester.tap(find.text('Update values'));
          await tester.pumpAndSettle();
        },
      );

      expect(edited(result).migrations, [
        ValueMigration('pressure', const [ConvertUnitStep(psi, bar)]),
      ]);
    });

    testWidgets('Keep numbers returns no migration', (tester) async {
      final result = await pushAndSave(
        tester,
        NumericalAdjustmentPage.edit(adjustment: pressure.copyWith(max: double.infinity), migrationContext: ValueMigrationContext(pressure.copyWith(max: double.infinity))),
        repository: repositoryWithRecorded([recordedValue(const NumericalValue(10))]),
        interact: () => pickUnit(tester, 'bar'),
        afterSave: () async {
          await tester.tap(find.text('Keep numbers'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Update values'));
          await tester.pumpAndSettle();
        },
      );

      expect(edited(result).migrations, isEmpty);
      expect((edited(result).value as NumericalAdjustment).unit, bar);
    });

    testWidgets('a unit change without values shows no sheet', (tester) async {
      final result = await pushAndSave(
        tester,
        NumericalAdjustmentPage.edit(adjustment: pressure, migrationContext: ValueMigrationContext(pressure)),
        repository: repositoryWithRecorded(),
        interact: () => pickUnit(tester, 'bar'),
      );

      expect(find.text(sheetTitle), findsNothing);
      expect(edited(result).migrations, isEmpty);
    });

    testWidgets('cancelling the sheet keeps the page open', (tester) async {
      final result = await pushAndSave(
        tester,
        NumericalAdjustmentPage.edit(adjustment: pressure, migrationContext: ValueMigrationContext(pressure)),
        repository: repositoryWithRecorded([recordedValue(const NumericalValue(80))]),
        interact: () => setMax(tester, '50'),
        afterSave: () async {
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
        },
      );

      expect(result, isNull);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('an edit that cannot affect values does not look them up', (tester) async {
      final repository = repositoryWithRecorded([recordedValue(const NumericalValue(80))]);
      final result = await pushAndSave(
        tester,
        NumericalAdjustmentPage.edit(adjustment: pressure, migrationContext: ValueMigrationContext(pressure)),
        repository: repository,
        interact: () => enterName(tester, 'Renamed'),
      );

      verifyNever(() => repository.recordedValues(any()));
      expect(edited(result).migrations, isEmpty);
    });

    group('a re-edit', () {
      final recorded = [recordedValue(const NumericalValue(80))];
      // An earlier edit of the same form narrowed the maximum to 50 and clamped.
      final narrowed = pressure.copyWith(max: 50.0);
      final earlier = MigrationProposal.build(before: pressure, after: narrowed, recorded: recorded);

      NumericalAdjustmentPage reEdit() => NumericalAdjustmentPage.edit(
        adjustment: narrowed,
        migrationContext: ValueMigrationContext(pressure, pending: earlier),
      );

      testWidgets('shows the net change from the saved definition', (tester) async {
        final result = await pushAndSave(
          tester,
          reEdit(),
          repository: repositoryWithRecorded(recorded),
          interact: () => setMax(tester, '70'),
          afterSave: () async {
            expect(find.textContaining('This replaces the change you confirmed earlier.'), findsOneWidget);
            await tester.tap(find.text('Update values'));
            await tester.pumpAndSettle();
          },
        );

        expect(edited(result).migrations.single.apply(const NumericalValue(80)), const NumericalValue(70));
      });

      testWidgets('back to the saved definition stages nothing', (tester) async {
        final result = await pushAndSave(
          tester,
          reEdit(),
          repository: repositoryWithRecorded(recorded),
          interact: () => setMax(tester, '100'),
        );

        expect(find.text(sheetTitle), findsNothing);
        expect(edited(result).pending, isNull);
      });

      testWidgets('that only renames shows the pending change again', (tester) async {
        final result = await pushAndSave(
          tester,
          reEdit(),
          repository: repositoryWithRecorded(recorded),
          interact: () => enterName(tester, 'Renamed'),
          afterSave: () async {
            expect(find.text(sheetTitle), findsOneWidget);
            await tester.tap(find.text('Update values'));
            await tester.pumpAndSettle();
          },
        );

        expect(edited(result).migrations.single.apply(const NumericalValue(80)), const NumericalValue(50));
      });
    });

    testWidgets('an adjustment that was never saved does not look values up', (tester) async {
      final repository = repositoryWithRecorded([recordedValue(const NumericalValue(80))]);
      final result = await pushAndSave(
        tester,
        NumericalAdjustmentPage.edit(adjustment: pressure),
        repository: repository,
        interact: () => setMax(tester, '50'),
      );

      verifyNever(() => repository.recordedValues(any()));
      expect(edited(result).pending, isNull);
    });
  });
}
