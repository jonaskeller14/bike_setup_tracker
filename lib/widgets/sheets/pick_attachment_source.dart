import 'package:flutter/material.dart';

enum AttachmentSource { gallery, camera, file }

Future<AttachmentSource?> showPickAttachmentSourceSheet(BuildContext context) {
  return showModalBottomSheet<AttachmentSource>(
    useSafeArea: true,
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(ctx, AttachmentSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(ctx, AttachmentSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.attach_file),
            title: const Text('Choose File'),
            onTap: () => Navigator.pop(ctx, AttachmentSource.file),
          ),
        ],
      ),
    ),
  );
}
