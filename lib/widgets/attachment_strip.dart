import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/attachment.dart';
import '../utils/attachment_actions.dart';
import 'attachment_viewer.dart';

enum AttachmentStripMode { view, edit }

class AttachmentFileTile extends StatelessWidget {
  final Attachment attachment;

  const AttachmentFileTile({super.key, required this.attachment});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(attachment.iconData, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(
            attachment.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class AttachmentStrip extends StatefulWidget {
  final List<Attachment> attachments;
  final String attachmentsDir;
  final AttachmentStripMode mode;
  final void Function(int index)? onRemove;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final void Function(List<Attachment> newAttachments)? onAdd;
  final void Function(int index, String name)? onRename;
  final String heroTagPrefix;

  const AttachmentStrip({
    super.key,
    required this.attachments,
    required this.attachmentsDir,
    this.mode = AttachmentStripMode.view,
    this.onRemove,
    this.onReorder,
    this.onAdd,
    this.onRename,
    this.heroTagPrefix = 'attachment',
  });

  @override
  State<AttachmentStrip> createState() => _AttachmentStripState();
}

class _AttachmentStripState extends State<AttachmentStrip> with TickerProviderStateMixin {
  final Map<String, AnimationController> _enterControllers = {};
  final Map<String, AnimationController> _exitControllers = {};

  @override
  void didUpdateWidget(AttachmentStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSet = oldWidget.attachments.map((a) => a.filename).toSet();
    for (final filename in widget.attachments.map((a) => a.filename)) {
      if (!oldSet.contains(filename) && !_enterControllers.containsKey(filename)) {
        final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
        _enterControllers[filename] = ctrl;
        unawaited(
          ctrl.forward().then((_) {
            if (mounted) setState(() => _enterControllers.remove(filename)?.dispose());
          }),
        );
      }
    }
    // Clean up exit controllers for items removed from widget.attachments
    final newSet = widget.attachments.map((a) => a.filename).toSet();
    for (final f in _exitControllers.keys.where((f) => !newSet.contains(f)).toList()) {
      _exitControllers.remove(f)?.dispose();
    }
  }

  @override
  void dispose() {
    for (final ctrl in _enterControllers.values) {
      ctrl.dispose();
    }
    for (final ctrl in _exitControllers.values) {
      ctrl.dispose();
    }
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
    unawaited(
      ctrl.reverse().then((_) {
        if (!mounted) return;
        final index = widget.attachments.indexWhere((a) => a.filename == filename);
        if (index != -1) widget.onRemove?.call(index);
      }),
    );
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

  /// The viewer works on its own copy of the list, so its attachment is looked up again here:
  /// a tile finishing its exit animation meanwhile shifts the indices.
  void _withCurrentIndex(Attachment attachment, void Function(int index) action) {
    final index = widget.attachments.indexWhere((a) => a.id == attachment.id);
    if (index != -1) action(index);
  }

  void _openViewer(BuildContext context, int index) {
    unawaited(
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttachmentViewer(
            attachments: widget.attachments,
            attachmentsDir: widget.attachmentsDir,
            initialIndex: index,
            onDelete: widget.onRemove != null
                ? (attachment) => _withCurrentIndex(attachment, (i) => widget.onRemove?.call(i))
                : null,
            onRename: widget.onRename != null
                ? (attachment, name) => _withCurrentIndex(attachment, (i) => widget.onRename?.call(i, name))
                : null,
          ),
        ),
      ),
    );
  }

  Future<void> _pickAttachments(BuildContext context) async {
    final attachments = await AttachmentActions.pickAttachments(context);
    if (attachments.isEmpty) return;
    widget.onAdd?.call(attachments);
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, size: 32),
      ),
    );
  }

  Widget _tileContent(BuildContext context, Attachment attachment) {
    if (!attachment.isImage) return AttachmentFileTile(attachment: attachment);
    return Image.file(
      File('${widget.attachmentsDir}${Platform.pathSeparator}${attachment.filename}'),
      fit: BoxFit.cover,
      cacheWidth: 300,
      errorBuilder: (_, _, _) => _placeholder(context),
    );
  }

  Widget _thumbnail(BuildContext context, Attachment attachment, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: () => _openViewer(context, index),
          child: Hero(
            tag: '${widget.heroTagPrefix}-${attachment.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _tileContent(context, attachment),
            ),
          ),
        ),
        if (widget.mode == AttachmentStripMode.edit)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => _handleRemove(attachment.filename),
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

    if (widget.attachments.isEmpty && widget.mode == AttachmentStripMode.view) return const SizedBox.shrink();

    if (widget.mode == AttachmentStripMode.edit) {
      Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
        return ScaleTransition(
          scale: Tween(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: SizedBox(
            width: tileSize,
            height: tileSize,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: _tileContent(context, widget.attachments[index]),
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
          itemCount: widget.attachments.length + (widget.onAdd != null ? 1 : 0),
          itemBuilder: (context, index) {
            if (widget.onAdd != null && index == widget.attachments.length) {
              return Padding(
                key: const ValueKey('add_button'),
                padding: EdgeInsets.only(left: widget.attachments.isEmpty ? 0 : spacing),
                child: GestureDetector(
                  onTap: () => _pickAttachments(context),
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
                        Icon(Icons.attach_file, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
            final attachment = widget.attachments[index];
            return ReorderableDelayedDragStartListener(
              key: ValueKey(attachment.filename),
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(right: spacing),
                child: _animatedItem(
                  attachment.filename,
                  SizedBox(
                    width: tileSize,
                    height: tileSize,
                    child: _thumbnail(context, attachment, index),
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
        itemCount: widget.attachments.length,
        separatorBuilder: (_, _) => const SizedBox(width: spacing),
        itemBuilder: (context, index) {
          final attachment = widget.attachments[index];
          return _animatedItem(
            attachment.filename,
            SizedBox(
              width: tileSize,
              height: tileSize,
              child: _thumbnail(context, attachment, index),
            ),
          );
        },
      ),
    );
  }
}
