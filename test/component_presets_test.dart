import 'dart:io';

import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component_preset.dart';
import 'package:bike_setup_tracker/utils/component_preset_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// CI correctness gate for the component-preset catalog (`data/component_presets/`).
///
/// Enumerates every brand YAML file, parses it with the same [parseBrandFile]
/// the app uses, then **instantiates every adjustment spec** via the strict
/// [Adjustment.fromYaml] and asserts the whole catalog is well-formed. Because
/// `fromYaml` rejects unknown keys, this test doubles as a typo detector: an AI
/// data edit that breaks the schema fails CI here rather than in the app.
void main() {
  final presetDir = Directory(p.join(Directory.current.path, 'data', 'component_presets'));

  final yamlFiles = presetDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => p.extension(f.path) == '.yaml')
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('preset catalog directory contains brand files', () {
    expect(presetDir.existsSync(), isTrue, reason: 'missing ${presetDir.path}');
    expect(yamlFiles, isNotEmpty, reason: 'no brand YAML files found');
  });

  // Collected across all files for the global duplicate-key check.
  final allPresetKeys = <String, String>{}; // authored key -> file

  for (final file in yamlFiles) {
    final relative = p.relative(file.path, from: presetDir.path);
    // Directory name (fork/shock) the file lives in — must match component_type.
    final expectedTypeDir = p.split(relative).first;

    group(relative, () {
      late List<ComponentPresetVariant> variants;

      setUpAll(() {
        variants = parseBrandFile(file.readAsStringSync());
      });

      test('parses to at least one variant', () {
        expect(variants, isNotEmpty);
      });

      test('component_type matches directory', () {
        for (final v in variants) {
          expect(v.componentType.name, expectedTypeDir,
              reason: '${v.key}: type ${v.componentType.name} in $expectedTypeDir/');
        }
      });

      test('every adjustment spec builds into a valid Adjustment', () {
        for (final v in variants) {
          final specs = [
            ...v.adjustmentSpecs,
            for (final d in v.dampers) ...d.adjustmentSpecs,
          ];
          for (final spec in specs) {
            final adjustment = spec.build(); // strict fromYaml — throws on typos
            expect(adjustment.name, isNotEmpty, reason: v.key);
            _assertAdjustmentInvariants(adjustment, v.key);
          }
        }
      });

      test('urls are http(s)', () {
        for (final v in variants) {
          final url = v.url;
          if (url == null) continue;
          final uri = Uri.tryParse(url);
          expect(uri != null && (uri.scheme == 'http' || uri.scheme == 'https'), isTrue,
              reason: '${v.key}: bad url "$url"');
        }
      });

      test('same-named models are consistent generations', () {
        final byModel = <String, List<ComponentPresetVariant>>{};
        for (final v in variants) {
          byModel.putIfAbsent(v.model, () => []).add(v);
        }
        for (final MapEntry(key: model, value: group) in byModel.entries) {
          final generations = group.map((v) => v.yearRange).toSet();
          if (generations.length == 1) continue;
          // The picker merges same-named models into one row, so the years are
          // all that tells the generations apart, and the category labels the
          // shared row rather than any single block.
          expect(generations, isNot(contains(null)),
              reason: '$relative: "$model" spans generations, so every block '
                  'needs a year_range');
          expect(group.map((v) => v.category).toSet(), hasLength(1),
              reason: '$relative: generations of "$model" disagree on category');
        }
      });

      test('keys are authored, ASCII-kebab and type-prefixed', () {
        // The key is persisted on user components, so its shape is frozen:
        // see tool/preset_keys.dart and SCHEMA.md.
        for (final v in variants) {
          expect(v.key, matches(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$')),
              reason: '"${v.key}" (${v.model} ${v.trim}) is not lowercase kebab-case');
          expect(v.key, startsWith('${v.componentType.name}-'),
              reason: '"${v.key}" does not start with its component type');
        }
      });

      test('keys are globally unique', () {
        for (final v in variants) {
          final existing = allPresetKeys[v.key];
          expect(existing, isNull,
              reason: 'duplicate key "${v.key}" in $relative and $existing');
          allPresetKeys[v.key] = relative;
        }
      });
    });
  }
}

void _assertAdjustmentInvariants(Adjustment adjustment, String key) {
  switch (adjustment) {
    case StepAdjustment(:final min, :final max, :final step):
      expect(min, lessThan(max), reason: '$key: step "${adjustment.name}" min<max');
      expect(step, greaterThan(0), reason: '$key: step "${adjustment.name}" step>0');
    case NumericalAdjustment(:final min, :final max):
      expect(min, lessThanOrEqualTo(max), reason: '$key: numerical "${adjustment.name}"');
    case CategoricalAdjustment(:final options):
      expect(options, isNotEmpty, reason: '$key: categorical "${adjustment.name}" options');
    case BooleanAdjustment():
      break;
    default:
      fail('$key: unexpected adjustment type ${adjustment.runtimeType} in preset data');
  }
}
