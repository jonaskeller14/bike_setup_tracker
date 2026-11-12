import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'dialog_action.dart';

/// Confirms signing out of the account (or deleting it) on this device.
/// Returns whether to remove the data from this device, or null when
/// cancelled. Removing is on by default, which is safe before handing the
/// phone on.
Future<bool?> showAccountSignOutDialog(
  BuildContext context, {
  required String title,
  required String content,
  required String confirmText,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _AccountSignOutDialog(title: title, content: content, confirmText: confirmText),
  );
}

class _AccountSignOutDialog extends StatefulWidget {
  final String title;
  final String content;
  final String confirmText;

  const _AccountSignOutDialog({required this.title, required this.content, required this.confirmText});

  @override
  State<_AccountSignOutDialog> createState() => _AccountSignOutDialogState();
}

class _AccountSignOutDialogState extends State<_AccountSignOutDialog> {
  bool _removeData = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.content),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _removeData,
              onChanged: (value) => setState(() => _removeData = value ?? true),
              title: Text(l10n.accountRemoveDataFromDevice),
            ),
          ],
        ),
      ),
      actions: [
        adaptiveAction(
          context: context,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        adaptiveAction(
          context: context,
          isDestructive: true,
          onPressed: () => Navigator.of(context).pop(_removeData),
          child: Text(widget.confirmText),
        ),
      ],
    );
  }
}
