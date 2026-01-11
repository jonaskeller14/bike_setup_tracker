import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import '../../models/app_settings.dart';
import 'sheet.dart';

Future<String?> showExportSheet({required BuildContext context}) async {
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
                    sheetTitle(context, 'Export Data'),
                    sheetCloseButton(context),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.insert_drive_file, color: Theme.of(context).colorScheme.primary),
                title: const Text("Download File"),
                subtitle: const Text("Download json file containing the data"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.pop(context, 'file'),
              ),
              ListTile(
                leading: Icon(Icons.file_present_sharp, color: Theme.of(context).colorScheme.primary),
                title: const Text("Save Backup"),
                subtitle: const Text("Save current state as a local backup"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                onTap: () => Navigator.pop(context, 'backup'),
              ),
              if (context.read<AppSettings>().enableGoogleDrive)
                ListTile(
                  leading: Icon(SimpleIcons.googledrive, color: Theme.of(context).colorScheme.primary),
                  title: const Text("Save Google Drive Backup"),
                  subtitle: const Text("Save current state as Backup in Google Drive"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onTap: () => Navigator.pop(context, 'googleDriveBackup'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
