import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/utils/preset_merge.dart';
import 'package:flutter_test/flutter_test.dart';

/// Linking a catalog product to a hand-built component merges the catalog
/// adjusters into the rider's own, so recorded values survive and guides find
/// their adjusters by preset key.

StepAdjustment _step(String name, {String? presetKey, int max = 10, String? notes}) => StepAdjustment(
  name: name,
  notes: notes,
  unit: null,
  presetKey: presetKey,
  step: 1,
  min: 0,
  max: max,
  visualization: StepAdjustmentVisualization.slider,
);

NumericalAdjustment _numerical(String name, {String? presetKey, AdjustmentUnit? unit, double? min, double? max}) =>
    NumericalAdjustment(name: name, notes: null, unit: unit, presetKey: presetKey, min: min, max: max);

const _psi = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'psi');
const _bar = KnownUnit(quantity: UnitQuantity.pressure, unitId: 'bar');

void main() {
  group('proposePresetMerge', () {
    test('matches by preset key role, even after a rename', () {
      final own = _step('My slow rebound', presetKey: 'fork:lsr');
      final catalog = _step('Low-speed rebound', presetKey: 'fork:lsr');

      expect(proposePresetMerge([own], [catalog]), [PresetMergeRow.merged(catalog, own)]);
    });

    test('matches a hand-built name against the catalog role', () {
      final own = _step('HSC');
      final catalog = _step('High-speed compression', presetKey: 'fork:hsc');

      expect(proposePresetMerge([own], [catalog]), [PresetMergeRow.merged(catalog, own)]);
    });

    test('matches by normalized name when the catalog id is overridden', () {
      final own = _step(' rebound ');
      final catalog = _step('Rebound', presetKey: 'fork:lsr');

      expect(proposePresetMerge([own], [catalog]), [PresetMergeRow.merged(catalog, own)]);
    });

    test('a role match wins over an earlier name match', () {
      final byName = _step('Rebound');
      final byRole = _step('Slow', presetKey: 'fork:lsr');
      final rebound = _step('Rebound', presetKey: 'fork:hsr');
      final lsr = _step('LSR', presetKey: 'fork:lsr');

      expect(proposePresetMerge([byName, byRole], [rebound, lsr]), [
        PresetMergeRow.merged(rebound, byName),
        PresetMergeRow.merged(lsr, byRole),
      ]);
    });

    test('types never cross', () {
      final own = BooleanAdjustment(name: 'Rebound', notes: null, unit: null);
      final catalog = _step('Rebound', presetKey: 'fork:rebound');

      expect(proposePresetMerge([own], [catalog]), [PresetMergeRow.newAdjustment(catalog)]);
    });

    test('SAG merges only with SAG', () {
      final own = _numerical('SAG', unit: SagAdjustment.percentUnit);
      final catalog = SagAdjustment(name: 'SAG', notes: null, presetKey: 'fork:sag');

      expect(proposePresetMerge([own], [catalog]), [PresetMergeRow.newAdjustment(catalog)]);
    });

    test('an existing adjustment is linked at most once', () {
      final own = _step('Rebound');
      final first = _step('Rebound', presetKey: 'fork:rebound');
      final second = _step('Rebound', presetKey: 'fork:rebound_2');

      expect(proposePresetMerge([own], [first, second]), [
        PresetMergeRow.merged(first, own),
        PresetMergeRow.newAdjustment(second),
      ]);
    });
  });

  group('mergeAdjustment', () {
    test('keeps id, name and unit, and stamps the catalog preset key', () {
      final own = _numerical('Air pressure', unit: _bar);
      final catalog = _numerical('Pressure', presetKey: 'fork:pressure', unit: _psi, min: 0, max: 100);

      final merged = mergeAdjustment(own, catalog, const [NumericalValue(5)]);

      expect(merged.adjustment, own.copyWith(presetKey: 'fork:pressure'));
      expect(merged.keptOwnRange, isFalse, reason: 'A unit difference is left to the guide');
    });

    test('adopts the catalog range when every recorded value stays valid', () {
      final own = _step('LSR', max: 20);
      final catalog = _step('LSR', presetKey: 'fork:lsr', max: 16);

      final merged = mergeAdjustment(own, catalog, const [StepValue(4), StepValue(16)]);

      expect(merged.adjustment, isA<StepAdjustment>().having((a) => a.max, 'max', 16));
      expect(merged.adjustment.id, own.id);
      expect(merged.keptOwnRange, isFalse);
    });

    test('keeps the rider range when a recorded value would be invalid', () {
      final own = _step('LSR', max: 20);
      final catalog = _step('LSR', presetKey: 'fork:lsr', max: 16);

      final merged = mergeAdjustment(own, catalog, const [StepValue(18)]);

      expect(merged.adjustment, own.copyWith(presetKey: 'fork:lsr'));
      expect(merged.keptOwnRange, isTrue);
    });

    test('never adopts a placeholder max', () {
      final own = _step('LSR', max: 12);
      final catalog = _step('LSR', presetKey: 'fork:lsr', max: StepAdjustment.unknownMaxPlaceholder);

      final merged = mergeAdjustment(own, catalog, const [], unknownMaxKeys: {'fork:lsr'});

      expect(merged.adjustment, own.copyWith(presetKey: 'fork:lsr'));
      expect(merged.keptOwnRange, isFalse);
      expect(
        applyPresetMerge([own], [PresetMergeRow.merged(catalog, own)], const {}, unknownMaxKeys: {'fork:lsr'}).adjustments,
        [own.copyWith(presetKey: 'fork:lsr')],
      );
    });

    test('the placeholder warning in notes alone does not mark a max as unknown', () {
      final own = _step('LSR', max: 12);
      final catalog = _step('LSR', presetKey: 'fork:lsr', max: 16, notes: StepAdjustment.unknownMaxWarning);

      final merged = mergeAdjustment(own, catalog, const []);

      expect(merged.adjustment, isA<StepAdjustment>().having((a) => a.max, 'max', 16));
    });

    test('adopts a numerical range in the same unit', () {
      final own = _numerical('Pressure', unit: _psi);
      final catalog = _numerical('Pressure', presetKey: 'fork:pressure', unit: _psi, min: 40, max: 120);

      final merged = mergeAdjustment(own, catalog, const [NumericalValue(80)]);

      expect(merged.adjustment, own.copyWith(presetKey: 'fork:pressure', min: 40.0, max: 120.0));
    });

    test('a categorical adjustment gains the catalog options it lacks', () {
      final own = CategoricalAdjustment(name: 'Spacers', notes: null, unit: null, options: const {'none', '1 x 10cc'});
      final catalog = CategoricalAdjustment(
        name: 'Spacers',
        notes: null,
        unit: null,
        presetKey: 'fork:volume_spacers',
        options: const {'1 x 10cc', '2 x 10cc'},
      );

      final merged = mergeAdjustment(own, catalog, [
        CategoricalValue(const ['none']),
      ]);

      expect((merged.adjustment as CategoricalAdjustment).options, {'none', '1 x 10cc', '2 x 10cc'});
    });

    test('a recorded explicit clear does not block gaining catalog options', () {
      final own = CategoricalAdjustment(name: 'Spacers', notes: null, unit: null, options: const {'none'});
      final catalog = CategoricalAdjustment(
        name: 'Spacers',
        notes: null,
        unit: null,
        presetKey: 'fork:volume_spacers',
        options: const {'1 x 10cc'},
      );

      final merged = mergeAdjustment(own, catalog, [
        CategoricalValue(const ['none']),
        CategoricalValue(const []),
      ]);

      expect(merged.keptOwnRange, isFalse);
      expect((merged.adjustment as CategoricalAdjustment).options, {'none', '1 x 10cc'});
    });

    test('SAG only gets the preset key', () {
      final own = SagAdjustment(name: 'Sag', notes: null, referenceTravelMm: 160);
      final catalog = SagAdjustment(name: 'SAG', notes: null, presetKey: 'fork:sag');

      expect(mergeAdjustment(own, catalog, const []).adjustment, own.copyWith(presetKey: 'fork:sag'));
    });
  });

  group('applyPresetMerge', () {
    test('merges linked adjustments in place, keeps the rest and appends added ones', () {
      final pressure = _numerical('Air pressure', unit: _psi);
      final lsr = _step('LSR', max: 20);
      final mine = BooleanAdjustment(name: 'Lockout', notes: null, unit: null);
      final catalogPressure = _numerical('Pressure', presetKey: 'fork:pressure', unit: _psi);
      final catalogLsr = _step('LSR', presetKey: 'fork:lsr', max: 16);
      final catalogHsc = _step('HSC', presetKey: 'fork:hsc', max: 8);
      final catalogSag = SagAdjustment(name: 'SAG', notes: null, presetKey: 'fork:sag');

      final result = applyPresetMerge(
        [pressure, lsr, mine],
        [
          PresetMergeRow.merged(catalogPressure, pressure),
          PresetMergeRow.merged(catalogLsr, lsr),
          PresetMergeRow.newAdjustment(catalogHsc),
          PresetMergeRow.notAdded(catalogSag),
        ],
        {
          lsr.id: const [StepValue(18)],
        },
      );

      expect(result.adjustments.map((a) => a.id), [pressure.id, lsr.id, mine.id, catalogHsc.id]);
      expect(result.adjustments.map((a) => a.presetKey), ['fork:pressure', 'fork:lsr', null, 'fork:hsc']);
      expect((result.adjustments[1] as StepAdjustment).max, 20, reason: 'A recorded 18 keeps the own range');
      expect(result.adjustments[2], same(mine));
      expect(result.newAdjustments, [catalogHsc]);
    });
  });

  group('replaceWithPreset', () {
    test('uses only the catalog adjusters and reports what it removes', () {
      final own = _step('LSR');
      final catalog = _step('LSR', presetKey: 'fork:lsr');

      final result = replaceWithPreset([own], [catalog]);

      expect(result.adjustments, [catalog]);
      expect(result.newAdjustments, [catalog]);
      expect(result.removed, [own]);
    });
  });

  group('migrateRecordedValues', () {
    test('applies a staged migration before a range is checked', () {
      final migration = ValueMigration('p', const [ConvertUnitStep(_bar, _psi)]);

      final converted = migrateRecordedValues(
        {
          'p': const [NumericalValue(5)],
          'other': const [NumericalValue(5)],
        },
        {'p': migration},
      );

      expect((converted['p']!.single as NumericalValue).value, closeTo(72.5, 0.1));
      expect(converted['other'], const [NumericalValue(5)]);
    });

    test('a range in the new unit is adopted once the values are converted', () {
      final own = _numerical('Pressure', unit: _psi);
      final catalog = _numerical('Pressure', presetKey: 'fork:pressure', unit: _psi, min: 40, max: 120);
      final converted = migrateRecordedValues(
        {
          own.id: const [NumericalValue(5)],
        },
        {own.id: ValueMigration(own.id, const [ConvertUnitStep(_bar, _psi)])},
      );

      expect(mergeAdjustment(own, catalog, converted[own.id]!).keptOwnRange, isFalse);
      expect(mergeAdjustment(own, catalog, const [NumericalValue(5)]).keptOwnRange, isTrue);
    });
  });
}
