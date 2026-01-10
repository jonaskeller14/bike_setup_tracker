import 'package:flutter/material.dart';

Future<String?> showImportMergeOverwriteSheet(BuildContext context) async {
  return showModalBottomSheet<String?>(
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (context) {
      return SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              Text('Import Data', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              ListTile(
                leading: Icon(Icons.replay, color: Theme.of(context).colorScheme.primary),
                title: const Text("Overwrite data"),
                subtitle: const Text("Replace your local data with the imported data. This will permanently delete existing data and cannot be undone."),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.pop(context, 'file'),
              ),
              ListTile(
                leading: Icon(Icons.merge, color: Theme.of(context).colorScheme.primary),
                title: const Text("Merge data"),
                subtitle: const Text("Add new items and update existing items when the imported version is newer (based on modification date)."),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.pop(context, 'backup'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
