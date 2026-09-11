import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../repositories/app_repository.dart';
import '../../services/image_storage_service.dart';
import '../../widgets/empty_state_placeholder.dart';
import '../../widgets/image_viewer.dart';

typedef _GalleryEntry = ({String filename, String? setupId});
typedef _ImageFolder = ({String dir, List<String> filenames});

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late final Future<_ImageFolder> _folder = _loadFolder();

  /// Reads the folder itself rather than the setups' image lists, so files that
  /// no setup references any more still surface here — nothing sweeps them
  /// except an import or sync, so they can pile up unnoticed.
  Future<_ImageFolder> _loadFolder() async {
    final dir = await ImageStorageService().getImagesPath();
    final directory = Directory(dir);
    if (!directory.existsSync()) return (dir: dir, filenames: const <String>[]);

    final files = (await directory.list().toList()).whereType<File>().toList();
    final modified = {for (final file in files) file.path: file.statSync().modified};
    files.sort((a, b) => modified[b.path]!.compareTo(modified[a.path]!));
    return (dir: dir, filenames: [for (final file in files) p.basename(file.path)]);
  }

  /// Setups newest first with their images in setup order, then unlinked files.
  List<_GalleryEntry> _entries(AppRepository repository, List<String> filenames) {
    final setups = repository.setups.values.toList()..sort((a, b) => b.datetime.compareTo(a.datetime));

    final entries = <_GalleryEntry>[];
    final linked = <String>{};
    for (final setup in setups) {
      for (final filename in setup.images) {
        if (linked.add(filename)) entries.add((filename: filename, setupId: setup.id));
      }
    }

    // A trashed setup still owns its images, so they are neither listed nor
    // counted as unlinked until that setup is purged for good.
    final trashed = repository.deletedSetups.expand((s) => s.images).toSet();
    for (final filename in filenames) {
      if (linked.contains(filename) || trashed.contains(filename)) continue;
      entries.add((filename: filename, setupId: null));
    }
    return entries;
  }

  void _openViewer(List<_GalleryEntry> entries, String imagesDir, int index) {
    final setupIdsByImage = {for (final entry in entries) entry.filename: entry.setupId};
    unawaited(
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => ImageViewer(
            images: [for (final entry in entries) entry.filename],
            imagesDir: imagesDir,
            initialIndex: index,
            setupIdForImage: (filename) => setupIdsByImage[filename],
          ),
        ),
      ),
    );
  }

  Widget _unlinkedHint(BuildContext context, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.error_outline, color: colorScheme.error),
      title: Text(
        count == 1
            ? '1 image is no longer linked to a setup. It stays on this device until you import or sync a backup.'
            : '$count images are no longer linked to a setup. They stay on this device until you import or sync a backup.',
        style: TextStyle(color: colorScheme.error),
      ),
      dense: true,
    );
  }

  Widget _tile(BuildContext context, _GalleryEntry entry, String imagesDir, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUnlinked = entry.setupId == null;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'setup-image-${entry.filename}',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: isUnlinked ? Border.all(color: colorScheme.error, width: 1.5) : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.file(
                File(p.join(imagesDir, entry.filename)),
                fit: BoxFit.cover,
                cacheWidth: 400,
                errorBuilder: (_, _, _) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(child: Icon(Icons.broken_image_outlined, size: 32)),
                ),
              ),
            ),
          ),
          if (isUnlinked)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.all(5),
                child: Icon(Icons.error_outline, size: 14, color: colorScheme.onError),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: SafeArea(
        child: FutureBuilder<_ImageFolder>(
          future: _folder,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const EmptyStatePlaceholder(
                icon: Icons.broken_image_outlined,
                title: 'Images unavailable',
                subtitle: 'The image folder could not be opened.',
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final folder = snapshot.data!;
            final entries = _entries(appRepository, folder.filenames);
            if (entries.isEmpty) {
              return const EmptyStatePlaceholder(
                icon: Icons.photo_library_outlined,
                title: 'No images yet',
                subtitle: 'Images you add to a setup appear here.',
              );
            }

            final unlinkedCount = entries.where((e) => e.setupId == null).length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (unlinkedCount > 0) _unlinkedHint(context, unlinkedCount),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 140,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (context, index) => _tile(
                      context,
                      entries[index],
                      folder.dir,
                      () => _openViewer(entries, folder.dir, index),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
