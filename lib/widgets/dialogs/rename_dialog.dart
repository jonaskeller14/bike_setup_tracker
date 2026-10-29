import 'package:flutter/material.dart';

import 'dialog_action.dart';

/// Returns the trimmed new name, or null when the dialog was cancelled or the
/// name is blank or unchanged.
Future<String?> showRenameDialog(BuildContext context, {required String title, required String name}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (context) => _RenameDialog(title: title, name: name),
  );
  final trimmed = result?.trim();
  if (trimmed == null || trimmed.isEmpty || trimmed == name) return null;
  return trimmed;
}

class _RenameDialog extends StatefulWidget {
  final String title;
  final String name;

  const _RenameDialog({required this.title, required this.name});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
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
      title: Text(widget.title),
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
