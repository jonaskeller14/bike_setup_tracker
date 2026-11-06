import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

enum AttachmentSource { gallery, camera, file }

Future<AttachmentSource?> showPickAttachmentSourceSheet(BuildContext context) {
  return showModalBottomSheet<AttachmentSource>(
    useSafeArea: true,
    context: context,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.attachmentSourceGallery),
              onTap: () => Navigator.pop(ctx, AttachmentSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(context.l10n.attachmentSourcePhoto),
              onTap: () => Navigator.pop(ctx, AttachmentSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(context.l10n.attachmentSourceFile),
              onTap: () => Navigator.pop(ctx, AttachmentSource.file),
            ),
          ],
        ),
      ),
    ),
  );
}
