import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/rating/rating_metric.dart';
import 'package:bike_setup_tracker/models/recorded_value.dart';
import 'package:bike_setup_tracker/pages/metric/duration_metric_page.dart';
import 'package:bike_setup_tracker/pages/metric/step_metric_page.dart';
import 'package:bike_setup_tracker/utils/value_migration_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../adjustment/preset_key_test_utils.dart';
import '../value_migration_test_utils.dart';

void main() {
  const sheetTitle = 'Update recorded values';

  RecordedValue entryValue(AdjustmentValue value) => recordedValue(value, source: RecordedValueSource.ratingEntry);

  AdjustmentEditResult<RatingMetric> edited(Object? result) => result! as AdjustmentEditResult<RatingMetric>;

  group('StepMetricPage', () {
    final metric = RatingMetric(
      adjustment: StepAdjustment(
        id: 'feel',
        name: 'Feel',
        notes: null,
        unit: null,
        step: 1,
        min: 0,
        max: 12,
        visualization: StepAdjustmentVisualization.slider,
      ),
    );

    Future<void> setStep(WidgetTester tester, String step) async {
      await tester.enterText(find.widgetWithText(TextFormField, 'Step'), step);
      await tester.pumpAndSettle();
    }

    testWidgets('a step change that puts values off the grid offers Snap', (tester) async {
      final result = await pushAndSave(
        tester,
        StepMetricPage.edit(metric: metric, migrationContext: ValueMigrationContext(metric.adjustment)),
        repository: repositoryWithRecorded([entryValue(const StepValue(4))]),
        interact: () => setStep(tester, '3'),
        afterSave: () async {
          expect(find.text(sheetTitle), findsOneWidget);
          expect(find.textContaining('rating entry'), findsWidgets);
          expect(find.text('Snap'), findsOneWidget);
          await tester.tap(find.byKey(const Key('value-migration-confirm')));
          await tester.pumpAndSettle();
        },
      );

      final migrations = edited(result).migrations;
      expect(migrations, hasLength(1));
      expect(migrations.single.adjustmentId, 'feel');
      expect(migrations.single.apply(const StepValue(4)), const StepValue(3));
    });

    testWidgets('a step change that keeps values on the grid shows no sheet', (tester) async {
      final result = await pushAndSave(
        tester,
        StepMetricPage.edit(metric: metric, migrationContext: ValueMigrationContext(metric.adjustment)),
        repository: repositoryWithRecorded([entryValue(const StepValue(4))]),
        interact: () => setStep(tester, '2'),
      );

      expect(find.text(sheetTitle), findsNothing);
      expect(edited(result).migrations, isEmpty);
    });
  });

  group('DurationMetricPage', () {
    final metric = RatingMetric(
      adjustment: DurationAdjustment(
        id: 'lap',
        name: 'Lap time',
        notes: null,
        unit: null,
        min: Duration.zero,
        max: const Duration(hours: 5),
      ),
      weight: -1,
    );

    testWidgets('lowering the max below a recorded value offers Clamp', (tester) async {
      final result = await pushAndSave(
        tester,
        DurationMetricPage.edit(metric: metric, migrationContext: ValueMigrationContext(metric.adjustment)),
        repository: repositoryWithRecorded([entryValue(const DurationValue(Duration(hours: 4)))]),
        interact: () => setDurationHours(tester, 'Max Duration', from: 5, to: 3),
        afterSave: () async {
          expect(find.text(sheetTitle), findsOneWidget);
          expect(find.text('Clamp'), findsOneWidget);
          await tester.tap(find.byKey(const Key('value-migration-confirm')));
          await tester.pumpAndSettle();
        },
      );

      final migrations = edited(result).migrations;
      expect(migrations, hasLength(1));
      expect(migrations.single.apply(const DurationValue(Duration(hours: 4))), const DurationValue(Duration(hours: 3)));
    });

    testWidgets('lowering the max without recorded values shows no sheet', (tester) async {
      final result = await pushAndSave(
        tester,
        DurationMetricPage.edit(metric: metric, migrationContext: ValueMigrationContext(metric.adjustment)),
        repository: repositoryWithRecorded(),
        interact: () => setDurationHours(tester, 'Max Duration', from: 5, to: 3),
      );

      expect(find.text(sheetTitle), findsNothing);
      expect(edited(result).migrations, isEmpty);
      expect((edited(result).value.adjustment as DurationAdjustment).max, const Duration(hours: 3));
    });
  });
}
