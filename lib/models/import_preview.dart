import 'package:flutter/foundation.dart';

import '../services/data_selection_dependencies.dart';
import 'selected_data.dart';
import 'syncable.dart';

enum ImportSourceOptions {
  file,
  backup,
}

enum ImportMethod {
  overwrite,
  merge,
  replace,
}

enum ImportOutcome { added, updated, unchanged, trashed }

@immutable
class ImportPreviewEntry {
  final DataKind kind;
  final String id;

  /// The file's item, or null when the import trashes a local item the file doesn't contain.
  final Syncable? remote;

  /// The item on this device before the import, or null when it isn't here yet.
  final Syncable? local;

  final ImportOutcome outcome;

  const ImportPreviewEntry({
    required this.kind,
    required this.id,
    required this.remote,
    required this.local,
    required this.outcome,
  });
}

/// What an import changes on this device, per item. Items the import has no
/// visible effect on (e.g. trashed in the file and absent here) are not listed.
class ImportPreview {
  final Map<DataKind, List<ImportPreviewEntry>> _entries;

  ImportPreview(Iterable<ImportPreviewEntry> entries)
    : _entries = {
        for (final kind in DataKind.values)
          kind: [
            for (final entry in entries)
              if (entry.kind == kind) entry,
          ],
      };

  /// Compares the device data [before] and [after] the import of [remote].
  /// "Live" means present and not in the trash.
  factory ImportPreview.diff({
    required SelectedData remote,
    required SelectedData before,
    required SelectedData after,
  }) {
    final entries = <ImportPreviewEntry>[];
    for (final kind in DataKind.values) {
      final remoteItems = itemsOf(remote, kind);
      final beforeItems = itemsOf(before, kind);
      final afterItems = itemsOf(after, kind);
      for (final id in {...remoteItems.keys, ...beforeItems.keys}) {
        final local = beforeItems[id];
        final result = afterItems[id];
        final wasLive = local != null && !local.isDeleted;
        final isLive = result != null && !result.isDeleted;
        final outcome = switch ((wasLive, isLive)) {
          (false, true) => ImportOutcome.added,
          (true, false) => ImportOutcome.trashed,
          (true, true) when !local!.hasSameContent(result!) => ImportOutcome.updated,
          (true, true) when remoteItems.containsKey(id) => ImportOutcome.unchanged,
          _ => null,
        };
        if (outcome == null) continue;
        entries.add(ImportPreviewEntry(kind: kind, id: id, remote: remoteItems[id], local: local, outcome: outcome));
      }
    }
    return ImportPreview(entries);
  }

  /// The entries of [kind]: the file's order first, then the local-only items.
  List<ImportPreviewEntry> entriesOf(DataKind kind) => _entries[kind]!;

  int count(DataKind kind, ImportOutcome outcome) => _entries[kind]!.where((e) => e.outcome == outcome).length;

  bool get isEmpty => _entries.values.every((entries) => entries.isEmpty);
}
