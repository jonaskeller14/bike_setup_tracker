import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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
}
