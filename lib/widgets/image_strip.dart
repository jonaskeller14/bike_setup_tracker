import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_storage_service.dart';
import 'image_viewer.dart';
import 'sheets/pick_image_source.dart';

enum ImageStripMode { view, edit }

class ImageStrip extends StatefulWidget {
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

  @override
  State<ImageStrip> createState() => _ImageStripState();
}

class _ImageStripState extends State<ImageStrip> with TickerProviderStateMixin {
  final Map<String, AnimationController> _enterControllers = {};
  final Map<String, AnimationController> _exitControllers = {};

  @override
  void didUpdateWidget(ImageStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSet = oldWidget.images.toSet();
    for (final filename in widget.images) {
      if (!oldSet.contains(filename) && !_enterControllers.containsKey(filename)) {
        final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
        _enterControllers[filename] = ctrl;
        unawaited(ctrl.forward().then((_) {
          if (mounted) setState(() => _enterControllers.remove(filename)?.dispose());
        }));
      }
    }
    // Clean up exit controllers for items removed from widget.images
    final newSet = widget.images.toSet();
    for (final f in _exitControllers.keys.where((f) => !newSet.contains(f)).toList()) {
      _exitControllers.remove(f)?.dispose();
    }
  }

  @override
  void dispose() {
    for (final ctrl in _enterControllers.values) { ctrl.dispose(); }
    for (final ctrl in _exitControllers.values) { ctrl.dispose(); }
    super.dispose();
  }

  void _handleRemove(String filename) {
    if (widget.onRemove == null || _exitControllers.containsKey(filename)) return;
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1.0,
    );
    setState(() => _exitControllers[filename] = ctrl);
    unawaited(ctrl.reverse().then((_) {
      if (!mounted) return;
      final index = widget.images.indexOf(filename);
      if (index != -1) widget.onRemove?.call(index);
    }));
  }

  Widget _animatedItem(String filename, Widget child) {
    final exitCtrl = _exitControllers[filename];
    final enterCtrl = _enterControllers[filename];

    if (exitCtrl != null) {
      final curved = CurvedAnimation(parent: exitCtrl, curve: Curves.easeIn);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.7, end: 1.0).animate(curved),
          child: child,
        ),
      );
    }
    if (enterCtrl != null) {
      final curved = CurvedAnimation(parent: enterCtrl, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.7, end: 1.0).animate(curved),
          child: child,
        ),
      );
    }
    return child;
  }

  void _openViewer(BuildContext context, int index) {
    unawaited(Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewer(
          images: widget.images,
          imagesDir: widget.imagesDir,
          initialIndex: index,
          onDelete: widget.onRemove != null
              ? (deletedIndex) => widget.onRemove?.call(deletedIndex)
              : null,
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
      widget.onAdd?.call([filename]);
    } else {
      final picked = await picker.pickMultiImage();
      if (picked.isEmpty) return;
      final filenames = <String>[];
      for (final x in picked) {
        filenames.add(await service.importImage(x));
      }
      widget.onAdd?.call(filenames);
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
    final file = File('${widget.imagesDir}${Platform.pathSeparator}$filename');
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () => _openViewer(context, index),
          child: Hero(
            tag: 'setup-image-$filename',
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
        ),
        if (widget.mode == ImageStripMode.edit)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _handleRemove(filename),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.inverseSurface,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.all(5),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
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

    if (widget.images.isEmpty && widget.mode == ImageStripMode.view) return const SizedBox.shrink();

    if (widget.mode == ImageStripMode.edit) {
      Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
        final file = File('${widget.imagesDir}${Platform.pathSeparator}${widget.images[index]}');
        return SizedBox(
          width: tileSize,
          height: tileSize,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Material(
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
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.inverseSurface,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.onInverseSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return SizedBox(
        height: tileSize,
        child: ReorderableListView.builder(
          scrollDirection: Axis.horizontal,
          buildDefaultDragHandles: false,
          proxyDecorator: proxyDecorator,
          onReorderStart: (_) => unawaited(HapticFeedback.lightImpact()),
          onReorderItem: (oldIndex, newIndex) {
            widget.onReorder?.call(oldIndex, newIndex);
          },
          itemCount: widget.images.length + (widget.onAdd != null ? 1 : 0),
          itemBuilder: (context, index) {
            if (widget.onAdd != null && index == widget.images.length) {
              return Padding(
                key: const ValueKey('add_button'),
                padding: EdgeInsets.only(left: widget.images.isEmpty ? 0 : spacing),
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
            final filename = widget.images[index];
            return ReorderableDelayedDragStartListener(
              key: ValueKey(filename),
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(right: spacing),
                child: _animatedItem(
                  filename,
                  SizedBox(
                    width: tileSize,
                    height: tileSize,
                    child: _thumbnail(context, filename, index),
                  ),
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
        itemCount: widget.images.length,
        separatorBuilder: (_, _) => const SizedBox(width: spacing),
        itemBuilder: (context, index) {
          final filename = widget.images[index];
          return _animatedItem(
            filename,
            SizedBox(
              width: tileSize,
              height: tileSize,
              child: _thumbnail(context, filename, index),
            ),
          );
        },
      ),
    );
  }
}
