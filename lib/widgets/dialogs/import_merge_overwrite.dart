import 'package:flutter/material.dart';

Future<String?> showImportMergeOverwriteDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import JSON'),
          content: const Text(
            'Do you want to overwrite existing data or append (merge) the imported data? Existing data could be lost forever and cannot be restored.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'merge'),
              child: const Text('Merge'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'overwrite'),
              child: const Text('Overwrite'),
            ),
          ],
        );
      },
    );
  }