import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import 'attachment_storage_service.dart';
import 'sync/attachment_sync.dart';

class TrashCleanupService {
  static const Duration retention = Duration(days: 30);

  /// Purges trash older than [retention], then deletes the attachment files no
  /// row references any more: those of the purged rows and any unlinked ones.
  /// The purged rows' files also go from the cloud, which every device does for
  /// itself. Only those: a file no local row references may still belong to a
  /// record another device just added.
  ///
  /// Has to finish before the UI mounts. A form holds picked files that are
  /// not saved yet, and on disk those look unlinked.
  static Future<void> run(AppDatabase database) async {
    try {
      // An empty database does not mean the files are unwanted: a failed legacy
      // migration boots into one, and a later restore still needs its files.
      if (!await database.watchHasUserData().first) return;

      final before = await database.referencedAttachmentFilenames();
      await database.purgeTrash(DateTime.now().toUtc().subtract(retention));
      final referenced = await database.referencedAttachmentFilenames();
      await AttachmentStorageService().deleteUnreferenced(referenced);
      await AttachmentDeleteQueue.add(before.difference(referenced));
    } catch (e, st) {
      debugPrint('Trash cleanup failed: $e\n$st');
    }
  }
}
