import 'dart:async';
import '../models/app_data.dart';
import '../utils/file_export.dart';

class StorageService {
  Timer? _debounce;

  void update(AppData data) {
    // If a new change comes in, cancel the previous pending save
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Only save if no changes have happened for 1 second
    _debounce = Timer(const Duration(seconds: 1), () async {
      await FileExport.saveData(data: data);
      await FileExport.saveBackup(data: data);
    });
  }
}
