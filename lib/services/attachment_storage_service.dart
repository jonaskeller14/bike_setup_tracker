import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../models/attachment.dart';
import '../models/selected_data.dart';
import 'data_export_service.dart';

class AttachmentTooLargeException implements Exception {
  final String name;

  const AttachmentTooLargeException(this.name);

  @override
  String toString() => 'AttachmentTooLargeException: $name';
}

class AttachmentStorageService {
  static const String _attachmentsDir = 'attachments';
  static const int maxFileBytes = 25 * 1024 * 1024;

  Future<String> _attachmentsPath() async {
    final base = await getApplicationDocumentsDirectory();
    return p.join(base.path, _attachmentsDir);
  }

  Future<void> ensureDir() async {
    final dir = Directory(await _attachmentsPath());
    if (!dir.existsSync()) await dir.create(recursive: true);
  }

  Future<String> getAttachmentsPath() => _attachmentsPath();

  Future<File> resolve(String filename) async {
    if (!Attachment.isPlainFilename(filename)) throw ArgumentError.value(filename, 'filename');
    return File(p.join(await _attachmentsPath(), filename));
  }

  File resolveSync(String dirPath, String filename) {
    return File(p.join(dirPath, filename));
  }

  Future<bool> exists(String filename) async {
    final file = await resolve(filename);
    return file.existsSync();
  }

  static void _checkSize(String name, int bytes) {
    if (bytes > maxFileBytes) throw AttachmentTooLargeException(name);
  }

  /// image_picker names camera shots and all iOS picks after its temp file (`image_picker_<GUID>`,
  /// `<UUID>…`); only Android gallery picks keep their original name.
  static final _generatedPickerName = RegExp(
    r'^image_picker|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
    caseSensitive: false,
  );

  /// Copy an XFile from the image picker into attachments/, named after the picked file
  /// or, when the picker made the name up, after the import time.
  Future<Attachment> importPicked(XFile picked, {DateTime? now}) async {
    _checkSize(picked.name, await picked.length());
    await ensureDir();
    final ext = p.extension(picked.path).isNotEmpty ? p.extension(picked.path) : '.jpg';
    final name = _generatedPickerName.hasMatch(picked.name)
        ? 'Photo ${DateFormat('yyyy-MM-dd HH.mm').format(now ?? DateTime.now())}'
        : picked.name;
    final attachment = Attachment(extension: ext, name: name);
    final dest = await resolve(attachment.filename);
    try {
      await File(picked.path).copy(dest.path);
    } catch (_) {
      await deleteFiles([attachment.filename]);
      rethrow;
    }
    return attachment;
  }

  /// Copy a file of any type from the file picker into attachments/, named after the picked file.
  Future<Attachment> importFile(PlatformFile picked) async {
    _checkSize(picked.name, await picked.length());
    await ensureDir();
    final attachment = Attachment(extension: p.extension(picked.name), name: picked.name);
    final dest = await resolve(attachment.filename);
    // Streamed rather than copied by path: Android may hand out a content URI instead of a file path.
    try {
      // Written through a handle that is closed before the cleanup below: an IOSink only
      // closes its file in the background after an error, which blocks the delete on Windows.
      final file = await dest.open(mode: FileMode.write);
      try {
        await for (final chunk in picked.readAsByteStream()) {
          await file.writeFrom(chunk);
        }
      } finally {
        await file.close();
      }
    } catch (_) {
      await deleteFiles([attachment.filename]);
      rethrow;
    }
    return attachment;
  }

  /// Duplicate an existing attachment under a new id so two objects never share a file.
  Future<Attachment> copyExisting(Attachment attachment) async {
    await ensureDir();
    final src = await resolve(attachment.filename);
    if (!src.existsSync()) return attachment;
    final copy = Attachment(extension: attachment.extension, name: attachment.name);
    final dest = await resolve(copy.filename);
    await src.copy(dest.path);
    return copy;
  }

  /// Takes filenames rather than [Attachment]s: unlinked files in the folder
  /// have no attachment left that describes them.
  Future<void> deleteFiles(Iterable<String> filenames) async {
    for (final filename in filenames) {
      try {
        final file = await resolve(filename);
        if (file.existsSync()) await file.delete();
      } catch (_) {}
    }
  }

  /// Deletes every file in attachments/ whose name is not in [referenced].
  Future<void> deleteUnreferenced(Set<String> referenced) async {
    final dir = Directory(await _attachmentsPath());
    if (!dir.existsSync()) return;
    final filenames = [
      for (final entity in await dir.list().toList())
        if (entity is File) p.basename(entity.path),
    ];
    await deleteFiles(filenames.where((filename) => !referenced.contains(filename)));
  }

  Future<void> deleteAll() async {
    final dir = Directory(await _attachmentsPath());
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  Future<File> exportBundle(AppDatabase database, {SelectedData? selectedData}) async {
    final exportData = await DataExportService.backupDatabaseToJson(database, subset: selectedData);
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    // When a subset is requested, only include attachments referenced by its setups, bikes, components and tasks.
    final Set<String>? allowedFilenames = selectedData == null ? null : _attachmentFilenames(selectedData);

    return _writeBundle(jsonString, 'bike_setup_bundle', allowedFilenames: allowedFilenames);
  }

  /// Bundles an on-disk backup with every attachment without touching the database,
  /// so it still works when the database failed to load.
  Future<File> exportRecoveryBundle(File backupJson) async {
    return _writeBundle(await backupJson.readAsString(), 'recovered_bundle');
  }

  Future<File> _writeBundle(String jsonString, String nameSuffix, {Set<String>? allowedFilenames}) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = _timestamp();
    final zipPath = p.join(tempDir.path, '${timestamp}_$nameSuffix.zip');

    final jsonTempFile = File(p.join(tempDir.path, 'data.json'));
    await jsonTempFile.writeAsString(jsonString);

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    await encoder.addFile(jsonTempFile, 'data.json');

    final attachmentsDir = Directory(await _attachmentsPath());
    if (attachmentsDir.existsSync()) {
      await for (final entity in attachmentsDir.list()) {
        if (entity is File) {
          final filename = p.basename(entity.path);
          if (allowedFilenames == null || allowedFilenames.contains(filename)) {
            await encoder.addFile(entity, '$_attachmentsDir/$filename');
          }
        }
      }
    }

    await encoder.close();
    await jsonTempFile.delete();

    return File(zipPath);
  }

  static Set<String> _attachmentFilenames(SelectedData data) {
    return {
      ...data.setups.values.expand((s) => s.attachments),
      ...data.bikes.values.expand((b) => b.attachments),
      ...data.components.values.expand((c) => c.attachments),
      ...data.taskRules.values.expand((tr) => tr.attachments),
      ...data.taskEntries.values.expand((te) => te.attachments),
    }.map((a) => a.filename).toSet();
  }

  Future<ImportBundleResult> importBundle() async {
    final pickedFile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (pickedFile == null) {
      return ImportBundleResult.cancelled();
    }

    try {
      final bytes = await pickedFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      await ensureDir();
      final attachmentsPath = await _attachmentsPath();
      String? jsonString;
      int attachmentCount = 0;

      for (final file in archive) {
        if (!file.isFile) continue;

        if (file.name == 'data.json') {
          jsonString = utf8.decode(file.content as Uint8List);
        } else if (file.name.startsWith('$_attachmentsDir/')) {
          final filename = p.basename(file.name);
          if (filename.isEmpty) continue;
          final dest = File(p.join(attachmentsPath, filename));
          await dest.writeAsBytes(file.content as Uint8List);
          attachmentCount++;
        }
      }

      if (jsonString == null) {
        return ImportBundleResult.failure('No data.json found in bundle.');
      }

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return ImportBundleResult.success(SelectedData.fromJson(jsonData), attachmentCount);
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
  final int attachmentCount;

  ImportBundleResult.success(this.data, this.attachmentCount)
      : errorMessage = null,
        isError = false,
        isCancelled = false;

  ImportBundleResult.failure(this.errorMessage)
      : data = null,
        isError = true,
        isCancelled = false,
        attachmentCount = 0;

  ImportBundleResult.cancelled()
      : data = null,
        errorMessage = null,
        isError = false,
        isCancelled = true,
        attachmentCount = 0;
}
