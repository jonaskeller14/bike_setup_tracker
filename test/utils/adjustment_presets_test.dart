import 'package:bike_setup_tracker/l10n/l10n.dart';
import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component.dart';
import 'package:bike_setup_tracker/utils/adjustment_presets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/german_l10n.dart';

/// Everything about a preset that must not depend on the language.
String _shape(Adjustment preset) => [
  preset.presetKey,
  preset.runtimeType,
  preset.unit,
  if (preset is NumericalAdjustment) '${preset.min}..${preset.max}',
  if (preset is StepAdjustment)
    '${preset.step} ${preset.min}..${preset.max} ${preset.visualization} ${preset.dialColor}',
  if (preset is CategoricalAdjustment) '${preset.options.length} options',
].join(' ');

void main() {
  final snake = RegExp('(?<=[a-z])(?=[A-Z])');
  final format = RegExp(r'^[a-z][a-z_]*:[a-z][a-z0-9]*(_[a-z0-9]+)*$');

  for (final l10n in allLocalizations) {
    group('adjustment presets in ${l10n.localeName}', () {
      final componentPresets = componentAdjustmentPresetsFor(l10n);
      final all = [...componentPresets.values.expand((presets) => presets), ...personAdjustmentPresetsFor(l10n)];

      test('every preset has a unique key of the form <type>:<snake_case>', () {
        final keys = all.map((preset) => preset.presetKey!).toList();
        expect(keys.toSet().length, keys.length);
        for (final key in keys) {
          expect(format.hasMatch(key), isTrue, reason: key);
        }
      });

      test('a component preset key starts with its component type', () {
        for (final MapEntry(key: type, value: presets) in componentPresets.entries) {
          final prefix = type.name.split(snake).join('_').toLowerCase();
          for (final preset in presets) {
            expect(preset.presetKey, startsWith('$prefix:'), reason: '$type');
          }
        }
      });

      test('names and notes are not empty', () {
        for (final preset in all) {
          expect(preset.name.trim(), isNotEmpty, reason: preset.presetKey);
          expect(preset.notes?.trim(), isNotEmpty, reason: preset.presetKey);
        }
      });

      test('categorical presets offer options', () {
        for (final preset in all.whereType<CategoricalAdjustment>()) {
          expect(preset.options, isNotEmpty, reason: preset.presetKey);
          expect(preset.options.every((option) => option.trim().isNotEmpty), isTrue, reason: preset.presetKey);
        }
      });

      test('a preset adjustment is fresh each time', () {
        final other = componentAdjustmentPresetsFor(l10n);
        expect(identical(componentPresets[ComponentType.fork]!.first, other[ComponentType.fork]!.first), isFalse);
        expect(
          identical(
            (componentPresets[ComponentType.equipment]![1] as CategoricalAdjustment).options,
            (componentPresets[ComponentType.equipment]![2] as CategoricalAdjustment).options,
          ),
          isFalse,
        );
      });
    });
  }

  group('across languages', () {
    test('only name, notes and options differ', () {
      final english = componentAdjustmentPresetsFor(englishL10n);
      final german = componentAdjustmentPresetsFor(germanL10n);
      expect(german.keys, english.keys);
      for (final type in english.keys) {
        expect(german[type]!.map(_shape).toList(), english[type]!.map(_shape).toList(), reason: '$type');
      }
      expect(
        personAdjustmentPresetsFor(germanL10n).map(_shape).toList(),
        personAdjustmentPresetsFor(englishL10n).map(_shape).toList(),
      );
    });

    test('keep their order', () {
      final keys = componentAdjustmentPresetsFor(englishL10n)[ComponentType.shock]!.map((p) => p.presetKey).toList();
      expect(keys.take(4), ['shock:lockout', 'shock:pressure', 'shock:spring_rate', 'shock:sag']);
      expect(
        componentAdjustmentPresetsFor(englishL10n)[ComponentType.fork]!.map((p) => p.presetKey),
        isNot(contains('fork:spring_rate')),
      );
    });

    test('read in German', () {
      final fork = componentAdjustmentPresetsFor(germanL10n)[ComponentType.fork]!;
      expect(fork.firstWhere((p) => p.presetKey == 'fork:rebound').name, 'Zugstufe');
      expect(fork.firstWhere((p) => p.presetKey == 'fork:lsc').name, 'LSC');
      expect(ridingWeightPresetFor(germanL10n).name, 'Fahrergewicht');
      final style = personAdjustmentPresetsFor(germanL10n).whereType<CategoricalAdjustment>().single;
      expect(style.options, {'Komfort', 'Ausgewogen', 'Race'});
    });

    test('the English wording is unchanged', () {
      final fork = componentAdjustmentPresetsFor(englishL10n)[ComponentType.fork]!;
      expect(fork.firstWhere((p) => p.presetKey == 'fork:rebound').name, 'Rebound');
      expect(ridingWeightPresetFor(englishL10n).name, 'Riding weight');
      final style = personAdjustmentPresetsFor(englishL10n).whereType<CategoricalAdjustment>().single;
      expect(style.options, {'Comfort', 'Balanced', 'Race'});
    });

    test('the SAG template differs by component type', () {
      expect(sagPresetFor(englishL10n, ComponentType.fork).notes, contains('XC 15%'));
      expect(sagPresetFor(englishL10n, ComponentType.shock).notes, contains('XC 20-25%'));
      expect(sagPresetFor(germanL10n, ComponentType.shock).notes, contains('Richtwerte'));
      expect(sagPresetFor(germanL10n, ComponentType.shock).presetKey, 'shock:sag');
    });
  });

  group('adjustmentPresetNameVariants', () {
    test('lists the name in every language, normalized', () {
      final rebound = componentAdjustmentPresetsFor(
        englishL10n,
      )[ComponentType.fork]!.firstWhere((p) => p.presetKey == 'fork:rebound');
      expect(adjustmentPresetNameVariants(rebound), {'rebound', 'zugstufe'});
    });

    test('a preset without a known key has just its own name', () {
      final custom = NumericalAdjustment(name: ' Custom ', unit: null, notes: null);
      expect(adjustmentPresetNameVariants(custom), {'custom'});
    });
  });
}
