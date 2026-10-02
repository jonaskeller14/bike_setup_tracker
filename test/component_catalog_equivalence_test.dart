import 'dart:io';

import 'package:bike_setup_tracker/models/component/component_catalog.dart';
import 'package:bike_setup_tracker/models/component/component_preset.dart';
import 'package:bike_setup_tracker/models/component/preset_spec_keys.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/component_preset_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Safety net for the catalog conversion (#25): the old parser on an old file
/// and the new parser on its converted file have to describe the same
/// products. Temporary — it goes away together with `data/component_presets/`
/// in its old shape.
void main() {
  final oldDir = p.join(Directory.current.path, 'data', 'component_presets');
  final newDir = p.join(Directory.current.path, 'data', 'component_catalog');

  for (final type in ['fork', 'shock']) {
    final oldFiles =
        Directory(
            p.join(oldDir, type),
          ).listSync().whereType<File>().where((f) => p.extension(f.path) == '.yaml').toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final oldFile in oldFiles) {
      final relative = p.join(type, p.basename(oldFile.path));

      test('$relative describes the same products in both schemas', () {
        final newFile = File(p.join(newDir, relative));
        expect(newFile.existsSync(), isTrue, reason: '$relative has not been converted');

        final variants = parseBrandFile(oldFile.readAsStringSync());
        final before = {for (final variant in variants) _variantName(variant): _describeVariant(variant)};
        expect(before, hasLength(variants.length), reason: 'old products are not told apart by name and years');

        final catalog = parseCatalogFile(newFile.readAsStringSync());
        final after = <String, Map<String, Object?>>{};
        for (final (:path, :product) in _products(catalog.nodes, const [])) {
          final name = _productName(path);
          after[_renamed[name] ?? name] = _describeProduct(catalog, product);
        }

        expect(after.keys, unorderedEquals(before.keys));
        for (final MapEntry(key: name, value: description) in before.entries) {
          expect(after[name], description, reason: name);
        }
      });
    }
  }
}

/// Shocks whose path was reshaped, new name → old name. An Öhlins air shock
/// without a version badge got one next to its `m.2`, and a Cane Creek
/// "Standard" trim that covered both mounts became the model node itself.
const _renamed = {
  'TTX1Air First generation Universal (2025-2026)': 'TTX1Air Universal (2025-2026)',
  'TTX2Air First generation Universal (2025-2026)': 'TTX2Air Universal (2025-2026)',
  'Tigon (2025-2026)': 'Tigon Standard (2025-2026)',
  'DB Air IL G1 (null)': 'DB Air IL G1 Standard (null)',
  'DBcoil IL G1 (null)': 'DBcoil IL G1 Standard (null)',
  'DB Kitsuma Air G1 (null)': 'DB Kitsuma Air G1 Standard (null)',
  'DB Kitsuma Coil G1 (null)': 'DB Kitsuma Coil G1 Standard (null)',
};

String _variantName(ComponentPresetVariant variant) => '${variant.model} ${variant.trim} (${variant.yearRange})';

/// A generation only spells out the years, which the old schema kept beside
/// the model name instead of in it.
String _productName(List<CatalogNode> path) {
  final labels = path.where((node) => node.level != 'generation').map((node) => node.label);
  return '${labels.join(' ')} (${path.last.years})';
}

Iterable<({List<CatalogNode> path, CatalogProduct product})> _products(
  List<CatalogNode> nodes,
  List<CatalogNode> parents,
) sync* {
  for (final node in nodes) {
    final path = [...parents, node];
    switch (node) {
      case CatalogGroup(:final children):
        yield* _products(children, path);
      case CatalogProduct():
        yield (path: path, product: node);
    }
  }
}

Map<String, Object?> _describeVariant(ComponentPresetVariant variant) => {
  'brand': variant.brand,
  'componentType': variant.componentType,
  'category': variant.category,
  'url': variant.url,
  'note': variant.note,
  'draft': !variant.complete,
  'spring': variant.springLabel,
  'stanchion': variant.stanchion,
  'adjustments': [for (final spec in variant.adjustmentSpecs) spec.raw],
  'dampers': [
    for (final damper in variant.dampers)
      {
        'id': damper.key,
        'name': damper.name,
        'description': damper.description,
        'adjustments': [for (final spec in damper.adjustmentSpecs) spec.raw],
      },
  ],
  'travel': variant.travelOptions,
  'wheelSizes': variant.wheelSizes,
  // "190x40/42.5/45 (Trunnion)" is three sizes.
  'sizes': variant.strokeOptions.fold<int>(0, (count, strokes) => count + strokes.split(' ').first.split('/').length),
};

Map<String, Object?> _describeProduct(BrandCatalog catalog, CatalogProduct product) => {
  'brand': catalog.brand,
  'componentType': catalog.componentType,
  'category': product.category,
  'url': product.url,
  'note': product.note,
  'draft': product.draft,
  'spring': product.specs.get(PresetSpecKeys.spring),
  'stanchion': product.specs.get(PresetSpecKeys.stanchion),
  'adjustments': [for (final spec in product.adjustments) spec.raw],
  'dampers': [
    for (final value in product.options[PresetOptionAxes.damper.id]?.values ?? const <OptionValue>[])
      {
        'id': value.id,
        'name': value.label,
        'description': value.description,
        'adjustments': [for (final spec in value.adjustments) spec.raw],
      },
  ],
  'travel': _optionIds(product, PresetOptionAxes.travelMm),
  'wheelSizes': _optionIds(product, PresetOptionAxes.wheelSize),
  'sizes': _optionIds(product, PresetOptionAxes.size).length,
};

List<Object> _optionIds(CatalogProduct product, OptionAxisKey axis) => [
  for (final value in product.options[axis.id]?.values ?? const <OptionValue>[]) value.id,
];
