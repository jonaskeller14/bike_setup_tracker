import 'dart:io';

import 'package:bike_setup_tracker/models/component/component_catalog.dart';
import 'package:bike_setup_tracker/models/component/preset_spec_keys.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:bike_setup_tracker/utils/task_presets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Guards the ids a saved component persists (`<level>: <id>`, `<axis>: <value>`).
///
/// `data/component_presets/ids.lock` lists every node path (`fork/fox/36/2025`),
/// every option value (`fork/fox/36/2025/factory#damper=grip_x2`), every
/// adjuster id (`fork/fox/36/2025/factory#adjuster=pressure`, and
/// `fork/fox#damper=grip_x2#adjuster=hsc` per damper value) that adjustments
/// persist as `presetKey`, and every brand-only task key
/// (`fork/fox#task=fork:air_spring_service`), which rules persist as `presetKey`.
/// New ids are fine; one that disappears fails here unless the brand file's
/// `moved:` map redirects its node path.
///
/// The lockfile is append-only, as saved components hold these ids:
/// `UPDATE_CATALOG_IDS=1 flutter test test/component_catalog_ids_test.dart`
/// adds the new ids, keeps every locked one, and refuses while one is missing.
void main() {
  final catalogDir = Directory(p.join(Directory.current.path, 'data', 'component_presets'));
  final lockFile = File(p.join(catalogDir.path, 'ids.lock'));

  final catalogs = <String, BrandCatalog>{};
  final current = _collectIds(catalogDir, catalogs).toSet();
  final locked = lockFile.existsSync() ? lockFile.readAsLinesSync().where((line) => line.isNotEmpty).toSet() : null;
  const missingReason =
      'Ids were removed or renamed. Restore the old id (explicit `id:`), or redirect a moved node path with `moved:`.';

  if (Platform.environment['UPDATE_CATALOG_IDS'] == '1') {
    test('adds the new ids to ids.lock', () {
      expect(_missing(locked ?? const {}, current, catalogs), isEmpty, reason: missingReason);
      lockFile.writeAsStringSync('${({...?locked, ...current}.toList()..sort()).join('\n')}\n');
    });
    return;
  }

  test('every id in ids.lock still exists in the catalog', () {
    expect(locked, isNotNull, reason: 'missing ids.lock — run with UPDATE_CATALOG_IDS=1');
    expect(_missing(locked!, current, catalogs), isEmpty, reason: missingReason);
  });
}

/// The [locked] ids that neither exist in [current] nor redirect to one that does.
Iterable<String> _missing(Set<String> locked, Set<String> current, Map<String, BrandCatalog> catalogs) =>
    locked.difference(current).where((id) => !current.contains(_redirected(id, catalogs)));

/// [lockedId] with its node path rewritten by the brand's `moved:` map; the
/// id itself when no redirect applies.
String _redirected(String lockedId, Map<String, BrandCatalog> catalogs) {
  final hash = lockedId.indexOf('#');
  final path = (hash < 0 ? lockedId : lockedId.substring(0, hash)).split('/');
  final suffix = hash < 0 ? '' : lockedId.substring(hash);
  final catalog = path.length > 2 ? catalogs['${path[0]}/${path[1]}'] : null;
  final moved = catalog?.redirect(path.sublist(2));
  return moved == null ? lockedId : '${path[0]}/${path[1]}/${moved.join('/')}$suffix';
}

List<String> _collectIds(Directory catalogDir, Map<String, BrandCatalog> catalogs) {
  final files = catalogDir.listSync(recursive: true).whereType<File>().where((f) => p.extension(f.path) == '.yaml');
  final ids = <String>{};

  for (final file in files) {
    final catalog = parseCatalogFile(file.readAsStringSync());
    final brandPath = '${catalog.componentType.name}/${catalog.id}';
    catalogs[brandPath] = catalog;
    final genericTaskKeys = {for (final template in taskPresets[catalog.componentType] ?? const []) template.key};

    void addTaskKeys(Iterable<String> keys) {
      for (final key in keys) {
        if (!genericTaskKeys.contains(key)) ids.add('$brandPath#task=$key');
      }
    }

    void visit(CatalogNode node, String parent) {
      final path = '$parent/${node.id}';
      ids.add(path);
      addTaskKeys(node.tasks.keys);
      switch (node) {
        case CatalogGroup(:final children):
          for (final child in children) {
            visit(child, path);
          }
        case CatalogProduct(:final options, :final adjustments):
          for (final spec in adjustments) {
            ids.add('$path#adjuster=${spec.id}');
          }
          for (final axis in options.values) {
            for (final value in axis.values) {
              final id = value.id;
              final valueId = id is num ? formatSpecNumber(id) : id;
              ids.add('$path#${axis.id}=$valueId');
              for (final spec in value.adjustments) {
                ids.add('$brandPath#${axis.id}=$valueId#adjuster=${spec.id}');
              }
              addTaskKeys([
                for (final MapEntry(:key, value: override) in value.tasks.entries)
                  if (override != null) key,
              ]);
            }
          }
      }
    }

    for (final node in catalog.nodes) {
      visit(node, brandPath);
    }
  }
  return ids.toList()..sort();
}
