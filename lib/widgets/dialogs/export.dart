import 'package:flutter/material.dart';

Future<String?> showExporttDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export Data'),
          content: const Text(
            'Do you want to export data by downloading a file or manually save a backup?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'file'),
              child: const Text('Download File'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'backup'),
              child: const Text('Save Backup'),
            ),
          ],
        );
      },
    );
  }