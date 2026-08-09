import 'dart:io';

import 'package:flutter/material.dart';

import '../services/share_service.dart';

class ImageViewer extends StatefulWidget {
  final List<String> images;
  final String imagesDir;
  final int initialIndex;
  final void Function(int index)? onDelete;

  const ImageViewer({
    super.key,
    required this.images,
    required this.imagesDir,
    this.initialIndex = 0,
    this.onDelete,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  late List<String> _images;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _images = List.from(widget.images);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String get _currentFilePath =>
      '${widget.imagesDir}${Platform.pathSeparator}${_images[_currentIndex]}';

  void _delete() {
    final index = _currentIndex;
    widget.onDelete?.call(index);
    if (_images.length == 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _images.removeAt(index);
      if (_currentIndex >= _images.length) {
        _currentIndex = _images.length - 1;
        _pageController.jumpToPage(_currentIndex);
      }
    });
  }

  Future<void> _share(BuildContext context) async {
    final file = File(_currentFilePath);
    if (!file.existsSync()) return;
    await ShareService.shareFile(context: context, filePath: file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: _images.length > 1
            ? Text('${_currentIndex + 1} / ${_images.length}')
            : null,
        actions: [
          if (widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _share(context),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final file = File(
            '${widget.imagesDir}${Platform.pathSeparator}${_images[index]}',
          );
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 6,
            child: Center(
              child: Hero(
                tag: 'setup-image-${_images[index]}',
                child: Image.file(
                  file,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined, size: 64, color: Colors.white54),
                        SizedBox(height: 8),
                        Text('Image not found', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
