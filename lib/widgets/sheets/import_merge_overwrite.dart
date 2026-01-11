import 'package:flutter/material.dart';
import 'sheet.dart';

Future<String?> showImportMergeOverwriteSheet(BuildContext context) async {
  return showModalBottomSheet<String?>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (context) {
      return SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    sheetTitle(context, 'Import Data'),
                    sheetCloseButton(context),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.replay, color: Theme.of(context).colorScheme.primary),
                title: const Text("Overwrite data"),
                subtitle: const Text("Replace your local data with the imported data. This will permanently delete existing data and cannot be undone."),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.pop(context, 'overwrite'),
              ),
              ListTile(
                leading: Icon(Icons.merge, color: Theme.of(context).colorScheme.primary),
                title: const Text("Merge data"),
                subtitle: const Text("Add new items and update existing items when the imported version is newer (based on modification date)."),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.pop(context, 'merge'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
