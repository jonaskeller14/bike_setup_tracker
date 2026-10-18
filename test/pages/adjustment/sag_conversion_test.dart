import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/pages/adjustment/numerical_adjustment_page.dart';
import 'package:bike_setup_tracker/pages/adjustment/sag_adjustment_page.dart';
import 'package:bike_setup_tracker/repositories/app_repository.dart';
import 'package:bike_setup_tracker/theme.dart';
import 'package:bike_setup_tracker/utils/value_migration_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../value_migration_test_utils.dart';
import 'preset_key_test_utils.dart';

/// Phase 2: existing users upgrade a plain "SAG" percentage numerical to the
/// SagAdjustment subtype (and back), keeping the same adjustment id so setup
/// values, history and charts stay attached. See doc/20260715_sag_adjustment_type.md §7.
void main() {
  const bannerLabel = 'Convert to SAG adjustment';

  NumericalAdjustment percentSag({String name = 'SAG'}) => NumericalAdjustment(
        id: 'adj-1',
        name: name,
        notes: 'measured static',
        unit: const CustomUnit('%'),
        min: 0,
        max: 100,
      );

  Future<Object?> openNumerical(
    WidgetTester tester,
    NumericalAdjustment adjustment, {
    bool enableSagConversion = true,
  }) async {
    Object? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<Object>(
                context,
                MaterialPageRoute(
                  builder: (context) => NumericalAdjustmentPage.edit(
                    adjustment: adjustment,
                    enableSagConversion: enableSagConversion,
                  ),
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
    return result;
  }

  group('Convert-to-SAG offer visibility', () {
    testWidgets('shown for a % adjustment named "sag"', (tester) async {
      await openNumerical(tester, percentSag());
      expect(find.text(bannerLabel), findsOneWidget);
    });

    testWidgets('hidden when the name has nothing to do with sag', (tester) async {
      await openNumerical(tester, percentSag(name: 'Pressure'));
      expect(find.text(bannerLabel), findsNothing);
    });

    testWidgets('hidden when the unit is not %', (tester) async {
      await openNumerical(
        tester,
        NumericalAdjustment(
          id: 'adj-1',
          name: 'SAG',
          notes: null,
          unit: const KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi'),
          min: 0,
          max: 100,
        ),
      );
      expect(find.text(bannerLabel), findsNothing);
    });

    testWidgets('hidden when conversion is disabled (e.g. person adjustment)', (tester) async {
      await openNumerical(tester, percentSag(), enableSagConversion: false);
      expect(find.text(bannerLabel), findsNothing);
    });
  });

  testWidgets('upgrading returns a SagAdjustment with the same id and captured travel',
      (tester) async {
    Object? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<Object>(
                context,
                MaterialPageRoute(
                  builder: (context) => NumericalAdjustmentPage.edit(
                    adjustment: percentSag().copyWith(presetKey: testPresetKey),
                    enableSagConversion: true,
                    componentType: ComponentType.fork,
                  ),
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

    await tester.tap(find.text(bannerLabel));
    await tester.pumpAndSettle();

    // We're now on the SAG page (via pushReplacement). Enter travel and save.
    expect(find.text('Edit SAG Adjustment'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'e.g. 160'), '160');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    final sag = (result! as AdjustmentEditResult<Adjustment>).value;
    expect(sag, isA<SagAdjustment>());
    sag as SagAdjustment;
    expect(sag.id, 'adj-1'); // same row → values/history stay attached
    expect(sag.name, 'SAG');
    expect(sag.notes, 'measured static');
    expect(sag.referenceTravelMm, 160);
    expect(sag.presetKey, testPresetKey);
  });

  testWidgets('downgrading returns a plain numerical (% / 0..100, no travel, same id)',
      (tester) async {
    Object? result;
    final sag = SagAdjustment(
      id: 'adj-1',
      name: 'SAG',
      notes: 'measured static',
      referenceTravelMm: 160,
      presetKey: testPresetKey,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: materialAppTheme,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.push<Object>(
                context,
                MaterialPageRoute(
                  builder: (context) => SagAdjustmentPage.edit(adjustment: sag),
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

    await tester.tap(find.byType(PopupMenuButton<void>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Convert to plain numerical'));
    await tester.pumpAndSettle();

    // Now on the numerical page (via pushReplacement). Save unchanged.
    expect(find.text('Edit Numerical Adjustment'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    final AdjustmentEditResult<Adjustment> edit = result! as AdjustmentEditResult<Adjustment>;
    final numerical = edit.value;
    expect(numerical, isNot(isA<SagAdjustment>()));
    expect(numerical, isA<NumericalAdjustment>());
    expect(numerical.id, 'adj-1');
    expect(numerical.name, 'SAG');
    expect(numerical.unit, const CustomUnit('%'));
    expect((numerical as NumericalAdjustment).min, 0);
    expect(numerical.max, 100);
    expect(numerical.presetKey, testPresetKey);
  });

  group('recorded values across the swap', () {
    /// Opens [page] and returns a getter for the result it pops.
    Future<Object? Function()> open(WidgetTester tester, Widget page, List<NumericalValue> values) async {
      Object? result;
      await tester.pumpWidget(
        ChangeNotifierProvider<AppRepository>.value(
          value: repositoryWithRecorded([for (final value in values) recordedValue(value)]),
          child: MaterialApp(
            theme: materialAppTheme,
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await Navigator.push<Object>(context, MaterialPageRoute(builder: (context) => page));
                },
                child: const Text('Open Page'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open Page'));
      await tester.pumpAndSettle();
      return () => result;
    }

    testWidgets('downgrading checks the numerical edit against the saved SAG', (tester) async {
      final sag = SagAdjustment(id: 'adj-1', name: 'SAG', notes: null);
      final page = SagAdjustmentPage.edit(adjustment: sag, migrationContext: ValueMigrationContext(sag));
      final result = await open(tester, page, const [NumericalValue(10)]);

      await tester.tap(find.byType(PopupMenuButton<void>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Convert to plain numerical'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Max Value (optional)'), '5');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(find.text('Update recorded values'), findsOneWidget);
      await tester.tap(find.byKey(const Key('value-migration-confirm')));
      await tester.pumpAndSettle();

      final migration = (result()! as AdjustmentEditResult<Adjustment>).migrations.single;
      expect(migration.apply(const NumericalValue(10)), const NumericalValue(5));
    });

    testWidgets('converting to SAG offers Clamp for values outside 0..100 %', (tester) async {
      final unbounded = NumericalAdjustment(id: 'adj-1', name: 'SAG', notes: null, unit: const CustomUnit('%'));
      final page = NumericalAdjustmentPage.edit(
        adjustment: unbounded,
        enableSagConversion: true,
        migrationContext: ValueMigrationContext(unbounded),
      );
      final result = await open(tester, page, const [NumericalValue(120), NumericalValue(30)]);

      await tester.tap(find.text(bannerLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(find.text('Clamp'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      await tester.tap(find.byKey(const Key('value-migration-confirm')));
      await tester.pumpAndSettle();

      final edit = result()! as AdjustmentEditResult<Adjustment>;
      expect(edit.value, isA<SagAdjustment>());
      expect(edit.migrations.single.apply(const NumericalValue(120)), const NumericalValue(100));
      expect(edit.migrations.single.apply(const NumericalValue(30)), const NumericalValue(30));
    });
  });

  final sagPreset = SagAdjustment(name: 'Preset', notes: null, presetKey: testPresetKey);
  presetKeyTests(
    template: () => SagAdjustmentPage.template(adjustment: sagPreset),
    edit: () => SagAdjustmentPage.edit(adjustment: sagPreset),
    add: () => SagAdjustmentPage.add(),
  );
}
