import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/component/component.dart';
import '../models/component/component_catalog.dart';
import '../models/component/component_preset.dart';
import '../utils/component_catalog_parser.dart';
import '../utils/component_preset_resolver.dart';

/// Files are discovered at runtime through the [AssetManifest] (there is no
/// hardcoded brand list), loaded and parsed on first request, then cached for
/// the session.
class ComponentCatalogRepository {
  static const String _baseDir = 'data/component_presets';

  /// Unfiltered — the `draft` filter belongs to the selectable-product getters,
  /// so [resolve] can still read an entry that went back to draft.
  final Map<ComponentType, List<BrandCatalog>> _catalogs = {};
  final Map<ComponentType, List<ResolvedPreset>> _selectable = {};

  ComponentCatalogRepository();

  /// Test seam — the real load path reads YAML through [rootBundle].
  @visibleForTesting
  ComponentCatalogRepository.withCatalogs(List<BrandCatalog> catalogs) {
    for (final type in ComponentType.values) {
      _catalogs[type] = catalogs.where((catalog) => catalog.componentType == type).toList();
    }
  }

  /// Selectable products of a single [type]. Loads and parses that type's
  /// brand files on first call, caches thereafter.
  Future<List<ResolvedPreset>> forType(ComponentType type) async {
    final cached = _selectable[type];
    if (cached != null) return cached;

    final selectable = [
      for (final catalog in await _load(type))
        for (final product in catalogProducts(catalog))
          if (!product.node.draft) product,
    ];
    _selectable[type] = selectable;
    return selectable;
  }

  /// Every selectable product across all types (needed by the cross-type
  /// name-field autocomplete).
  Future<List<ResolvedPreset>> all() async {
    return [
      for (final type in ComponentType.values) ...await forType(type),
    ];
  }

  /// Resolves the catalog entry a saved component points at
  /// (`Component.preset`), as deep as it still matches; null when not even
  /// its brand does.
  ///
  /// Deliberately reads the **unfiltered** catalog, `draft: true` nodes
  /// included: an entry can go back to draft in a later data revision, and a
  /// component saved before that still has to resolve.
  Future<ResolvedPreset?> resolve(ComponentPreset preset) async {
    final type = preset.componentType;
    if (type == null) return null;
    return resolvePreset(await _load(type), preset);
  }

  Future<List<BrandCatalog>> _load(ComponentType type) async {
    final cached = _catalogs[type];
    if (cached != null) return cached;

    final prefix = '$_baseDir/${type.name}/';
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final paths = manifest.listAssets().where((p) => p.endsWith('.yaml') && p.startsWith(prefix)).toList()..sort();

    final catalogs = <BrandCatalog>[];
    for (final path in paths) {
      try {
        catalogs.add(parseCatalogFile(await rootBundle.loadString(path)));
      } catch (error, stack) {
        debugPrint('ComponentCatalogRepository: skipping unparseable "$path": $error');
        debugPrintStack(stackTrace: stack);
      }
    }
    _catalogs[type] = catalogs;
    return catalogs;
  }
}
