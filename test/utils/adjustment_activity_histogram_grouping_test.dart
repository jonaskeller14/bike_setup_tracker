import 'package:bike_setup_tracker/l10n/adjustment_value_text.dart';
import 'package:bike_setup_tracker/l10n/histogram_text.dart';
import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/adjustment_activity_histogram.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/services/component_slot.dart';
import 'package:bike_setup_tracker/utils/adjustment_activity_histogram_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AdjustmentActivityValue value(AdjustmentValue? value, int count, [String id = 'setup']) {
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
      values: [value(const StepValue(2), 3), value(const StepValue(-1), 4), value(const StepValue(2), 5, 'other')],
    );

    expect(result.bars.map((bar) => bar.exactValue), [const StepValue(-1), const StepValue(2)]);
    expect(result.bars.map((bar) => bar.activityCount), [4, 8]);
  });

  test('orders booleans and groups equal text values deterministically', () {
    final boolean = BooleanAdjustment(id: 'bool', name: 'Lockout', notes: null, unit: null);
    final text = TextAdjustment(id: 'text', name: 'Notes', notes: null, unit: null);

    expect(
      groupAdjustmentActivityHistogram(
        adjustment: boolean,
        values: [value(const BooleanValue(true), 2), value(const BooleanValue(false), 1)],
      ).labels,
      ['Off', 'On'],
    );
    expect(
      groupAdjustmentActivityHistogram(
        adjustment: text,
        values: [value(TextValue.orNull('Beta'), 2), value(TextValue.orNull('Alpha'), 1), value(TextValue.orNull('Beta'), 3, 'other')],
      ).labelsAndCounts,
      [('Alpha', 1), ('Beta', 5)],
    );
  });

  test('explodes categorical selections, de-duplicates, and uses option order', () {
    final adjustment = CategoricalAdjustment(
      id: 'category',
      name: 'Tyres',
      notes: null,
      unit: null,
      options: const {'Rear', 'Front', 'Spare'},
      multiSelect: true,
    );

    final result = groupAdjustmentActivityHistogram(
      adjustment: adjustment,
      values: [
        value(CategoricalValue(const ['Front', 'Rear', 'Front']), 4),
        value(CategoricalValue(const ['Front']), 2, 'other'),
      ],
    );

    expect(result.labelsAndCounts, [('Rear', 4), ('Front', 6)]);
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
      values: [for (var index = 0; index < 12; index++) value(NumericalValue(index / 2), 1, '$index')],
    );

    expect(result.isBinned, isFalse);
    expect(result.bars, hasLength(12));
    expect(result.labels.first, '0 psi');
    expect(result.labels.last, '5.5 psi');
  });

  test('bins thirteen values into eight stable half-open ranges', () {
    final adjustment = NumericalAdjustment(id: 'number', name: 'Value', notes: null, unit: null);
    final result = groupAdjustmentActivityHistogram(
      adjustment: adjustment,
      values: [for (var index = -6; index <= 6; index++) value(NumericalValue(index.toDouble()), 1, '$index')],
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
        for (var index = 0; index < 13; index++) value(DurationValue(Duration(seconds: index * 10)), 1, '$index'),
      ],
    );

    expect(result.isBinned, isTrue);
    expect(result.labels.first, startsWith('00:00:00–00:00:15'));
  });

  test('handles SAG as continuous numerical data', () {
    final adjustment = SagAdjustment(id: 'sag', name: 'SAG', notes: null, referenceTravelMm: 160);
    final result = groupAdjustmentActivityHistogram(
      adjustment: adjustment,
      values: [value(const NumericalValue(20.0), 2), value(const NumericalValue(25.0), 3, 'other')],
    );

    expect(result.labels, ['20 %', '25 %']);
  });

  test('ignores absent and zero-weight values and returns empty when none remain', () {
    final adjustment = NumericalAdjustment(id: 'number', name: 'Value', notes: null, unit: null);
    final result = groupAdjustmentActivityHistogram(
      adjustment: adjustment,
      values: [value(null, 4), value(const NumericalValue(2.0), 0), value(const NumericalValue(double.infinity), 2)],
    );

    expect(result.isEmpty, isTrue);
  });

  group('slot stacking', () {
    const frontTire = ComponentSlot(type: ComponentType.tire, parentType: ComponentType.wheelFront);
    const rearTire = ComponentSlot(type: ComponentType.tire, parentType: ComponentType.wheelRear);
    final pressure = NumericalAdjustment(id: 'pressure', name: 'Pressure', notes: null, unit: null);

    AdjustmentActivityValue mounted(AdjustmentValue value, int count, ComponentSlot? slot, String id) =>
        AdjustmentActivityValue(setupId: id, value: value, activityCount: count, slot: slot);

    void expectSegmentsSumToBars(AdjustmentActivityHistogram histogram) {
      for (final bar in histogram.bars) {
        expect(bar.segments.fold<int>(0, (sum, segment) => sum + segment.activityCount), bar.activityCount);
      }
    }

    test('stays unstacked when every activity shares one slot', () {
      final result = groupAdjustmentActivityHistogram(
        adjustment: pressure,
        values: [
          mounted(const NumericalValue(1.8), 2, rearTire, 'a'),
          mounted(const NumericalValue(2.1), 3, rearTire, 'b'),
        ],
      );

      expect(result.isStacked, isFalse);
      expect(result.bars.every((bar) => bar.segments.isEmpty), isTrue);
    });

    test('splits exact bars by slot, ordered front before rear and unknown last', () {
      final result = groupAdjustmentActivityHistogram(
        adjustment: pressure,
        values: [
          mounted(const NumericalValue(2.1), 4, rearTire, 'rear'),
          mounted(const NumericalValue(1.8), 3, frontTire, 'front'),
          mounted(const NumericalValue(1.8), 1, rearTire, 'rear-low'),
          mounted(const NumericalValue(2.1), 2, null, 'loose'),
        ],
      );

      expect(result.slots, [frontTire, rearTire, null]);
      expect(result.labelsAndCounts, [('1.8', 4), ('2.1', 6)]);
      expect(result.bars.first.segments, [(slot: frontTire, activityCount: 3), (slot: rearTire, activityCount: 1)]);
      expect(result.bars.last.segments, [(slot: rearTire, activityCount: 4), (slot: null, activityCount: 2)]);
      expect(englishL10n.chartHistogramSegment(result.slotLabel(null, englishL10n), 2), 'Not installed: 2 activities');
      expect(result.segmentLines(result.bars.first, englishL10n), [
        'Tire (Front Wheel): 3 activities',
        'Tire (Rear Wheel): 1 activity',
      ]);
    });

    test('keeps bins of the totals and splits each bin by slot', () {
      final result = groupAdjustmentActivityHistogram(
        adjustment: pressure,
        values: [
          for (var index = 0; index <= 12; index++)
            mounted(NumericalValue(index.toDouble()), 1, index < 6 ? frontTire : rearTire, '$index'),
        ],
      );
      final unstacked = groupAdjustmentActivityHistogram(
        adjustment: pressure,
        values: [for (var index = 0; index <= 12; index++) value(NumericalValue(index.toDouble()), 1, '$index')],
      );

      expect(result.isBinned, isTrue);
      expect(result.slots, [frontTire, rearTire]);
      expect(result.labelsAndCounts, unstacked.labelsAndCounts);
      expectSegmentsSumToBars(result);
    });

    test('counts each selected categorical option for its slot', () {
      final adjustment = CategoricalAdjustment(
        id: 'insert',
        name: 'Insert',
        notes: null,
        unit: null,
        options: const {'Foam', 'None'},
        multiSelect: true,
      );
      final result = groupAdjustmentActivityHistogram(
        adjustment: adjustment,
        values: [
          mounted(CategoricalValue(const ['Foam', 'None']), 2, frontTire, 'front'),
          mounted(CategoricalValue(const ['Foam']), 5, rearTire, 'rear'),
        ],
      );

      expect(result.labelsAndCounts, [('Foam', 7), ('None', 2)]);
      expect(result.bars.last.segments, [(slot: frontTire, activityCount: 2)]);
      expectSegmentsSumToBars(result);
    });

    test('splits discrete bars by slot', () {
      final rebound = StepAdjustment(
        id: 'step',
        name: 'Rebound',
        notes: null,
        unit: null,
        step: 1,
        min: 0,
        max: 10,
        visualization: StepAdjustmentVisualization.slider,
      );
      final result = groupAdjustmentActivityHistogram(
        adjustment: rebound,
        values: [mounted(const StepValue(3), 2, frontTire, 'front'), mounted(const StepValue(3), 1, rearTire, 'rear')],
      );

      expect(result.bars.single.segments, [(slot: frontTire, activityCount: 2), (slot: rearTire, activityCount: 1)]);
    });
  });

  group('binning on decimal bin edges', () {
    // 17 values spaced half a bin apart: the even ones sit exactly on a bin
    // edge, the odd ones in the middle of a bin. Binning by floor((v - min) / width)
    // alone drops edge values such as 1.7 into the bin below.
    final adjustment = NumericalAdjustment(id: 'number', name: 'Value', notes: null, unit: null);

    for (final start in [0.0, 1.6, -3.3, 0.1, 12.5, 100.0]) {
      for (final binWidth in [0.1, 0.05, 0.2, 0.25, 0.3, 0.7, 1.0, 2.5, 0.01]) {
        test('start $start, bin width $binWidth', () {
          final rides = [
            for (var index = 0; index <= 16; index++)
              (value: NumericalValue(double.parse((start + index * binWidth / 2).toStringAsFixed(6))), bin: (index ~/ 2).clamp(0, 7)),
          ];
          final histogram = groupAdjustmentActivityHistogram(
            adjustment: adjustment,
            values: [for (final (index, ride) in rides.indexed) value(ride.value, 1, 'setup-$index')],
          );

          expect(histogram.isBinned, isTrue);
          final expectedCounts = List<int>.filled(8, 0);
          for (final ride in rides) {
            expectedCounts[ride.bin]++;
            expect(
              adjustmentHistogramBarIndexesFor(histogram, ride.value),
              {ride.bin},
              reason: '${ride.value.value} should highlight bin ${ride.bin}',
            );
          }
          expect(histogram.bars.map((bar) => bar.activityCount), expectedCounts);
        });
      }
    }

    test('1.7 and 1.9 are not swallowed by the bin below (gallery data)', () {
      final pressures = [1.60, 1.65, 1.70, 1.80, 1.85, 1.90, 2.00, 2.05, 2.10, 2.20, 2.25, 2.30, 2.35, 2.40];
      final histogram = groupAdjustmentActivityHistogram(
        adjustment: adjustment,
        values: [for (final (index, pressure) in pressures.indexed) value(NumericalValue(pressure), 1, 'setup-$index')],
      );

      expect(histogram.bars.map((bar) => bar.activityCount), [2, 1, 2, 1, 2, 1, 2, 3]);
      expect(adjustmentHistogramBarIndexesFor(histogram, const NumericalValue(1.7)), {1});
      expect(adjustmentHistogramBarIndexesFor(histogram, const NumericalValue(1.95)), {3});
    });
  });

  group('adjustmentHistogramBarIndexesFor', () {
    test('matches the exact bar and nothing for an unridden or absent value', () {
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
      final histogram = groupAdjustmentActivityHistogram(
        adjustment: adjustment,
        values: [value(const StepValue(-1), 4), value(const StepValue(2), 3, 'other')],
      );

      expect(adjustmentHistogramBarIndexesFor(histogram, const StepValue(2)), {1});
      expect(adjustmentHistogramBarIndexesFor(histogram, const StepValue(5)), isEmpty);
      expect(adjustmentHistogramBarIndexesFor(histogram, null), isEmpty);
      expect(
        adjustmentHistogramBarIndexesFor(AdjustmentActivityHistogram.empty('step'), const StepValue(2)),
        isEmpty,
      );
    });

    test('matches every bar of a multi-select categorical value', () {
      final adjustment = CategoricalAdjustment(
        id: 'category',
        name: 'Tyres',
        notes: null,
        unit: null,
        options: const {'Rear', 'Front', 'Spare'},
        multiSelect: true,
      );
      final histogram = groupAdjustmentActivityHistogram(
        adjustment: adjustment,
        values: [
          value(CategoricalValue(const ['Rear']), 1),
          value(CategoricalValue(const ['Front']), 1, 'front'),
          value(CategoricalValue(const ['Spare']), 1, 'spare'),
        ],
      );

      expect(adjustmentHistogramBarIndexesFor(histogram, CategoricalValue(const ['Spare', 'Rear'])), {0, 2});
      expect(adjustmentHistogramBarIndexesFor(histogram, CategoricalValue(const ['Front'])), {1});
      expect(adjustmentHistogramBarIndexesFor(histogram, CategoricalValue(const [])), isEmpty);
    });

    test('puts a binned value into the bin that counted it', () {
      final adjustment = NumericalAdjustment(id: 'number', name: 'Value', notes: null, unit: null);
      final ridden = [for (var index = -6; index <= 6; index++) NumericalValue(index.toDouble())];
      final histogram = groupAdjustmentActivityHistogram(
        adjustment: adjustment,
        values: [for (final entry in ridden) value(entry, 1, entry.displayText(englishL10n))],
      );

      final perBar = List<int>.filled(histogram.bars.length, 0);
      for (final entry in ridden) {
        perBar[adjustmentHistogramBarIndexesFor(histogram, entry).single]++;
      }
      expect(perBar, histogram.bars.map((bar) => bar.activityCount));
      expect(adjustmentHistogramBarIndexesFor(histogram, const NumericalValue(6)), {histogram.bars.length - 1});
      expect(adjustmentHistogramBarIndexesFor(histogram, const NumericalValue(0.25)), {4});
      expect(adjustmentHistogramBarIndexesFor(histogram, const NumericalValue(6.5)), isEmpty);
      expect(adjustmentHistogramBarIndexesFor(histogram, const NumericalValue(-6.5)), isEmpty);
    });
  });
}

extension on AdjustmentActivityHistogram {
  List<String> get labels => [for (final bar in bars) barLabel(bar, englishL10n)];

  List<(String, int)> get labelsAndCounts => [for (final bar in bars) (barLabel(bar, englishL10n), bar.activityCount)];
}
