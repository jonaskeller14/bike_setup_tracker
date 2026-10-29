import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NumericalRange', () {
    const range = NumericalRange(-5, 20);

    test('contains its bounds and the values between them', () {
      expect(range.contains(const NumericalValue(-5)), isTrue);
      expect(range.contains(const NumericalValue(20)), isTrue);
      expect(range.contains(const NumericalValue(7.5)), isTrue);
      expect(range.contains(const NumericalValue(20.0001)), isFalse);
      expect(range.contains(const NumericalValue(-5.0001)), isFalse);
    });

    test('a clamped value is always contained', () {
      for (final value in [-1e9, -5.0001, -5.0, 0.0, 20.0, 20.5, 1e9]) {
        final clamped = range.clamp(NumericalValue(value));
        expect(range.contains(clamped), isTrue, reason: 'for $value -> $clamped');
      }
    });

    test('open bounds clamp nothing', () {
      const open = NumericalRange(double.negativeInfinity, double.infinity);
      expect(open.clamp(const NumericalValue(-1e12)), const NumericalValue(-1e12));
      expect(open.contains(const NumericalValue(1e12)), isTrue);
    });
  });

  group('StepGrid', () {
    test('contains only values on the grid counted from min', () {
      const grid = StepGrid(2, 11, 3);
      expect(
        [
          for (var v = 0; v <= 13; v++)
            if (grid.contains(StepValue(v))) v,
        ],
        [2, 5, 8, 11],
      );
    });

    test('a clamped value is always contained', () {
      for (final grid in const [StepGrid(1, 20, 4), StepGrid(0, 10, 3), StepGrid(-6, 6, 4), StepGrid(0, 0, 1)]) {
        for (var value = -30; value <= 30; value++) {
          final clamped = grid.clamp(StepValue(value));
          expect(grid.contains(clamped), isTrue, reason: '$grid: $value -> $clamped');
        }
      }
    });

    test('a value on the grid stays as it is', () {
      const grid = StepGrid(0, 10, 2);
      expect(grid.clamp(const StepValue(6)), const StepValue(6));
    });
  });

  group('DurationRange', () {
    const range = DurationRange(Duration(minutes: 1), Duration(minutes: 5));

    test('a clamped value is always contained', () {
      for (final seconds in [-30, 0, 59, 60, 180, 300, 301, 3600]) {
        final clamped = range.clamp(DurationValue(Duration(seconds: seconds)));
        expect(range.contains(clamped), isTrue, reason: 'for ${seconds}s -> $clamped');
      }
    });

    test('a null bound is open', () {
      const openMin = DurationRange(null, Duration(minutes: 5));
      expect(openMin.contains(const DurationValue(Duration(seconds: -30))), isTrue);
      expect(openMin.clamp(const DurationValue(Duration(hours: 1))), const DurationValue(Duration(minutes: 5)));
    });
  });

  group('every range', () {
    const ranges = <ValueRange>[NumericalRange(0, 1), StepGrid(0, 10, 1), DurationRange(null, null)];

    test('passes values of another type through and does not contain them', () {
      const values = <AdjustmentValue>[
        NumericalValue(99),
        StepValue(99),
        DurationValue(Duration(days: 9)),
        BooleanValue(true),
      ];
      for (final range in ranges) {
        for (final value in values) {
          if (range.appliesTo(value)) continue;
          expect(range.clamp(value), value, reason: '$range on $value');
          expect(range.contains(value), isFalse, reason: '$range on $value');
        }
      }
    });

    test('equality compares only the bounds', () {
      expect(const NumericalRange(0, 1), const NumericalRange(0, 1));
      expect(const NumericalRange(0, 1), isNot(const NumericalRange(0, 2)));
      expect(const StepGrid(0, 10, 2), isNot(const StepGrid(0, 10, 1)));
      expect(
        const DurationRange(null, Duration(minutes: 1)).hashCode,
        const DurationRange(null, Duration(minutes: 1)).hashCode,
      );
    });
  });

  group('adjustment ranges', () {
    test('isValidValue matches its range', () {
      final step = StepAdjustment(
        name: 'Clicks',
        notes: null,
        unit: null,
        step: 2,
        min: 0,
        max: 10,
        visualization: StepAdjustmentVisualization.slider,
      );
      for (var v = -2; v <= 12; v++) {
        expect(step.isValidValue(StepValue(v)), step.range.contains(StepValue(v)));
      }
      expect(step.isValidValue(const NumericalValue(2)), isFalse);
    });

    test('a SAG adjustment keeps its fixed 0–100 % range', () {
      final sag = SagAdjustment(name: 'Sag', notes: null);
      expect(sag.range, const NumericalRange(SagAdjustment.minPercent, SagAdjustment.maxPercent));
    });

    test('an unbounded numerical adjustment accepts any number', () {
      final open = NumericalAdjustment(name: 'Pressure', notes: null, unit: null);
      expect(open.isValidValue(const NumericalValue(-1e12)), isTrue);
      expect(open.isValidValue(const NumericalValue(1e12)), isTrue);
    });
  });
}
