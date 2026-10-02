import 'package:flutter/material.dart';

import '../models/attachment.dart';
import '../services/attachment_storage_service.dart';
import 'attachment_strip.dart';

/// Read-only attachment strip with a leading icon, aligned like a dense `ListTile`.
class AttachmentRow extends StatefulWidget {
  final List<Attachment> attachments;

  const AttachmentRow({super.key, required this.attachments});

  @override
  State<AttachmentRow> createState() => _AttachmentRowState();
}

class _AttachmentRowState extends State<AttachmentRow> {
  late final Future<String> _attachmentsDir = AttachmentStorageService().getAttachmentsPath();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.attach_file),
          ),
          Expanded(
            child: FutureBuilder<String>(
              future: _attachmentsDir,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 80,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return AttachmentStrip(
                  attachments: widget.attachments,
                  attachmentsDir: snapshot.data!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
