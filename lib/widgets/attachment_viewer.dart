import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/attachment.dart';
import '../models/bike.dart';
import '../models/component/component.dart';
import '../models/setup.dart';
import '../pages/details/bike_details_page.dart';
import '../pages/details/component_details_page.dart';
import '../services/file_save_service.dart';
import '../services/share_service.dart';
import 'app_snackbar.dart';
import 'dialogs/rename_attachment.dart';
import 'sheets/setup_details.dart';

enum _AttachmentAction { share, save }

class AttachmentViewer extends StatefulWidget {
  final List<Attachment> attachments;
  final String attachmentsDir;
  final int initialIndex;
  final void Function(int index)? onDelete;
  final void Function(int index, String name)? onRename;
  final AttachmentOwner? Function(Attachment attachment)? ownerForAttachment;
  final FileSaveService? fileSaveService;

  const AttachmentViewer({
    super.key,
    required this.attachments,
    required this.attachmentsDir,
    this.initialIndex = 0,
    this.onDelete,
    this.onRename,
    this.ownerForAttachment,
    this.fileSaveService,
  });

  @override
  State<AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<AttachmentViewer> {
  late PageController _pageController;
  late int _currentIndex;
  late List<Attachment> _attachments;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _attachments = List.from(widget.attachments);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  File _file(Attachment attachment) => File('${widget.attachmentsDir}${Platform.pathSeparator}${attachment.filename}');

  void _delete() {
    final index = _currentIndex;
    widget.onDelete?.call(index);
    if (_attachments.length == 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _attachments.removeAt(index);
      if (_currentIndex >= _attachments.length) {
        _currentIndex = _attachments.length - 1;
        _pageController.jumpToPage(_currentIndex);
      }
    });
  }

  Future<void> _rename() async {
    final index = _currentIndex;
    final name = await showRenameAttachmentDialog(context, name: _attachments[index].name);
    if (name == null || !mounted) return;
    widget.onRename?.call(index, name);
    setState(() => _attachments[index] = _attachments[index].copyWith(name: name));
  }

  Future<void> _share(Attachment attachment) async {
    final file = _file(attachment);
    if (!file.existsSync()) return;
    await ShareService.shareFile(context: context, filePath: file.path, fileName: attachment.exportFileName);
  }

  Future<void> _saveToFiles(Attachment attachment) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await _file(attachment).readAsBytes();
      final outcome = await (widget.fileSaveService ?? FileSaveService()).saveFile(
        fileName: attachment.exportFileName,
        bytes: bytes,
        extension: attachment.extension.replaceFirst('.', ''),
      );
      if (outcome != FileSaveOutcome.saved || !mounted) return;
      messenger.showSnackBar(AppSnackBar.success(context, 'File saved'));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(AppSnackBar.error(context, 'Could not save file: $e'));
    }
  }

  void _showOwner(AttachmentOwner owner) {
    switch (owner.type) {
      case AttachmentOwnerType.setup:
        unawaited(showSetupDetailsSheet(context: context, setupId: owner.id));
      case AttachmentOwnerType.bike:
        unawaited(
          Navigator.push(context, MaterialPageRoute<void>(builder: (_) => BikeDetailsPage(bikeId: owner.id))),
        );
      case AttachmentOwnerType.component:
        unawaited(
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => ComponentDetailsPage(componentId: owner.id)),
          ),
        );
    }
  }

  Widget _ownerButton(AttachmentOwner owner) {
    final (tooltip, icon) = switch (owner.type) {
      AttachmentOwnerType.setup => ('Show Setup', Setup.iconData),
      AttachmentOwnerType.bike => ('Show Bike', Bike.iconData),
      AttachmentOwnerType.component => ('Show Component', Component.iconData),
    };
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: () => _showOwner(owner),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _imagePage(Attachment attachment) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 6,
      child: Center(
        child: Hero(
          tag: 'attachment-${attachment.id}',
          child: Image.file(
            _file(attachment),
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
  }

  Widget _filePage(BuildContext context, Attachment attachment) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final file = _file(attachment);
    final exists = file.existsSync();

    return SafeArea(
      top: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(attachment.iconData, size: 64, color: colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      attachment.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exists ? _formatSize(file.lengthSync()) : 'File not found',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: exists ? colorScheme.onSurfaceVariant : colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: exists ? () => _share(attachment) : null,
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                        OutlinedButton.icon(
                          onPressed: exists ? () => _saveToFiles(attachment) : null,
                          icon: const Icon(Icons.save_alt),
                          label: const Text('Save to Files'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attachment = _attachments[_currentIndex];
    final owner = widget.ownerForAttachment?.call(attachment);
    final exists = _file(attachment).existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(attachment.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (_attachments.length > 1)
              Text(
                '${_currentIndex + 1} / ${_attachments.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
          ],
        ),
        actions: [
          if (owner != null) _ownerButton(owner),
          if (widget.onRename != null)
            IconButton(
              tooltip: 'Rename',
              icon: const Icon(Icons.drive_file_rename_outline),
              onPressed: _rename,
            ),
          if (widget.onDelete != null)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          PopupMenuButton<_AttachmentAction>(
            tooltip: 'Share',
            icon: const Icon(Icons.share),
            enabled: exists,
            onSelected: (action) => switch (action) {
              _AttachmentAction.share => unawaited(_share(attachment)),
              _AttachmentAction.save => unawaited(_saveToFiles(attachment)),
            },
            // The menu inherits the app bar's white icon theme; use the popup's own foreground.
            itemBuilder: (context) {
              final iconColor = Theme.of(context).colorScheme.onSurface;
              return [
                PopupMenuItem(
                  value: _AttachmentAction.share,
                  child: Row(
                    spacing: 10,
                    children: [
                      Icon(Icons.share, color: iconColor),
                      const Text('Share…'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: _AttachmentAction.save,
                  child: Row(
                    spacing: 10,
                    children: [
                      Icon(Icons.save_alt, color: iconColor),
                      const Text('Save to Files'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _attachments.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final attachment = _attachments[index];
          return attachment.isImage ? _imagePage(attachment) : _filePage(context, attachment);
        },
      ),
    );
  }
}
