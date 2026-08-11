import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

enum FileSaveOutcome { saved, cancelled }

typedef SaveFilePicker =
    Future<String?> Function({
      String? fileName,
      required FileType type,
      List<String>? allowedExtensions,
      Uint8List? bytes,
    });

class FileSaveService {
  final SaveFilePicker _saveFile;

  FileSaveService([this._saveFile = FilePicker.saveFile]);

  Future<FileSaveOutcome> saveFile({
    required String fileName,
    required List<int> bytes,
    required String extension,
  }) async {
    final path = await _saveFile(
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [extension],
      bytes: Uint8List.fromList(bytes),
    );

    return path == null ? FileSaveOutcome.cancelled : FileSaveOutcome.saved;
  }
}
