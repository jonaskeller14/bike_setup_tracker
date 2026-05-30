import 'dart:async';
import '../database/app_database.dart';
import '../utils/file_export.dart';

class BackupService {
  Timer? _debounce;

  void update(AppDatabase database) {
    // If a new change comes in, cancel the previous pending save
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Only save if no changes have happened for 1 second
    _debounce = Timer(const Duration(seconds: 1), () async {
      await FileExport.saveBackup(database: database);
    });
  }
}
