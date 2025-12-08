import 'package:flutter/material.dart';

Future<bool> showConfirmationDialog(
  BuildContext context, {
  String title = "Are you sure?",
  String? content = "This action cannot be undone.",
  String falseText = "Cancel",
  String trueText = "Continue"
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: content == null ? null : Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(falseText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(trueText),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
