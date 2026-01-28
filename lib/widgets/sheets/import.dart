import 'package:flutter/material.dart';
import 'sheet.dart';

enum ImportSheetOptions {
  file,
  backup,
}

Future<ImportSheetOptions?> showImportSheet(BuildContext context) async {
  return showModalBottomSheet<ImportSheetOptions?>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (context) {
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
                      leading: Icon(Icons.insert_drive_file, color: Theme.of(context).colorScheme.primary),
                      title: const Text("Import File"),
                      subtitle: const Text("Select json file which contains data to import"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () => Navigator.pop(context, ImportSheetOptions.file),
                    ),
                    ListTile(
                      leading: Icon(Icons.file_present_sharp, color: Theme.of(context).colorScheme.primary),
                      title: const Text("Restore Backup"),
                      subtitle: const Text("Restore local or cloud Backup"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                      onTap: () => Navigator.pop(context, ImportSheetOptions.backup),
                    ),
                  ],
                ),
              )
            ), 
          ],
        ),
      );
    },
  );
}
