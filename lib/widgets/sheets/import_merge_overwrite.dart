import 'package:flutter/material.dart';
import 'sheet.dart';

class SelectImportMethodSheetContent extends StatelessWidget {
  final VoidCallback onOverwrite;
  final VoidCallback onMerge;
  final VoidCallback onReplace;
  final VoidCallback onBack;

  const SelectImportMethodSheetContent({
    super.key, 
    required this.onOverwrite,
    required this.onMerge,
    required this.onReplace,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                sheetBackButton(context, onPressed: onBack),
                sheetTitle(context, 'Import Data'),
                sheetCloseButton(context),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.published_with_changes, color: Theme.of(context).colorScheme.primary),
                    title: const Text("Overwrite data"),
                    subtitle: const Text("Overwrite your local data with the imported data. Unique local data will remain."),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onOverwrite,
                  ),
                  ListTile(
                    leading: Icon(Icons.merge, color: Theme.of(context).colorScheme.primary),
                    title: const Text("Merge data"),
                    subtitle: const Text("Add new items and update existing items when the imported version is newer (based on modification date)."),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onMerge,
                  ),
                  ListTile(
                    leading: Icon(Icons.find_replace, color: Theme.of(context).colorScheme.primary),
                    title: const Text("Replace data"),
                    subtitle: const Text("Replace your local data with the imported data. This will permanently delete all existing data and cannot be undone."),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                    onTap: onReplace,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
