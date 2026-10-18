import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/rating/rating_metric.dart';
import 'package:bike_setup_tracker/models/recorded_value.dart';
import 'package:bike_setup_tracker/pages/metric/categorical_metric_page.dart';
import 'package:bike_setup_tracker/utils/value_migration_actions.dart';
import 'package:bike_setup_tracker/utils/value_migration_proposal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../adjustment/preset_key_test_utils.dart';
import '../value_migration_test_utils.dart';

void main() {
  const sheetTitle = 'Update recorded values';

  final metric = RatingMetric(
    adjustment: CategoricalAdjustment(
      id: 'grip',
      name: 'Grip',
      notes: null,
      unit: null,
      options: const {'Low', 'Mid', 'High'},
    ),
  );

  RecordedValue entryValue(List<String> options) =>
      recordedValue(CategoricalValue(options), source: RecordedValueSource.ratingEntry);

  Future<void> setOption(WidgetTester tester, int row, String text) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Option $row'), text);
    await tester.pumpAndSettle();
  }

  AdjustmentEditResult<RatingMetric> edited(Object? result) => result! as AdjustmentEditResult<RatingMetric>;

  testWidgets('a rename with values maps them to the new name', (tester) async {
    final result = await pushAndSave(
      tester,
      CategoricalMetricPage.edit(metric: metric, migrationContext: ValueMigrationContext(metric.adjustment)),
      repository: repositoryWithRecorded([
        entryValue(['Low']),
      ]),
      interact: () => setOption(tester, 1, 'Poor'),
      afterSave: () async {
        expect(find.text(sheetTitle), findsOneWidget);
        expect(find.textContaining('rating entry'), findsWidgets);
        expect(find.text('Renamed options'), findsOneWidget);
        await tester.tap(find.byKey(const Key('value-migration-confirm')));
        await tester.pumpAndSettle();
      },
    );

    final migrations = edited(result).migrations;
    expect(migrations, hasLength(1));
    expect(migrations.single.adjustmentId, 'grip');
    expect(migrations.single.apply(CategoricalValue(const ['Low'])), CategoricalValue(const ['Poor']));
  });

  testWidgets('a rename without values shows no sheet', (tester) async {
    final result = await pushAndSave(
      tester,
      CategoricalMetricPage.edit(metric: metric, migrationContext: ValueMigrationContext(metric.adjustment)),
      repository: repositoryWithRecorded(),
      interact: () => setOption(tester, 1, 'Poor'),
    );

    expect(find.text(sheetTitle), findsNothing);
    expect(edited(result).migrations, isEmpty);
  });

  testWidgets('a deleted option offers a target option', (tester) async {
    final result = await pushAndSave(
      tester,
      CategoricalMetricPage.edit(metric: metric, migrationContext: ValueMigrationContext(metric.adjustment)),
      repository: repositoryWithRecorded([
        entryValue(['Mid']),
      ]),
      interact: () async {
        await tester.tap(find.byTooltip('Remove option').at(1));
        await tester.pumpAndSettle();
      },
      afterSave: () async {
        await tester.tap(find.byType(DropdownButtonFormField<MigrationChoice>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('High').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('value-migration-confirm')));
        await tester.pumpAndSettle();
      },
    );

    expect(edited(result).migrations.single.apply(CategoricalValue(const ['Mid'])), CategoricalValue(const ['High']));
  });

  testWidgets('a re-edit shows a renamed option deleted later by its newer name', (tester) async {
    final saved = metric.adjustment as CategoricalAdjustment;
    final renamed = RatingMetric(adjustment: saved.copyWith(options: {'Poor', 'Mid', 'High'}));
    final recorded = [entryValue(['Low'])];
    final earlier = MigrationProposal.build(
      before: saved,
      after: renamed.adjustment,
      optionOrigins: const {'Poor': 'Low', 'Mid': 'Mid', 'High': 'High'},
      recorded: recorded,
    );
    final result = await pushAndSave(
      tester,
      CategoricalMetricPage.edit(metric: renamed, migrationContext: ValueMigrationContext(saved, pending: earlier)),
      repository: repositoryWithRecorded(recorded),
      interact: () async {
        await tester.tap(find.byTooltip('Remove option').at(0));
        await tester.pumpAndSettle();
      },
      afterSave: () async {
        expect(find.text("'Poor' was deleted"), findsWidgets);
        expect(find.textContaining('This replaces the change you confirmed earlier.'), findsOneWidget);
        await tester.tap(find.byKey(const Key('value-migration-confirm')));
        await tester.pumpAndSettle();
      },
    );

    expect(edited(result).migrations.single.apply(CategoricalValue(const ['Low'])), CategoricalValue(const ['Mid']));
  });
}
