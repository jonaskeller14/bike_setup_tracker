import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../models/attachment.dart';
import '../../repositories/app_repository.dart';
import '../../services/attachment_storage_service.dart';
import '../../utils/attachment_actions.dart';
import '../../utils/attachment_index.dart';
import '../../widgets/animated_app_bar_switcher.dart';
import '../../widgets/attachment_strip.dart';
import '../../widgets/attachment_viewer.dart';
import '../../widgets/empty_state_placeholder.dart';

typedef _AttachmentFolder = ({String dir, List<String> filenames});

class AttachmentsPage extends StatefulWidget {
  const AttachmentsPage({super.key});

  @override
  State<AttachmentsPage> createState() => _AttachmentsPageState();
}

class _AttachmentsPageState extends State<AttachmentsPage> {
  late Future<_AttachmentFolder> _folder = _loadFolder();
  final Set<String> _selectedAttachments = {};
  bool _isDeleting = false;

  bool get _isSelectionMode => _selectedAttachments.isNotEmpty;

  void _clearSelection() {
    setState(() => _selectedAttachments.clear());
  }

  void _toggleSelection(String filename) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      if (!_selectedAttachments.remove(filename)) _selectedAttachments.add(filename);
    });
  }

  Future<void> _deleteSelectedAttachments() async {
    if (_isDeleting) return;

    setState(() => _isDeleting = true);
    try {
      final deleted = await AttachmentActions.deleteAttachments(
        context,
        filenames: Set<String>.of(_selectedAttachments),
      );
      if (!mounted || !deleted) return;
      setState(() {
        _selectedAttachments.clear();
        _folder = _loadFolder();
      });
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  /// Reads the folder itself rather than the owners' attachment lists, so files
  /// that no setup, bike or component references any more still surface here —
  /// nothing sweeps them except an import or sync, so they can pile up unnoticed.
  Future<_AttachmentFolder> _loadFolder() async {
    final dir = await AttachmentStorageService().getAttachmentsPath();
    final directory = Directory(dir);
    if (!directory.existsSync()) return (dir: dir, filenames: const <String>[]);

    final files = (await directory.list().toList()).whereType<File>().toList();
    final modified = {for (final file in files) file.path: file.statSync().modified};
    files.sort((a, b) => modified[b.path]!.compareTo(modified[a.path]!));
    return (dir: dir, filenames: [for (final file in files) p.basename(file.path)]);
  }

  List<AttachmentIndexEntry> _entries(AppRepository repository, List<String> filenames) {
    return attachmentIndex(
      setups: repository.setups.values,
      bikes: repository.bikes.values,
      components: repository.components.values,
      trashedAttachments: [
        ...repository.deletedSetups.expand((s) => s.attachments),
        ...repository.deletedBikes.expand((b) => b.attachments),
        ...repository.deletedComponents.expand((c) => c.attachments),
      ],
      filenames: filenames,
    );
  }

  void _openViewer(List<AttachmentIndexEntry> entries, String attachmentsDir, int index) {
    final ownersByAttachment = {for (final entry in entries) entry.attachment.filename: entry.owner};
    unawaited(
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => AttachmentViewer(
            attachments: [for (final entry in entries) entry.attachment],
            attachmentsDir: attachmentsDir,
            initialIndex: index,
            ownerForAttachment: (attachment) => ownersByAttachment[attachment.filename],
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
            ? '1 attachment is no longer linked to a setup, bike or component. It stays on this device until you import or sync a backup.'
            : '$count attachments are no longer linked to a setup, bike or component. They stay on this device until you import or sync a backup.',
        style: TextStyle(color: colorScheme.error),
      ),
      dense: true,
    );
  }

  Widget _tileContent(BuildContext context, Attachment attachment, String attachmentsDir) {
    if (!attachment.isImage) return AttachmentFileTile(attachment: attachment);
    return Image.file(
      File(p.join(attachmentsDir, attachment.filename)),
      fit: BoxFit.cover,
      cacheWidth: 400,
      errorBuilder: (_, _, _) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(child: Icon(Icons.broken_image_outlined, size: 32)),
      ),
    );
  }

  Widget _tile(BuildContext context, AttachmentIndexEntry entry, String attachmentsDir, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUnlinked = entry.owner == null;
    final filename = entry.attachment.filename;
    final isSelected = _selectedAttachments.contains(filename);

    return GestureDetector(
      onTap: _isSelectionMode ? () => _toggleSelection(filename) : onTap,
      onLongPress: () => _toggleSelection(filename),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'attachment-${entry.attachment.id}',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: isUnlinked ? Border.all(color: colorScheme.error, width: 1.5) : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: _tileContent(context, entry.attachment, attachmentsDir),
            ),
          ),
          if (isSelected)
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Icon(Icons.check_circle, color: colorScheme.onPrimary, size: 32)),
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

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        appBar: AnimatedAppBarSwitcher(
          child: _isSelectionMode
              ? AppBar(
                  key: const ValueKey('attachments-selection-app-bar'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clearSelection,
                  ),
                  title: Text('${_selectedAttachments.length} selected'),
                  actions: [
                    IconButton(
                      onPressed: _isDeleting ? null : _deleteSelectedAttachments,
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete selected',
                    ),
                  ],
                )
              : AppBar(
                  key: const ValueKey('attachments-app-bar'),
                  title: const Text('Attachments'),
                ),
        ),
        body: SafeArea(
          child: FutureBuilder<_AttachmentFolder>(
            future: _folder,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const EmptyStatePlaceholder(
                  icon: Icons.folder_off_outlined,
                  title: 'Attachments unavailable',
                  subtitle: 'The attachments folder could not be opened.',
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final folder = snapshot.data!;
              final entries = _entries(appRepository, folder.filenames);
              if (entries.isEmpty) {
                return const EmptyStatePlaceholder(
                  icon: Icons.attach_file,
                  title: 'No attachments yet',
                  subtitle: 'Images and files you add to a setup, bike or component appear here.',
                );
              }

              final unlinkedCount = entries.where((e) => e.owner == null).length;
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
      ),
    );
  }
}
