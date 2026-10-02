import 'package:flutter/material.dart';

import 'dialog_action.dart';

/// Returns the trimmed new name, or null when the dialog was cancelled or the
/// name is blank or unchanged.
Future<String?> showRenameAttachmentDialog(BuildContext context, {required String name}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (context) => _RenameAttachmentDialog(name: name),
  );
  final trimmed = result?.trim();
  if (trimmed == null || trimmed.isEmpty || trimmed == name) return null;
  return trimmed;
}

class _RenameAttachmentDialog extends StatefulWidget {
  final String name;

  const _RenameAttachmentDialog({required this.name});

  @override
  State<_RenameAttachmentDialog> createState() => _RenameAttachmentDialogState();
}

class _RenameAttachmentDialogState extends State<_RenameAttachmentDialog> {
  late final TextEditingController _controller = TextEditingController.fromValue(
    TextEditingValue(
      text: widget.name,
      selection: TextSelection(baseOffset: 0, extentOffset: widget.name.length),
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: const Text('Rename Attachment'),
      // The Cupertino dialog provides no Material ancestor for the TextField.
      content: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Name'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
      ),
      actions: [
        adaptiveAction(
          context: context,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        adaptiveAction(
          context: context,
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
