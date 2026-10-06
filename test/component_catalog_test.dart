import 'dart:io';

import 'package:bike_setup_tracker/models/adjustment/adjustment.dart';
import 'package:bike_setup_tracker/models/component/component_catalog.dart';
import 'package:bike_setup_tracker/models/component/preset_spec_keys.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// CI correctness gate for the generic component catalog (`data/component_presets/`).
///
/// Enumerates every brand YAML file, parses it with the same [parseCatalogFile]
/// the app uses, then **instantiates every adjustment spec** via the strict
/// [Adjustment.fromYaml]. The parser rejects unregistered spec keys and option
/// axes and `fromYaml` rejects unknown adjustment keys, so this test doubles as
/// a typo detector: a data edit that breaks the schema fails CI here rather
/// than in the app.
void main() {
  final catalogDir = Directory(p.join(Directory.current.path, 'data', 'component_presets'));

  final yamlFiles =
      catalogDir.listSync(recursive: true).whereType<File>().where((f) => p.extension(f.path) == '.yaml').toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('catalog directory contains brand files', () {
    expect(catalogDir.existsSync(), isTrue, reason: 'missing ${catalogDir.path}');
    expect(yamlFiles, isNotEmpty, reason: 'no brand YAML files found');
  });

  // Collected across all files for the global uniqueness check.
  final allProductPaths = <String, String>{}; // product path -> file

  for (final file in yamlFiles) {
    final relative = p.relative(file.path, from: catalogDir.path);
    // Directory name (fork/shock) the file lives in — must match component_type.
    final expectedTypeDir = p.split(relative).first;

    group(relative, () {
      late BrandCatalog catalog;
      late Map<String, CatalogNode> nodes; // id path -> node

      setUpAll(() {
        catalog = parseCatalogFile(file.readAsStringSync());
        nodes = _nodesByPath(catalog);
      });

      test('parses to at least one product', () {
        expect(nodes.values.whereType<CatalogProduct>(), isNotEmpty);
      });

      test('component_type matches directory', () {
        expect(catalog.componentType.name, expectedTypeDir);
      });

      test('every adjustment spec builds into a valid Adjustment', () {
        for (final MapEntry(key: path, value: node) in nodes.entries) {
          if (node is! CatalogProduct) continue;
          for (final spec in _adjustmentSpecs(node)) {
            final adjustment = spec.build(); // strict fromYaml — throws on typos
            expect(adjustment.name, isNotEmpty, reason: path);
            _assertAdjustmentInvariants(adjustment, path);
          }
        }
      });

      test('clicks are step adjustments', () {
        // A click count is discrete; a numerical field would accept 12.5 clicks
        // and show no dial.
        for (final MapEntry(key: path, value: node) in nodes.entries) {
          if (node is! CatalogProduct) continue;
          for (final spec in _adjustmentSpecs(node)) {
            expect(
              spec.raw['type'] != 'numerical' || spec.raw['unit'] != 'clicks',
              isTrue,
              reason: '$path: "${spec.raw['name']}" counts clicks, so it is a step adjustment',
            );
          }
        }
      });

      test('rider-facing text carries no research notes', () {
        // Node notes, value descriptions and adjustment notes reach the rider;
        // sourcing belongs in `source:` / `note:` keys and comments, and a
        // missing adjuster in `missing_adjustments`.
        final texts = <String, String?>{
          for (final MapEntry(key: path, value: node) in nodes.entries) ...{
            '$path note': node.note,
            if (node is CatalogProduct) ...{
              for (final spec in _adjustmentSpecs(node)) '$path ${spec.raw['name']} notes': spec.raw['notes'] as String?,
              for (final axis in node.options.values)
                for (final value in axis.values) '${axis.id} ${value.id} description': value.description,
            },
          },
        };
        for (final MapEntry(key: where, value: text) in texts.entries) {
          final match = text == null ? null : _researchNote.firstMatch(text);
          expect(match, isNull, reason: '$where: "${match?[0]}" in "$text"');
        }
      });

      test('non-draft products have no damper with an empty adjustment list', () {
        // An empty list means the adjusters themselves are unknown. It also
        // makes the axis optional, so the check cannot rely on `required`.
        for (final MapEntry(key: path, value: node) in nodes.entries) {
          if (node is! CatalogProduct || node.draft) continue;
          for (final damper in node.options[PresetOptionAxes.damper.id]?.values ?? const <OptionValue>[]) {
            expect(damper.adjustments, isNotEmpty, reason: '$path: damper "${damper.id}" has no adjustments');
          }
        }
      });

      test('every size has a stroke in mm', () {
        for (final MapEntry(key: path, value: node) in nodes.entries) {
          if (node is! CatalogProduct) continue;
          for (final size in node.options[PresetOptionAxes.size.id]?.values ?? const <OptionValue>[]) {
            final stroke = size.specs.get(PresetSpecKeys.strokeMm);
            final eyeToEye = size.specs.get(PresetSpecKeys.eyeToEyeMm);
            expect(stroke, isNotNull, reason: '$path: size "${size.id}" has no stroke_mm');
            // An inch figure that was not converted reads as a tiny mm value.
            expect(stroke, greaterThan(20), reason: '$path: size "${size.id}" is not in mm');
            if (eyeToEye != null) {
              expect(eyeToEye, greaterThan(stroke!), reason: '$path: size "${size.id}" eye-to-eye > stroke');
            }
          }
        }
      });

      test('urls are http(s)', () {
        for (final MapEntry(key: path, value: node) in nodes.entries) {
          for (final url in [node.url, node.setupGuide].nonNulls) {
            final uri = Uri.tryParse(url);
            expect(
              uri != null && (uri.scheme == 'http' || uri.scheme == 'https'),
              isTrue,
              reason: '$path: bad url "$url"',
            );
          }
        }
      });

      test('product paths are globally unique', () {
        // The path is what a component persists, so two brand files must not
        // both claim it.
        for (final MapEntry(key: path, value: node) in nodes.entries) {
          if (node is! CatalogProduct) continue;
          final existing = allProductPaths[path];
          expect(existing, isNull, reason: 'duplicate product "$path" in $relative and $existing');
          allProductPaths[path] = relative;
        }
      });
    });
  }
}

/// Every node of [catalog], keyed by the ids on its path:
/// `fork/fox/36/2025/factory`.
Map<String, CatalogNode> _nodesByPath(BrandCatalog catalog) {
  final nodes = <String, CatalogNode>{};
  void visit(CatalogNode node, String parent) {
    final path = '$parent/${node.id}';
    nodes[path] = node;
    if (node is CatalogGroup) {
      for (final child in node.children) {
        visit(child, path);
      }
    }
  }

  for (final node in catalog.nodes) {
    visit(node, '${catalog.componentType.name}/${catalog.id}');
  }
  return nodes;
}

/// The product's own adjustments plus those of every option value it offers.
List<PresetAdjustmentSpec> _adjustmentSpecs(CatalogProduct product) => [
  ...product.adjustments,
  for (final axis in product.options.values)
    for (final value in axis.values) ...value.adjustments,
];

/// Wording that belongs to the data editor, not the rider: links, citations,
/// verification status, and "please add it yourself" prose.
final RegExp _researchNote = RegExp(
  r'https?://|\bsource[sd]?\b|\breview(ed|s)?\b|pinkbike|vital ?mtb|bikeradar|enduro-mtb|\bconfirm|'
  r'\bverif|follow-?up|not (yet )?published|\bper (the )?(manual|review|article|tuning guide|product page)\b|'
  r'see damper|product page|adjustments incomplete|yourself',
  caseSensitive: false,
);

void _assertAdjustmentInvariants(Adjustment adjustment, String path) {
  switch (adjustment) {
    case StepAdjustment(:final min, :final max, :final step):
      expect(min, lessThan(max), reason: '$path: step "${adjustment.name}" min<max');
      expect(step, greaterThan(0), reason: '$path: step "${adjustment.name}" step>0');
    case NumericalAdjustment(:final min, :final max):
      expect(min, lessThanOrEqualTo(max), reason: '$path: numerical "${adjustment.name}"');
    case CategoricalAdjustment(:final options):
      expect(options, isNotEmpty, reason: '$path: categorical "${adjustment.name}" options');
    case BooleanAdjustment():
      break;
    default:
      fail('$path: unexpected adjustment type ${adjustment.runtimeType} in catalog data');
  }
}
