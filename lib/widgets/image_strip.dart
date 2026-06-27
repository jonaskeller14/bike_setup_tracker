import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_storage_service.dart';
import 'image_viewer.dart';
import 'sheets/pick_image_source.dart';

enum ImageStripMode { view, edit }

class ImageStrip extends StatelessWidget {
  final List<String> images;
  final String imagesDir;
  final ImageStripMode mode;
  final void Function(int index)? onRemove;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final void Function(List<String> newFilenames)? onAdd;

  const ImageStrip({
    super.key,
    required this.images,
    required this.imagesDir,
    this.mode = ImageStripMode.view,
    this.onRemove,
    this.onReorder,
    this.onAdd,
  });

  void _openViewer(BuildContext context, int index) {
    unawaited(Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewer(
          images: images,
          imagesDir: imagesDir,
          initialIndex: index,
        ),
      ),
    ));
  }

  Future<void> _pickImages(BuildContext context) async {
    final picker = ImagePicker();
    final source = await showPickImageSourceSheet(context);
    if (source == null) return;

    final service = ImageStorageService();
    if (source == ImageSource.camera) {
      final picked = await picker.pickImage(source: ImageSource.camera);
      if (picked == null) return;
      final filename = await service.importImage(picked);
      onAdd?.call([filename]);
    } else {
      final picked = await picker.pickMultiImage();
      if (picked.isEmpty) return;
      final filenames = <String>[];
      for (final x in picked) {
        filenames.add(await service.importImage(x));
      }
      onAdd?.call(filenames);
    }
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, size: 32),
      ),
    );
  }

  Widget _thumbnail(BuildContext context, String filename, int index) {
    final file = File('$imagesDir${Platform.pathSeparator}$filename');
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () => _openViewer(context, index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              file,
              fit: BoxFit.cover,
              cacheWidth: 300,
              errorBuilder: (_, _, _) => _placeholder(context),
            ),
          ),
        ),
        if (mode == ImageStripMode.edit)
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => onRemove?.call(index),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const double tileSize = 80;
    const double spacing = 8;

    if (images.isEmpty && mode == ImageStripMode.view) return const SizedBox.shrink();

    if (mode == ImageStripMode.edit) {
      Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
        // Rebuild the thumbnail without the item's right-side spacing so the drag
        // ghost is a clean square with rounded corners and a subtle elevation.
        final file = File('$imagesDir${Platform.pathSeparator}${images[index]}');
        return SizedBox(
          width: tileSize,
          height: tileSize,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: Image.file(
              file,
              fit: BoxFit.cover,
              cacheWidth: 300,
              errorBuilder: (_, _, _) => _placeholder(context),
            ),
          ),
        );
      }

      return SizedBox(
        height: tileSize,
        child: ReorderableListView.builder(
          scrollDirection: Axis.horizontal,
          buildDefaultDragHandles: false,
          proxyDecorator: proxyDecorator,
          onReorderItem: (oldIndex, newIndex) {
            onReorder?.call(oldIndex, newIndex);
          },
          itemCount: images.length + (onAdd != null ? 1 : 0),
          itemBuilder: (context, index) {
            if (onAdd != null && index == images.length) {
              return Padding(
                key: const ValueKey('add_button'),
                padding: EdgeInsets.only(left: images.isEmpty ? 0 : spacing),
                child: GestureDetector(
                  onTap: () => _pickImages(context),
                  child: Container(
                    width: tileSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                        Text(
                          'Add',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return ReorderableDelayedDragStartListener(
              key: ValueKey(images[index]),
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(right: spacing),
                child: SizedBox(
                  width: tileSize,
                  height: tileSize,
                  child: _thumbnail(context, images[index], index),
                ),
              ),
            );
          },
        ),
      );
    }

    // view mode
    return SizedBox(
      height: tileSize,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: spacing),
        itemBuilder: (context, index) {
          return SizedBox(
            width: tileSize,
            height: tileSize,
            child: _thumbnail(context, images[index], index),
          );
        },
      ),
    );
  }
}
