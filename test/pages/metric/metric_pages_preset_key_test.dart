import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/rating/rating_metric.dart';
import 'package:bike_setup_tracker/pages/metric/boolean_metric_page.dart';
import 'package:bike_setup_tracker/pages/metric/categorical_metric_page.dart';
import 'package:bike_setup_tracker/pages/metric/duration_metric_page.dart';
import 'package:bike_setup_tracker/pages/metric/numerical_metric_page.dart';
import 'package:bike_setup_tracker/pages/metric/step_metric_page.dart';
import 'package:bike_setup_tracker/pages/metric/text_metric_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../adjustment/preset_key_test_utils.dart';

void main() {
  group('BooleanMetricPage', () {
    final metric = RatingMetric(
      adjustment: BooleanAdjustment(name: 'Preset', notes: null, unit: null, presetKey: testPresetKey),
    );
    presetKeyTests(
      template: () => BooleanMetricPage.template(metric: metric),
      edit: () => BooleanMetricPage.edit(metric: metric),
      add: () => BooleanMetricPage.add(),
    );
  });

  group('CategoricalMetricPage', () {
    final metric = RatingMetric(
      adjustment: CategoricalAdjustment(
        name: 'Preset',
        notes: null,
        unit: null,
        options: const {'A', 'B'},
        presetKey: testPresetKey,
      ),
    );
    presetKeyTests(
      template: () => CategoricalMetricPage.template(metric: metric),
      edit: () => CategoricalMetricPage.edit(metric: metric),
      add: () => CategoricalMetricPage.add(),
      fillAdd: (tester) => tester.enterText(find.widgetWithText(TextFormField, 'Option 1'), 'A'),
    );
  });

  // Add mode is left out: min and max are required and only settable through
  // the duration picker sheet; with no initial metric there is no key to keep.
  group('DurationMetricPage', () {
    final metric = RatingMetric(
      adjustment: DurationAdjustment(
        name: 'Preset',
        notes: null,
        unit: null,
        min: Duration.zero,
        max: const Duration(hours: 1),
        presetKey: testPresetKey,
      ),
    );
    presetKeyTests(
      template: () => DurationMetricPage.template(metric: metric),
      edit: () => DurationMetricPage.edit(metric: metric),
    );
  });

  group('NumericalMetricPage', () {
    final metric = RatingMetric(
      adjustment: NumericalAdjustment(
        name: 'Preset',
        notes: null,
        unit: const KnownUnit(quantity: UnitQuantity.mass, unitId: 'kilograms'),
        min: 0,
        max: 10,
        presetKey: testPresetKey,
      ),
    );
    presetKeyTests(
      template: () => NumericalMetricPage.template(metric: metric),
      edit: () => NumericalMetricPage.edit(metric: metric),
      add: () => NumericalMetricPage.add(),
      fillAdd: (tester) async {
        await tester.enterText(find.widgetWithText(TextFormField, 'Min Value'), '0');
        await tester.enterText(find.widgetWithText(TextFormField, 'Max Value'), '10');
      },
    );
  });

  group('StepMetricPage', () {
    final metric = RatingMetric(
      adjustment: StepAdjustment(
        name: 'Preset',
        notes: null,
        unit: null,
        step: 1,
        min: 0,
        max: 10,
        visualization: StepAdjustmentVisualization.slider,
        presetKey: testPresetKey,
      ),
    );
    presetKeyTests(
      template: () => StepMetricPage.template(metric: metric),
      edit: () => StepMetricPage.edit(metric: metric),
      add: () => StepMetricPage.add(),
      fillAdd: (tester) => tester.enterText(find.widgetWithText(TextFormField, 'Max Value'), '10'),
    );
  });

  group('TextMetricPage', () {
    final metric = RatingMetric(
      adjustment: TextAdjustment(name: 'Preset', notes: null, unit: null, presetKey: testPresetKey),
    );
    presetKeyTests(
      template: () => TextMetricPage.template(metric: metric),
      edit: () => TextMetricPage.edit(metric: metric),
      add: () => TextMetricPage.add(),
    );
  });
}
