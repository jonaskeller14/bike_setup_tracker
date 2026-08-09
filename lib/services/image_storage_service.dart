import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/selected_data.dart';
import '../services/data_export_service.dart';

class ImageStorageService {
  static const String _imagesDir = 'images';

  Future<String> _imagesPath() async {
    final base = await getApplicationDocumentsDirectory();
    return p.join(base.path, _imagesDir);
  }

  Future<void> ensureDir() async {
    final dir = Directory(await _imagesPath());
    if (!dir.existsSync()) await dir.create(recursive: true);
  }

  Future<String> getImagesPath() => _imagesPath();

  Future<File> resolve(String filename) async {
    return File(p.join(await _imagesPath(), filename));
  }

  File resolveSync(String dirPath, String filename) {
    return File(p.join(dirPath, filename));
  }

  Future<bool> exists(String filename) async {
    final file = await resolve(filename);
    return file.existsSync();
  }

  /// Copy an XFile from the image picker into images/ and return the new filename.
  Future<String> importImage(XFile picked) async {
    await ensureDir();
    final ext = p.extension(picked.path).toLowerCase().isNotEmpty
        ? p.extension(picked.path).toLowerCase()
        : '.jpg';
    final filename = '${const Uuid().v4()}$ext';
    final dest = await resolve(filename);
    await File(picked.path).copy(dest.path);
    return filename;
  }

  /// Duplicate an existing image under a new filename so two objects never share a file.
  Future<String> copyExisting(String filename) async {
    await ensureDir();
    final src = await resolve(filename);
    if (!src.existsSync()) return filename;
    final ext = p.extension(filename);
    final newFilename = '${const Uuid().v4()}$ext';
    final dest = await resolve(newFilename);
    await src.copy(dest.path);
    return newFilename;
  }

  Future<void> deleteImages(Iterable<String> filenames) async {
    for (final filename in filenames) {
      try {
        final file = await resolve(filename);
        if (file.existsSync()) await file.delete();
      } catch (_) {}
    }
  }

  Future<File> exportBundle(AppDatabase database, {SelectedData? selectedData}) async {
    final exportData = await DataExportService.backupDatabaseToJson(database, subset: selectedData);
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    final tempDir = await getTemporaryDirectory();
    final timestamp = _timestamp();
    final zipPath = p.join(tempDir.path, '${timestamp}_bike_setup_bundle.zip');

    final jsonTempFile = File(p.join(tempDir.path, 'data.json'));
    await jsonTempFile.writeAsString(jsonString);

    // When a subset is requested, only include images referenced by those setups.
    final Set<String>? allowedFilenames = selectedData?.setups.values.expand((s) => s.images).toSet();

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    await encoder.addFile(jsonTempFile, 'data.json');

    final imagesDir = Directory(await _imagesPath());
    if (imagesDir.existsSync()) {
      await for (final entity in imagesDir.list()) {
        if (entity is File) {
          final filename = p.basename(entity.path);
          if (allowedFilenames == null || allowedFilenames.contains(filename)) {
            await encoder.addFile(entity, 'images/$filename');
          }
        }
      }
    }

    await encoder.close();
    await jsonTempFile.delete();

    return File(zipPath);
  }

  Future<ImportBundleResult> importBundle() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (picked == null || picked.files.isEmpty) {
      return ImportBundleResult.cancelled();
    }

    try {
      final pickedFile = picked.files.single;
      final Uint8List bytes;
      if (pickedFile.path != null) {
        bytes = await File(pickedFile.path!).readAsBytes();
      } else if (pickedFile.bytes != null) {
        bytes = pickedFile.bytes!;
      } else {
        return ImportBundleResult.failure('Cannot read selected file.');
      }
      final archive = ZipDecoder().decodeBytes(bytes);

      await ensureDir();
      final imagesPath = await _imagesPath();
      String? jsonString;
      int imageCount = 0;

      for (final file in archive) {
        if (!file.isFile) continue;

        if (file.name == 'data.json') {
          jsonString = utf8.decode(file.content as Uint8List);
        } else if (file.name.startsWith('images/')) {
          final filename = p.basename(file.name);
          if (filename.isEmpty) continue;
          final dest = File(p.join(imagesPath, filename));
          await dest.writeAsBytes(file.content as Uint8List);
          imageCount++;
        }
      }

      if (jsonString == null) {
        return ImportBundleResult.failure('No data.json found in bundle.');
      }

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return ImportBundleResult.success(SelectedData.fromJson(jsonData), imageCount);
    } catch (e) {
      return ImportBundleResult.failure('Import failed: $e');
    }
  }

  static String _timestamp() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }
}

class ImportBundleResult {
  final SelectedData? data;
  final String? errorMessage;
  final bool isError;
  final bool isCancelled;
  final int imageCount;

  ImportBundleResult.success(this.data, this.imageCount)
      : errorMessage = null,
        isError = false,
        isCancelled = false;

  ImportBundleResult.failure(this.errorMessage)
      : data = null,
        isError = true,
        isCancelled = false,
        imageCount = 0;

  ImportBundleResult.cancelled()
      : data = null,
        errorMessage = null,
        isError = false,
        isCancelled = true,
        imageCount = 0;
}
