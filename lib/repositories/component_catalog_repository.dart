import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/component/component.dart';
import '../models/component/component_catalog.dart';
import '../models/component/component_preset.dart';
import '../models/task/task_template.dart';
import '../utils/component_catalog_parser.dart';
import '../utils/component_preset_resolver.dart';

const List<String> _popularBrandIds = ['fox', 'rockshox'];

/// The one brand order: popular brands first, then alphabetical. The picker,
/// the card teaser and search ties all follow the order [ComponentCatalogRepository]
/// returns its products in.
int _compareBrands(BrandCatalog a, BrandCatalog b) {
  final popularA = _popularBrandIds.indexOf(a.id);
  final popularB = _popularBrandIds.indexOf(b.id);
  if (popularA != popularB) return (popularA == -1 ? 999 : popularA).compareTo(popularB == -1 ? 999 : popularB);
  return a.brand.toLowerCase().compareTo(b.brand.toLowerCase());
}

List<BrandCatalog> _inBrandOrder(Iterable<BrandCatalog> catalogs) => catalogs.toList()..sort(_compareBrands);

/// Files are discovered at runtime through the [AssetManifest] (there is no
/// hardcoded brand list), loaded and parsed on first request, then cached for
/// the session. The text is in the language the repository is asked for, which
/// it follows on every access (see [_setLanguage]); only that language is ever
/// in memory.
class ComponentCatalogRepository {
  static const String _baseDir = 'data/component_presets';

  /// Unfiltered — the `draft` filter belongs to the selectable-product getters,
  /// so [resolve] can still read an entry that went back to draft.
  final Map<ComponentType, List<BrandCatalog>> _catalogs = {};
  final Map<ComponentType, List<ResolvedPreset>> _selectable = {};

  /// Loads still parsing, so concurrent callers share one parse.
  final Map<ComponentType, Future<List<BrandCatalog>>> _loading = {};

  final Future<List<BrandCatalog>> Function(ComponentType type, String languageCode) _read;

  /// The language the app runs in now.
  final String Function() _wantedLanguage;

  String _language = 'en';

  /// The latest switch of [_language], null until the language first changes.
  Future<void>? _switching;

  /// Counts language switches, so a load that started before one is dropped.
  int _generation = 0;

  /// [languageCode] tells the language the app runs in. It is asked on every
  /// access, so a language switch needs no one to tell the repository.
  ComponentCatalogRepository({String Function()? languageCode})
    : _wantedLanguage = languageCode ?? (() => 'en'),
      _read = _readAssets;

  /// Test seam — the real load path reads YAML through [rootBundle].
  @visibleForTesting
  ComponentCatalogRepository.withCatalogs(List<BrandCatalog> catalogs) : _wantedLanguage = (() => 'en'), _read = _readAssets {
    for (final type in ComponentType.values) {
      _catalogs[type] = _inBrandOrder(catalogs.where((catalog) => catalog.componentType == type));
    }
  }

  /// Test seam for the load itself: [read] stands in for the asset bundle, so
  /// a test can count loads or hold one open.
  @visibleForTesting
  ComponentCatalogRepository.withLoader(Future<List<BrandCatalog>> Function(ComponentType type) read)
    : _wantedLanguage = (() => 'en'),
      _read = ((type, _) => read(type));

  /// `withLoader` for a test that follows the language too.
  @visibleForTesting
  ComponentCatalogRepository.withLanguageLoader(
    Future<List<BrandCatalog>> Function(ComponentType type, String languageCode) read, {
    String Function()? languageCode,
  }) : _wantedLanguage = languageCode ?? (() => 'en'),
       _read = read;

  /// The language the catalog text is in.
  String get languageCode => _language;

  /// Starts the switch when the app language is not the one the text is in.
  void _followLanguage() {
    final wanted = _wantedLanguage();
    if (wanted != _language) _switching = _setLanguage(wanted);
  }

  /// Switches the text to [languageCode], re-parsing only the types already
  /// loaded. The new catalogs replace the old ones in one step once all are
  /// parsed, so the cached lookups never come back empty in between. A load
  /// still running for the old language is discarded.
  Future<void> _setLanguage(String languageCode) async {
    if (languageCode == _language) return;
    _language = languageCode;
    final generation = ++_generation;
    _loading.clear();

    final reparsed = <ComponentType, List<BrandCatalog>>{};
    for (final type in _catalogs.keys.toList()) {
      final catalogs = _inBrandOrder(await _read(type, languageCode));
      if (generation != _generation) return;
      reparsed[type] = catalogs;
    }
    _catalogs.addAll(reparsed);
    _selectable.clear();
  }

  /// Selectable products of a single [type]. Loads and parses that type's
  /// brand files on first call, caches thereafter.
  Future<List<ResolvedPreset>> forType(ComponentType type) async {
    _followLanguage();
    await _switching;
    final cached = _selectable[type];
    if (cached != null) return cached;

    final generation = _generation;
    final selectable = [
      for (final catalog in await _load(type))
        for (final product in catalogProducts(catalog))
          if (!product.node.draft) product,
    ];
    if (generation == _generation) _selectable[type] = selectable;
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

  /// The task overrides of [preset]'s catalog entry, from the cache alone:
  /// empty while its type is not loaded yet, so callers stay synchronous and
  /// fall back to the generic templates.
  Map<String, TaskTemplateOverride> loadedTaskOverrides(ComponentPreset preset) =>
      loadedPreset(preset)?.taskOverrides ?? const {};

  /// [resolve] from the cache alone: null while [preset]'s type is not loaded yet.
  ResolvedPreset? loadedPreset(ComponentPreset preset) {
    _followLanguage();
    final catalogs = _catalogs[preset.componentType];
    if (catalogs == null) return null;
    return resolvePreset(catalogs, preset);
  }

  Future<List<BrandCatalog>> _load(ComponentType type) async {
    _followLanguage();
    await _switching;
    final cached = _catalogs[type];
    if (cached != null) return cached;
    return _loading[type] ??= () async {
      final generation = _generation;
      try {
        final catalogs = _inBrandOrder(await _read(type, _language));
        // A switch in the meantime made this the wrong language.
        if (generation != _generation) return await _load(type);
        return _catalogs[type] = catalogs;
      } finally {
        // The removed future is this very load; awaiting it would never return.
        if (generation == _generation) unawaited(_loading.remove(type));
      }
    }();
  }

  static Future<List<BrandCatalog>> _readAssets(ComponentType type, String languageCode) async {
    final prefix = '$_baseDir/${type.name}/';
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final paths = manifest.listAssets().where((p) => p.endsWith('.yaml') && p.startsWith(prefix)).toList()..sort();

    final catalogs = <BrandCatalog>[];
    for (final path in paths) {
      try {
        catalogs.add(parseCatalogFile(await rootBundle.loadString(path), languageCode: languageCode));
      } catch (error, stack) {
        debugPrint('ComponentCatalogRepository: skipping unparseable "$path": $error');
        debugPrintStack(stackTrace: stack);
      }
    }
    return catalogs;
  }
}
