import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/component.dart';
import '../models/component_preset.dart';
import '../utils/component_preset_parser.dart';

/// Files are discovered at runtime through the [AssetManifest] (there is no
/// hardcoded brand list), loaded and parsed on first request, then cached for
/// the session.
class ComponentPresetRepository {
  static const String _baseDir = 'data/component_presets';

  final Map<ComponentType, List<ComponentPresetVariant>> _byType = {};
  List<ComponentPresetVariant>? _all;
  List<ComponentPresetVariant>? _allRaw;
  Map<String, ComponentPresetVariant>? _byKey;

  ComponentPresetRepository();

  /// Test seam for [byKey] and [all] — the real load path reads YAML through
  /// [rootBundle], which a unit test has no way to provide.
  @visibleForTesting
  ComponentPresetRepository.withVariants(List<ComponentPresetVariant> variants) {
    _allRaw = variants;
  }

  /// Variants for a single [type]. Loads and parses that type's brand files on
  /// first call, caches thereafter.
  Future<List<ComponentPresetVariant>> forType(ComponentType type) async {
    final cached = _byType[type];
    if (cached != null) return cached;

    final prefix = '$_baseDir/${type.name}/';
    final variants = await _loadMatching((path) => path.startsWith(prefix));
    final selectable = variants.where((v) => v.complete).toList();
    _byType[type] = selectable;
    return selectable;
  }

  /// Every variant across all types (needed by the cross-type name-field
  /// autocomplete). Same session cache; also populates the per-type cache.
  Future<List<ComponentPresetVariant>> all() async {
    final cached = _all;
    if (cached != null) return cached;

    final selectable = (await _loadAll()).where((v) => v.complete).toList();
    _all = selectable;
    for (final type in selectable.map((v) => v.componentType).toSet()) {
      _byType[type] = selectable.where((v) => v.componentType == type).toList();
    }
    return selectable;
  }

  /// Resolves the catalog entry a saved component points at
  /// (`Component.presetKey`); null once a key is retired from the data.
  ///
  /// Deliberately searches the **unfiltered** catalog, `complete: false`
  /// entries included: a trim can go incomplete in a later data revision, and a
  /// component saved while it was complete still has to resolve.
  Future<ComponentPresetVariant?> byKey(String key) async {
    final index = _byKey ??= {for (final v in await _loadAll()) v.key: v};
    return index[key];
  }

  Future<List<ComponentPresetVariant>> _loadAll() async {
    final cached = _allRaw;
    if (cached != null) return cached;

    final variants = await _loadMatching((path) => path.startsWith('$_baseDir/'));
    _allRaw = variants;
    return variants;
  }

  Future<List<ComponentPresetVariant>> _loadMatching(bool Function(String path) matches) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final paths = manifest
        .listAssets()
        .where((p) => p.endsWith('.yaml') && matches(p))
        .toList()
      ..sort();

    final variants = <ComponentPresetVariant>[];
    for (final path in paths) {
      try {
        final source = await rootBundle.loadString(path);
        // Unfiltered — the `complete` filter belongs to the selectable-variant
        // getters, so [byKey] can still resolve an entry that went incomplete.
        variants.addAll(parseBrandFile(source));
      } catch (error, stack) {
        debugPrint('ComponentPresetRepository: skipping unparseable "$path": $error');
        debugPrintStack(stackTrace: stack);
      }
    }
    return variants;
  }
}
