import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/rating/rating_metric.dart';
import 'package:bike_setup_tracker/models/recorded_value.dart';
import 'package:bike_setup_tracker/pages/metric/numerical_metric_page.dart';
import 'package:bike_setup_tracker/utils/value_migration_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../adjustment/preset_key_test_utils.dart';
import '../value_migration_test_utils.dart';

void main() {
  const sheetTitle = 'Update recorded values';
  const psi = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi');
  const bar = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'bar');

  final metric = RatingMetric(
    adjustment: NumericalAdjustment(id: 'effort', name: 'Effort', notes: null, unit: psi, min: 0, max: 100),
  );

  RecordedValue entryValue(double value) =>
      recordedValue(NumericalValue(value), source: RecordedValueSource.ratingEntry);

  Future<void> setMax(WidgetTester tester, String max) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Max Value'), max);
    await tester.pumpAndSettle();
  }

  Future<void> pickUnit(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(const Key('unit_picker_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  AdjustmentEditResult<RatingMetric> edited(Object? result) => result! as AdjustmentEditResult<RatingMetric>;

  testWidgets('narrowing the range without recorded values saves without a sheet', (tester) async {
    final result = await pushAndSave(
      tester,
      NumericalMetricPage.edit(metric: metric, migrationContext: ValueMigrationContext(metric.adjustment)),
      repository: repositoryWithRecorded(),
      interact: () => setMax(tester, '50'),
    );

    expect(find.text(sheetTitle), findsNothing);
    expect(edited(result).migrations, isEmpty);
  });

  testWidgets('narrowing the range with values outside it shows the sheet and clamps', (tester) async {
    final result = await pushAndSave(
      tester,
      NumericalMetricPage.edit(metric: metric, migrationContext: ValueMigrationContext(metric.adjustment)),
      repository: repositoryWithRecorded([entryValue(80)]),
      interact: () => setMax(tester, '50'),
      afterSave: () async {
        expect(find.text(sheetTitle), findsOneWidget);
        expect(find.textContaining('rating entry'), findsWidgets);
        await tester.tap(find.byKey(const Key('value-migration-confirm')));
        await tester.pumpAndSettle();
      },
    );

    final migrations = edited(result).migrations;
    expect(migrations, hasLength(1));
    expect(migrations.single.adjustmentId, 'effort');
    expect(migrations.single.apply(const NumericalValue(80)), const NumericalValue(50));
  });

  testWidgets('a unit change with values offers Convert and returns the conversion', (tester) async {
    final result = await pushAndSave(
      tester,
      NumericalMetricPage.edit(metric: metric, migrationContext: ValueMigrationContext(metric.adjustment)),
      repository: repositoryWithRecorded([entryValue(10)]),
      interact: () => pickUnit(tester, 'bar'),
      afterSave: () async {
        await tester.tap(find.byKey(const Key('value-migration-confirm')));
        await tester.pumpAndSettle();
      },
    );

    expect(edited(result).migrations, [
      ValueMigration('effort', const [ConvertUnitStep(psi, bar)]),
    ]);
  });

  testWidgets('a unit change without values shows no sheet', (tester) async {
    final result = await pushAndSave(
      tester,
      NumericalMetricPage.edit(metric: metric, migrationContext: ValueMigrationContext(metric.adjustment)),
      repository: repositoryWithRecorded(),
      interact: () => pickUnit(tester, 'bar'),
    );

    expect(find.text(sheetTitle), findsNothing);
    expect(edited(result).migrations, isEmpty);
  });

  testWidgets('cancelling the sheet keeps the page open', (tester) async {
    final result = await pushAndSave(
      tester,
      NumericalMetricPage.edit(metric: metric, migrationContext: ValueMigrationContext(metric.adjustment)),
      repository: repositoryWithRecorded([entryValue(80)]),
      interact: () => setMax(tester, '50'),
      afterSave: () async {
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
      },
    );

    expect(result, isNull);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('a rename does not look recorded values up', (tester) async {
    final repository = repositoryWithRecorded([entryValue(80)]);
    final result = await pushAndSave(
      tester,
      NumericalMetricPage.edit(metric: metric, migrationContext: ValueMigrationContext(metric.adjustment)),
      repository: repository,
      interact: () => enterName(tester, 'Renamed'),
    );

    verifyNever(() => repository.recordedValues(any()));
    expect(edited(result).migrations, isEmpty);
  });
}
