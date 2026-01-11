import 'package:flutter/material.dart';
import 'sheet.dart';

Future<String?> showImportSheet(BuildContext context) async {
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
                leading: Icon(Icons.insert_drive_file, color: Theme.of(context).colorScheme.primary),
                title: const Text("Import File"),
                subtitle: const Text("Select json file which contains data to import"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.pop(context, 'file'),
              ),
              ListTile(
                leading: Icon(Icons.file_present_sharp, color: Theme.of(context).colorScheme.primary),
                title: const Text("Restore Backup"),
                subtitle: const Text("Restore local or cloud Backup"),
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
