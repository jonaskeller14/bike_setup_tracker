import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/adjustment/value_migration.dart';
import 'package:flutter_test/flutter_test.dart';

const _psi = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi');
const _bar = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'bar');

CategoricalValue _options(List<String> options) => CategoricalValue(options);

ValueMigration _migration(List<ValueMigrationStep> steps) => ValueMigration('a', steps);

AdjustmentValue? _apply(ValueMigrationStep step, AdjustmentValue value) => _migration([step]).apply(value);

NumericalRange _numerical({double? min, double? max}) =>
    NumericalAdjustment(name: 'Pressure', notes: null, unit: null, min: min, max: max).range;

StepGrid _step({required int min, required int max, required int step}) => StepAdjustment(
  name: 'Clicks',
  notes: null,
  unit: null,
  step: step,
  min: min,
  max: max,
  visualization: StepAdjustmentVisualization.slider,
).range;

DurationRange _duration({Duration? min, Duration? max}) =>
    DurationAdjustment(name: 'Time', notes: null, unit: null, min: min, max: max).range;

void main() {
  group('ConvertUnitStep', () {
    test('converts numerical values', () {
      final converted = _apply(const ConvertUnitStep(_psi, _bar), const NumericalValue(10));
      expect((converted as NumericalValue).value, closeTo(0.689476, 1e-5));
    });

    test('passes other value types through', () {
      expect(_apply(const ConvertUnitStep(_psi, _bar), const StepValue(3)), const StepValue(3));
      expect(_apply(const ConvertUnitStep(_psi, _bar), _options(['A'])), _options(['A']));
    });
  });

  group('MapOptionsStep', () {
    test('renames an option', () {
      expect(_apply(MapOptionsStep(const {'A': 'B'}), _options(['A'])), _options(['B']));
    });

    test('swaps two options in one step', () {
      expect(_apply(MapOptionsStep(const {'A': 'B', 'B': 'A'}), _options(['A', 'B', 'C'])), _options(['B', 'A', 'C']));
    });

    test('deleting an option removes it from a multi-selection', () {
      expect(_apply(MapOptionsStep(const {'B': null}), _options(['A', 'B', 'C'])), _options(['A', 'C']));
    });

    test('deleting the only selected option removes the row', () {
      expect(_apply(MapOptionsStep(const {'A': null}), _options(['A'])), isNull);
      expect(_apply(MapOptionsStep(const {'A': null}), _options(['A', 'A'])), isNull);
    });

    test('leaves unmapped options and an empty selection alone', () {
      expect(_apply(MapOptionsStep(const {'A': 'B'}), _options(['C'])), _options(['C']));
      expect(_apply(MapOptionsStep(const {'A': null}), _options([])), _options([]));
    });

    test('passes other value types through', () {
      expect(_apply(MapOptionsStep(const {'A': 'B'}), TextValue.orNull('A')!), TextValue.orNull('A'));
    });
  });

  group('DedupeOptionsStep', () {
    test('keeps the first occurrence of each option', () {
      expect(
        _apply(const DedupeOptionsStep(), _options(['Spacer', 'Spacer', 'Spacer'])),
        _options(['Spacer']),
      );
      expect(_apply(const DedupeOptionsStep(), _options(['B', 'A', 'B', 'A'])), _options(['B', 'A']));
    });

    test('passes other value types through', () {
      expect(_apply(const DedupeOptionsStep(), const StepValue(1)), const StepValue(1));
    });
  });

  group('MapCombinationsStep', () {
    final step = MapCombinationsStep(const {
      {'Soft', 'Firm'}: 'Medium',
      {'Soft', 'Hard'}: null,
    });

    test('maps a combination to one option, whatever the order and counts', () {
      expect(_apply(step, _options(['Soft', 'Firm'])), _options(['Medium']));
      expect(_apply(step, _options(['Firm', 'Soft', 'Soft'])), _options(['Medium']));
    });

    test('removes the row of a combination mapped to null', () {
      expect(_apply(step, _options(['Hard', 'Soft'])), isNull);
    });

    test('leaves other selections alone', () {
      expect(_apply(step, _options(['Soft'])), _options(['Soft']));
      expect(_apply(step, _options(['Soft', 'Firm', 'Hard'])), _options(['Soft', 'Firm', 'Hard']));
    });

    test('equality ignores set identity and entry order', () {
      expect(
        MapCombinationsStep(const {
          {'A', 'B'}: 'C',
          {'D'}: null,
        }),
        MapCombinationsStep(const {
          {'D'}: null,
          {'B', 'A'}: 'C',
        }),
      );
      expect(
        MapCombinationsStep(const {
          {'A', 'B'}: 'C',
        }).hashCode,
        MapCombinationsStep(const {
          {'B', 'A'}: 'C',
        }).hashCode,
      );
      expect(
        MapCombinationsStep(const {
          {'A', 'B'}: 'C',
        }),
        isNot(
          MapCombinationsStep(const {
            {'A', 'B'}: 'D',
          }),
        ),
      );
    });
  });

  group('ClampToRangeStep', () {
    group('numerical', () {
      final step = ClampToRangeStep(_numerical(min: 10, max: 20));

      test('clamps below and above', () {
        expect(_apply(step, const NumericalValue(5)), const NumericalValue(10));
        expect(_apply(step, const NumericalValue(25)), const NumericalValue(20));
      });

      test('keeps values in range, bounds included', () {
        expect(_apply(step, const NumericalValue(15)), const NumericalValue(15));
        expect(_apply(step, const NumericalValue(10)), const NumericalValue(10));
        expect(_apply(step, const NumericalValue(20)), const NumericalValue(20));
      });

      test('an open bound does not clamp', () {
        final openMax = ClampToRangeStep(_numerical(min: 0));
        expect(_apply(openMax, const NumericalValue(1e9)), const NumericalValue(1e9));
        expect(_apply(openMax, const NumericalValue(-1)), const NumericalValue(0));
      });

      test('passes other value types through', () {
        expect(_apply(step, const StepValue(99)), const StepValue(99));
      });
    });

    group('step', () {
      final step = ClampToRangeStep(_step(min: 2, max: 11, step: 3));

      test('snaps a value between grid points to the nearest one', () {
        expect(_apply(step, const StepValue(4)), const StepValue(5));
        expect(_apply(step, const StepValue(6)), const StepValue(5));
        expect(_apply(step, const StepValue(7)), const StepValue(8));
      });

      test('keeps values already on the grid', () {
        expect(_apply(step, const StepValue(8)), const StepValue(8));
      });

      test('clamps below the range to the minimum', () {
        expect(_apply(step, const StepValue(-4)), const StepValue(2));
      });

      test('clamps above the range to the last grid value in range', () {
        expect(_apply(step, const StepValue(40)), const StepValue(11));
        expect(_apply(ClampToRangeStep(_step(min: 0, max: 10, step: 3)), const StepValue(40)), const StepValue(9));
      });

      test('a rounded-up grid value beyond the maximum stays in range', () {
        expect(_apply(ClampToRangeStep(_step(min: 0, max: 10, step: 3)), const StepValue(10)), const StepValue(9));
      });

      test('results are valid for the target', () {
        final target = _step(min: 1, max: 20, step: 4);
        for (var value = -5; value <= 30; value++) {
          final snapped = _apply(ClampToRangeStep(target), StepValue(value))!;
          expect(target.contains(snapped), isTrue, reason: 'for $value -> $snapped');
        }
      });
    });

    group('duration', () {
      test('clamps to both bounds', () {
        final step = ClampToRangeStep(_duration(min: const Duration(minutes: 1), max: const Duration(minutes: 5)));
        expect(_apply(step, const DurationValue(Duration(seconds: 10))), const DurationValue(Duration(minutes: 1)));
        expect(_apply(step, const DurationValue(Duration(minutes: 9))), const DurationValue(Duration(minutes: 5)));
        expect(_apply(step, const DurationValue(Duration(minutes: 3))), const DurationValue(Duration(minutes: 3)));
      });

      test('an open bound does not clamp', () {
        final step = ClampToRangeStep(_duration(max: const Duration(minutes: 5)));
        expect(_apply(step, const DurationValue(Duration(seconds: -30))), const DurationValue(Duration(seconds: -30)));
        expect(_apply(step, const DurationValue(Duration(hours: 1))), const DurationValue(Duration(minutes: 5)));
      });
    });
  });

  group('ClearOutOfRangeStep', () {
    test('clears a numerical value outside the range and keeps one inside', () {
      final step = ClearOutOfRangeStep(_numerical(min: 0, max: 10));
      expect(_apply(step, const NumericalValue(11)), isNull);
      expect(_apply(step, const NumericalValue(10)), const NumericalValue(10));
    });

    test('clears a step value off the grid', () {
      final step = ClearOutOfRangeStep(_step(min: 0, max: 10, step: 2));
      expect(_apply(step, const StepValue(3)), isNull);
      expect(_apply(step, const StepValue(4)), const StepValue(4));
    });

    test('passes values of another type through', () {
      expect(_apply(ClearOutOfRangeStep(_numerical(min: 0, max: 10)), const StepValue(99)), const StepValue(99));
      expect(_apply(ClearOutOfRangeStep(_numerical(min: 0, max: 10)), _options(['A'])), _options(['A']));
    });
  });

  group('ClearAllStep', () {
    test('removes the row of a value', () {
      expect(_apply(const ClearAllStep(), const NumericalValue(1)), isNull);
      expect(_apply(const ClearAllStep(), const BooleanValue(true)), isNull);
    });

    test('removes the row of a categorical value', () {
      expect(_apply(const ClearAllStep(), _options(['A'])), isNull);
    });
  });

  group('ValueMigration', () {
    test('applies steps in order', () {
      final migration = _migration([
        const ConvertUnitStep(_psi, _bar),
        ClampToRangeStep(_numerical(min: 0, max: 1)),
      ]);
      expect(migration.apply(const NumericalValue(100)), const NumericalValue(1));
      expect((migration.apply(const NumericalValue(10)) as NumericalValue).value, closeTo(0.689476, 1e-5));
    });

    test('a removed row stays removed', () {
      final migration = _migration([const ClearAllStep(), const ConvertUnitStep(_psi, _bar)]);
      expect(migration.apply(const NumericalValue(1)), isNull);
    });

    test('an unresolved value is not touched by a mapping', () {
      expect(_apply(MapOptionsStep(const {'A': 'B'}), const UnresolvedValue('[1]')), const UnresolvedValue('[1]'));
    });

    test('isNoOp is true only without steps', () {
      expect(_migration([]).isNoOp, isTrue);
      expect(_migration([const DedupeOptionsStep()]).isNoOp, isFalse);
    });

    group('equality', () {
      test('compares adjustment id and steps', () {
        expect(_migration([const DedupeOptionsStep()]), _migration([const DedupeOptionsStep()]));
        expect(_migration([const DedupeOptionsStep()]).hashCode, _migration([const DedupeOptionsStep()]).hashCode);
        expect(_migration([const DedupeOptionsStep()]), isNot(ValueMigration('b', const [DedupeOptionsStep()])));
        expect(_migration([const DedupeOptionsStep()]), isNot(_migration([const ClearAllStep()])));
      });

      test('steps compare by their content', () {
        expect(MapOptionsStep(const {'A': 'B'}), MapOptionsStep(const {'A': 'B'}));
        expect(MapOptionsStep(const {'A': 'B'}), isNot(MapOptionsStep(const {'A': 'C'})));
        expect(ClampToRangeStep(_numerical(max: 1)), isNot(ClampToRangeStep(_numerical(max: 2))));
        expect(ClampToRangeStep(_numerical(max: 1)), isNot(ClearOutOfRangeStep(_numerical(max: 1))));
      });

      test('range steps ignore the adjustment they came from', () {
        final renamed = NumericalAdjustment(name: 'Renamed', notes: 'Notes', unit: _bar, max: 1);
        expect(ClampToRangeStep(renamed.range), ClampToRangeStep(_numerical(max: 1)));
        expect(ClampToRangeStep(renamed.range).hashCode, ClampToRangeStep(_numerical(max: 1)).hashCode);
      });
    });

    test('toString names the steps', () {
      expect(_migration([const ConvertUnitStep(_psi, _bar)]).toString(), contains('pressure:psi -> pressure:bar'));
    });
  });
}
