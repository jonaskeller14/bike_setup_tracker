import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import 'attachment_storage_service.dart';

class TrashCleanupService {
  static const Duration retention = Duration(days: 30);

  /// Purges trash older than [retention], then deletes the attachment files no
  /// row references any more: those of the purged rows and any unlinked ones.
  ///
  /// Has to finish before the UI mounts. A form holds picked files that are
  /// not saved yet, and on disk those look unlinked.
  static Future<void> run(AppDatabase database) async {
    try {
      // An empty database does not mean the files are unwanted: a failed legacy
      // migration boots into one, and a later restore still needs its files.
      if (!await database.watchHasUserData().first) return;

      await database.purgeTrash(DateTime.now().toUtc().subtract(retention));
      await AttachmentStorageService().deleteUnreferenced(await database.referencedAttachmentFilenames());
    } catch (e, st) {
      debugPrint('Trash cleanup failed: $e\n$st');
    }
  }
}
