import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/adjustment_activity_histogram.dart';
import 'package:bike_setup_tracker/utils/adjustment_activity_histogram_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AdjustmentActivityValue value(dynamic value, int count, [String id = 'setup']) {
    return AdjustmentActivityValue(setupId: id, value: value, activityCount: count);
  }

  test('aggregates and naturally orders step values', () {
    final adjustment = StepAdjustment(
      id: 'step',
      name: 'Rebound',
      notes: null,
      unit: null,
      step: 1,
      min: -10,
      max: 10,
      visualization: StepAdjustmentVisualization.slider,
    );

    final result = groupAdjustmentActivityHistogram(
      adjustment: adjustment,
      values: [value(2, 3), value(-1, 4), value(2, 5, 'other')],
    );

    expect(result.bars.map((bar) => bar.exactValue), [-1, 2]);
    expect(result.bars.map((bar) => bar.activityCount), [4, 8]);
  });

  test('orders booleans and groups equal text values deterministically', () {
    final boolean = BooleanAdjustment(id: 'bool', name: 'Lockout', notes: null, unit: null);
    final text = TextAdjustment(id: 'text', name: 'Notes', notes: null, unit: null);

    expect(
      groupAdjustmentActivityHistogram(
        adjustment: boolean,
        values: [value(true, 2), value(false, 1)],
      ).bars.map((bar) => bar.label),
      ['Off', 'On'],
    );
    expect(
      groupAdjustmentActivityHistogram(
        adjustment: text,
        values: [value('Beta', 2), value('Alpha', 1), value('Beta', 3, 'other')],
      ).bars.map((bar) => (bar.label, bar.activityCount)),
      [('Alpha', 1), ('Beta', 5)],
    );
  });

  test('explodes categorical selections, de-duplicates, and uses option order', () {
    final adjustment = CategoricalAdjustment(
      id: 'category',
      name: 'Tyres',
      notes: null,
      unit: null,
      options: {'Rear', 'Front', 'Spare'},
      multiSelect: true,
    );

    final result = groupAdjustmentActivityHistogram(
      adjustment: adjustment,
      values: [
        value(['Front', 'Rear', 'Front'], 4),
        value(['Front'], 2, 'other'),
      ],
    );

    expect(result.bars.map((bar) => (bar.label, bar.activityCount)), [('Rear', 4), ('Front', 6)]);
  });

  test('keeps twelve numerical values exact with unit-aware labels', () {
    final adjustment = NumericalAdjustment(
      id: 'number',
      name: 'Pressure',
      notes: null,
      unit: AdjustmentUnit.fromLegacy('psi'),
    );
    final result = groupAdjustmentActivityHistogram(
      adjustment: adjustment,
      values: [for (var index = 0; index < 12; index++) value(index / 2, 1, '$index')],
    );

    expect(result.isBinned, isFalse);
    expect(result.bars, hasLength(12));
    expect(result.bars.first.label, '0 psi');
    expect(result.bars.last.label, '5.5 psi');
  });

  test('bins thirteen values into eight stable half-open ranges', () {
    final adjustment = NumericalAdjustment(id: 'number', name: 'Value', notes: null, unit: null);
    final result = groupAdjustmentActivityHistogram(
      adjustment: adjustment,
      values: [for (var index = -6; index <= 6; index++) value(index.toDouble(), 1, '$index')],
    );

    expect(result.isBinned, isTrue);
    expect(result.bars, hasLength(adjustmentHistogramBinCount));
    expect(result.bars.first.lowerBound, -6);
    expect(result.bars.first.includesUpperBound, isFalse);
    expect(result.bars.last.upperBound, 6);
    expect(result.bars.last.includesUpperBound, isTrue);
    expect(result.bars.fold<int>(0, (sum, bar) => sum + bar.activityCount), 13);
  });

  test('groups duration values numerically and formats duration ranges', () {
    final adjustment = DurationAdjustment(id: 'duration', name: 'Time', notes: null, unit: null);
    final result = groupAdjustmentActivityHistogram(
      adjustment: adjustment,
      values: [
        for (var index = 0; index < 13; index++) value(Duration(seconds: index * 10), 1, '$index'),
      ],
    );

    expect(result.isBinned, isTrue);
    expect(result.bars.first.label, startsWith('00:00:00–00:00:15'));
  });

  test('handles SAG as continuous numerical data', () {
    final adjustment = SagAdjustment(id: 'sag', name: 'SAG', notes: null, referenceTravelMm: 160);
    final result = groupAdjustmentActivityHistogram(
      adjustment: adjustment,
      values: [value(20.0, 2), value(25.0, 3, 'other')],
    );

    expect(result.bars.map((bar) => bar.label), ['20 %', '25 %']);
  });

  test('ignores absent and zero-weight values and returns empty when none remain', () {
    final adjustment = NumericalAdjustment(id: 'number', name: 'Value', notes: null, unit: null);
    final result = groupAdjustmentActivityHistogram(
      adjustment: adjustment,
      values: [value(null, 4), value(2.0, 0), value(double.infinity, 2)],
    );

    expect(result.isEmpty, isTrue);
  });
}
