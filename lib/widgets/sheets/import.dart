import 'package:flutter/material.dart';

Future<String?> showImportSheet(BuildContext context) async {
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
