import 'dart:io';

import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component_preset.dart';
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
  final allPresetKeys = <String, String>{}; // presetKey -> file

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
              reason: '${v.presetKey}: type ${v.componentType.name} in $expectedTypeDir/');
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
            expect(adjustment.name, isNotEmpty, reason: v.presetKey);
            _assertAdjustmentInvariants(adjustment, v.presetKey);
          }
        }
      });

      test('urls are http(s)', () {
        for (final v in variants) {
          final url = v.url;
          if (url == null) continue;
          final uri = Uri.tryParse(url);
          expect(uri != null && (uri.scheme == 'http' || uri.scheme == 'https'), isTrue,
              reason: '${v.presetKey}: bad url "$url"');
        }
      });

      test('presetKeys are globally unique', () {
        for (final v in variants) {
          final existing = allPresetKeys[v.presetKey];
          expect(existing, isNull,
              reason: 'duplicate presetKey "${v.presetKey}" in $relative and $existing');
          allPresetKeys[v.presetKey] = relative;
        }
      });
    });
  }
}

void _assertAdjustmentInvariants(Adjustment adjustment, String presetKey) {
  switch (adjustment) {
    case StepAdjustment(:final min, :final max, :final step):
      expect(min, lessThan(max), reason: '$presetKey: step "${adjustment.name}" min<max');
      expect(step, greaterThan(0), reason: '$presetKey: step "${adjustment.name}" step>0');
    case NumericalAdjustment(:final min, :final max):
      expect(min, lessThanOrEqualTo(max), reason: '$presetKey: numerical "${adjustment.name}"');
    case CategoricalAdjustment(:final options):
      expect(options, isNotEmpty, reason: '$presetKey: categorical "${adjustment.name}" options');
    case BooleanAdjustment():
      break;
    default:
      fail('$presetKey: unexpected adjustment type ${adjustment.runtimeType} in preset data');
  }
}
