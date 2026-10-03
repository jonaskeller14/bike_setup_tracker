import 'dart:io';

import 'package:bike_setup_tracker/models/component/component_catalog.dart';
import 'package:bike_setup_tracker/models/component/preset_spec_keys.dart';
import 'package:bike_setup_tracker/utils/component_catalog_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Guards the ids a saved component persists (`<level>: <id>`, `<axis>: <value>`).
///
/// `data/component_presets/ids.lock` lists every node path (`fork/fox/36/2025`)
/// and every option value (`fork/fox/36/2025/factory#damper=grip_x2`). New ids
/// are fine; one that disappears fails here. Regenerate the lockfile with
/// `UPDATE_CATALOG_IDS=1 flutter test test/component_catalog_ids_test.dart`.
void main() {
  final catalogDir = Directory(p.join(Directory.current.path, 'data', 'component_presets'));
  final lockFile = File(p.join(catalogDir.path, 'ids.lock'));

  final current = _collectIds(catalogDir);

  if (Platform.environment['UPDATE_CATALOG_IDS'] == '1') {
    test('writes ids.lock', () {
      lockFile.writeAsStringSync('${current.join('\n')}\n');
    });
    return;
  }

  test('every id in ids.lock still exists in the catalog', () {
    expect(lockFile.existsSync(), isTrue, reason: 'missing ids.lock — run with UPDATE_CATALOG_IDS=1');
    final locked = lockFile.readAsLinesSync().where((line) => line.isNotEmpty);
    final missing = locked.toSet().difference(current.toSet());
    expect(
      missing,
      isEmpty,
      reason: 'Ids were removed or renamed. Keep the old id (explicit `id:`), or while the feature is '
          'unreleased regenerate with UPDATE_CATALOG_IDS=1.',
    );
  });
}

List<String> _collectIds(Directory catalogDir) {
  final files = catalogDir.listSync(recursive: true).whereType<File>().where((f) => p.extension(f.path) == '.yaml');
  final ids = <String>{};

  for (final file in files) {
    final catalog = parseCatalogFile(file.readAsStringSync());

    void visit(CatalogNode node, String parent) {
      final path = '$parent/${node.id}';
      ids.add(path);
      switch (node) {
        case CatalogGroup(:final children):
          for (final child in children) {
            visit(child, path);
          }
        case CatalogProduct(:final options):
          for (final axis in options.values) {
            for (final value in axis.values) {
              final id = value.id;
              ids.add('$path#${axis.id}=${id is num ? formatSpecNumber(id) : id}');
            }
          }
      }
    }

    for (final node in catalog.nodes) {
      visit(node, '${catalog.componentType.name}/${catalog.id}');
    }
  }
  return ids.toList()..sort();
}
