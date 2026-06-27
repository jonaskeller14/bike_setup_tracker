import 'dart:io';
import 'package:flutter/material.dart';
import '../services/share_service.dart';

class ImageViewer extends StatefulWidget {
  final List<String> images;
  final String imagesDir;
  final int initialIndex;

  const ImageViewer({
    super.key,
    required this.images,
    required this.imagesDir,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String get _currentFilePath =>
      '${widget.imagesDir}${Platform.pathSeparator}${widget.images[_currentIndex]}';

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
        title: widget.images.length > 1
            ? Text('${_currentIndex + 1} / ${widget.images.length}')
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _share(context),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final file = File(
            '${widget.imagesDir}${Platform.pathSeparator}${widget.images[index]}',
          );
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 6,
            child: Center(
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
          );
        },
      ),
    );
  }
}
