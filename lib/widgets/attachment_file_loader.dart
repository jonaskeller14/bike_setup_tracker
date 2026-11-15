import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/attachment.dart';
import '../services/cloud_sync_service.dart';
import '../services/sync/attachment_sync.dart';

enum AttachmentFileStatus { ready, loading, missing }

/// `result` says why a missing file isn't there: null while nothing was asked
/// of the cloud.
typedef AttachmentFileState = ({AttachmentFileStatus status, AttachmentDownloadResult? result, VoidCallback retry});

extension AttachmentFileStateText on AttachmentFileState {
  /// Whether the cloud was asked and couldn't help.
  bool get cloudIssue => result != null && result != AttachmentDownloadResult.notSyncing;

  /// Loading, or missing for a reason the cloud explains. Otherwise the file
  /// is read from disk, and a missing one fails there like any broken image.
  bool get showsPlaceholder => status == AttachmentFileStatus.loading || cloudIssue;

  String? message(BuildContext context) => switch (result) {
    AttachmentDownloadResult.notInCloud => context.l10n.attachmentDownloadNotInCloud,
    AttachmentDownloadResult.offline => context.l10n.attachmentDownloadOffline,
    AttachmentDownloadResult.failed => context.l10n.attachmentDownloadFailed,
    _ => null,
  };
}

/// Builds an attachment from its file on this device. A file this device
/// doesn't have yet is fetched from the cloud first (cloud sync on, premium,
/// signed in); [AttachmentFileStatus.loading] shows meanwhile.
class AttachmentFileLoader extends StatefulWidget {
  final Attachment attachment;
  final String attachmentsDir;
  final Widget Function(BuildContext context, File file, AttachmentFileState state) builder;

  /// The state changed after the first build, so a parent that reads the
  /// file's presence (the viewer's menu) can rebuild.
  final VoidCallback? onChanged;

  const AttachmentFileLoader({
    super.key,
    required this.attachment,
    required this.attachmentsDir,
    required this.builder,
    this.onChanged,
  });

  @override
  State<AttachmentFileLoader> createState() => _AttachmentFileLoaderState();
}

class _AttachmentFileLoaderState extends State<AttachmentFileLoader> {
  late File _file;
  var _status = AttachmentFileStatus.ready;
  AttachmentDownloadResult? _result;
  var _generation = 0;
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listening, because the account session can come up after the first build.
    final sync = Provider.of<CloudSyncService?>(context);
    final becameActive =
        _status == AttachmentFileStatus.missing && _result == AttachmentDownloadResult.notSyncing && (sync?.isActive ?? false);
    if (!_started || becameActive) {
      _started = true;
      _resolve(sync);
    }
  }

  @override
  void didUpdateWidget(AttachmentFileLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment.filename != widget.attachment.filename || oldWidget.attachmentsDir != widget.attachmentsDir) {
      _resolve(Provider.of<CloudSyncService?>(context, listen: false));
    }
  }

  void _resolve(CloudSyncService? sync, {bool force = false}) {
    final generation = ++_generation;
    _file = File(p.join(widget.attachmentsDir, widget.attachment.filename));
    if (_file.existsSync()) {
      _status = AttachmentFileStatus.ready;
      _result = null;
      return;
    }
    if (sync == null || !sync.isActive) {
      _status = AttachmentFileStatus.missing;
      _result = AttachmentDownloadResult.notSyncing;
      return;
    }
    _status = AttachmentFileStatus.loading;
    _result = null;
    unawaited(
      sync.downloadAttachment(widget.attachment, force: force).then((result) {
        if (!mounted || generation != _generation) return;
        setState(() {
          _result = result;
          _status = result.isAvailable ? AttachmentFileStatus.ready : AttachmentFileStatus.missing;
        });
        widget.onChanged?.call();
      }),
    );
  }

  void _retry() {
    setState(() => _resolve(Provider.of<CloudSyncService?>(context, listen: false), force: true));
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _file, (status: _status, result: _result, retry: _retry));
  }
}

/// A thumbnail-sized stand-in for an attachment that isn't on this device.
class AttachmentFilePlaceholder extends StatelessWidget {
  final AttachmentFileState state;

  const AttachmentFilePlaceholder({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: state.status == AttachmentFileStatus.loading
            ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(state.cloudIssue ? Icons.cloud_off_outlined : Icons.broken_image_outlined, size: 32),
      ),
    );
  }
}
