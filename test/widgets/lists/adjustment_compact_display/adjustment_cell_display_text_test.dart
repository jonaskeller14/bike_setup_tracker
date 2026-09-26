import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/widgets/lists/adjustment_compact_display/adjustment_cell.dart';
import 'package:flutter_test/flutter_test.dart';

/// [valueText] and [previousText] are what a *changed* cell prints for
/// [value] and [previousValue] — both already bounded and, for Duration,
/// pairwise shortened. The `→` is not part of either: it is a styled span
/// the cell widget adds (`previousSegmentSpan`).
typedef _Case = ({
  String type,
  Adjustment adjustment,
  dynamic value,
  dynamic previousValue,
  String valueText,
  String previousText,
});

void main() {
  final cases = <_Case>[
    (
      type: 'boolean',
      adjustment: BooleanAdjustment(id: 'b', name: 'Lockout', notes: null, unit: null),
      value: true,
      previousValue: false,
      valueText: 'On',
      previousText: 'Off',
    ),
    (
      type: 'categorical',
      adjustment: CategoricalAdjustment(
        id: 'c',
        name: 'Tokens',
        notes: null,
        unit: null,
        options: {'A', 'B', 'C'},
        multiSelect: true,
        counted: true,
      ),
      value: ['A', 'C', 'C', 'C'],
      previousValue: ['A', 'A', 'B', 'C', 'C', 'C'],
      valueText: 'A, C (3)',
      // 'A (2), B, C (3)' is over budget, so the last option is dropped whole.
      previousText: 'A (2), B…',
    ),
    (
      type: 'step',
      adjustment: StepAdjustment(
        id: 's',
        name: 'Rebound',
        notes: null,
        unit: null,
        step: 1,
        min: 0,
        max: 20,
        visualization: StepAdjustmentVisualization.slider,
      ),
      value: 12,
      previousValue: 10,
      valueText: '12',
      previousText: '10',
    ),
    (
      type: 'numerical',
      adjustment: NumericalAdjustment(id: 'n', name: 'Pressure', notes: null, unit: null, min: 0, max: 200),
      value: 85.5,
      previousValue: 80.0,
      valueText: '85.5',
      previousText: '80',
    ),
    (
      type: 'text',
      adjustment: TextAdjustment(id: 't', name: 'Mode', notes: null, unit: null),
      value: 'Open',
      previousValue: 'Closed',
      valueText: 'Open',
      previousText: 'Closed',
    ),
    (
      type: 'duration',
      adjustment: DurationAdjustment(id: 'd', name: 'Burn-in', notes: null, unit: null),
      value: const Duration(hours: 1, minutes: 35),
      previousValue: const Duration(hours: 1, minutes: 20),
      valueText: '1:35',
      previousText: '1:20',
    ),
  ];

  CellDisplayText displayOf(_Case c, {required dynamic previousValue, bool isError = false}) => AdjustmentCell.resolve(
    adjustment: c.adjustment,
    value: c.value,
    previousValue: previousValue,
    isError: isError,
  ).displayText;

  group('AdjustmentCell.displayText', () {
    for (final c in cases) {
      group(c.type, () {
        test('a changed cell carries the previous value, without the arrow', () {
          final display = displayOf(c, previousValue: c.previousValue);
          expect(display.value, c.valueText);
          expect(display.previous, c.previousText);
        });

        test('initial, constant and error cells show no previous value', () {
          for (final display in [
            displayOf(c, previousValue: null),
            displayOf(c, previousValue: c.value),
            displayOf(c, previousValue: c.previousValue, isError: true),
          ]) {
            expect(display.value, Adjustment.formatValue(c.value));
            expect(display.previous, isNull);
            expect(display.hasPrevious, isFalse);
          }
        });
      });
    }

    test('no cell ever renders a signed delta', () {
      for (final c in cases) {
        for (final previousValue in [null, c.value, c.previousValue]) {
          final display = displayOf(c, previousValue: previousValue);
          expect(display.value, isNot(startsWith('+')));
          expect(display.previous ?? '', isNot(startsWith('+')));
        }
      }
    });

    test('a numeric change shows the previous value, not the difference', () {
      final numeric = cases.firstWhere((c) => c.type == 'numerical');
      expect(displayOf(numeric, previousValue: numeric.previousValue).previous, '80');
    });

    test('line breaks in either value are flattened to spaces', () {
      final text = cases.firstWhere((c) => c.type == 'text');
      final display = AdjustmentCell.resolve(
        adjustment: text.adjustment,
        value: 'front\nrear',
        previousValue: 'left\nright',
      ).displayText;
      expect(display.value, 'front rear');
      expect(display.previous, 'left right');
    });
  });

  group('previous value bounding', () {
    final text = TextAdjustment(id: 't', name: 'Tyre', notes: null, unit: null);
    final list = CategoricalAdjustment(
      id: 'c',
      name: 'Tyre',
      notes: null,
      unit: null,
      options: {'Gravel', 'Mud', 'Sand', 'Continental Kryptotal', 'X'},
      multiSelect: true,
      counted: true,
    );

    CellDisplayText displayOf(Adjustment adjustment, dynamic value, dynamic previousValue) =>
        AdjustmentCell.resolve(adjustment: adjustment, value: value, previousValue: previousValue).displayText;

    test('a previous value within the budget prints whole', () {
      expect(displayOf(text, 'Fox 38', 'Fox 36').previous, 'Fox 36');
    });

    test('a long previous value is head-truncated', () {
      expect(displayOf(text, 'Fox 38', 'RockShox Lyrik Ultimate').previous, 'RockShox L…');
    });

    test('a list drops whole options once the budget is spent', () {
      expect(
        displayOf(list, ['Mud'], ['Gravel', 'Gravel', 'Mud', 'Sand']).previous,
        'Gravel (2)…',
      );
    });

    test('a single over-budget option falls back to character truncation', () {
      expect(displayOf(list, ['X'], ['Continental Kryptotal', 'X']).previous, 'Continenta…');
    });

    test('the current value is never truncated', () {
      expect(displayOf(text, 'RockShox Lyrik Ultimate', 'Fox 36').value, 'RockShox Lyrik Ultimate');
    });
  });

  group('Duration pairs', () {
    final duration = DurationAdjustment(id: 'd', name: 'Burn-in', notes: null, unit: null);

    CellDisplayText displayOf(Duration value, Duration? previousValue) =>
        AdjustmentCell.resolve(adjustment: duration, value: value, previousValue: previousValue).displayText;

    test('zero seconds on both sides drops the seconds', () {
      final display = displayOf(const Duration(hours: 1, minutes: 35), const Duration(hours: 1, minutes: 20));
      expect(display.previous, '1:20');
      expect(display.value, '1:35');
    });

    test('zero hours on both sides drops the hours and unpads the minutes', () {
      final display = displayOf(const Duration(minutes: 6), const Duration(minutes: 5, seconds: 30));
      expect(display.previous, '5:30');
      expect(display.value, '6:00');

      final underOneMinute = displayOf(const Duration(minutes: 1, seconds: 10), const Duration(seconds: 45));
      expect(underOneMinute.previous, '0:45');
      expect(underOneMinute.value, '1:10');
    });

    test('a segment is never dropped on one side only', () {
      final display = displayOf(const Duration(hours: 1, minutes: 5), const Duration(minutes: 59));
      expect(display.previous, '00:59:00');
      expect(display.value, '01:05:00');
    });

    test('an unchanged Duration keeps the shared hh:mm:ss format', () {
      expect(displayOf(const Duration(hours: 1, minutes: 35), null).value, '01:35:00');
    });
  });
}
