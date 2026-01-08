import 'package:flutter/material.dart';

Future<String?> showImportDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import Data'),
          content: const Text(
            'Do you want to import data from a file or restore data from a backup?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'file'),
              child: const Text('Import File'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'backup'),
              child: const Text('Restore Backup'),
            ),
          ],
        );
      },
    );
  }