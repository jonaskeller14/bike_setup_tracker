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

  /// Variants for a single [type]. Loads and parses that type's brand files on
  /// first call, caches thereafter.
  Future<List<ComponentPresetVariant>> forType(ComponentType type) async {
    final cached = _byType[type];
    if (cached != null) return cached;

    final prefix = '$_baseDir/${type.name}/';
    final variants = await _loadMatching((path) => path.startsWith(prefix));
    _byType[type] = variants;
    return variants;
  }

  /// Every variant across all types (needed by the cross-type name-field
  /// autocomplete). Same session cache; also populates the per-type cache.
  Future<List<ComponentPresetVariant>> all() async {
    final cached = _all;
    if (cached != null) return cached;

    final variants = await _loadMatching((path) => path.startsWith('$_baseDir/'));
    _all = variants;
    for (final type in variants.map((v) => v.componentType).toSet()) {
      _byType[type] = variants.where((v) => v.componentType == type).toList();
    }
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
        variants.addAll(
          parseBrandFile(source).where((v) => v.complete),
        );
      } catch (error, stack) {
        debugPrint('ComponentPresetRepository: skipping unparseable "$path": $error');
        debugPrintStack(stackTrace: stack);
      }
    }
    return variants;
  }
}
