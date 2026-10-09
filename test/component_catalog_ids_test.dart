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
/// every option value (`fork/fox/36/2025/factory#damper=grip_x2`) and every
/// brand-only task key (`fork/fox#task=fork:air_spring_service`), which rules
/// persist as `presetKey`. New ids are fine; one that disappears fails here. Regenerate the lockfile with
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
    final brandPath = '${catalog.componentType.name}/${catalog.id}';
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
        case CatalogProduct(:final options):
          for (final axis in options.values) {
            for (final value in axis.values) {
              final id = value.id;
              ids.add('$path#${axis.id}=${id is num ? formatSpecNumber(id) : id}');
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
