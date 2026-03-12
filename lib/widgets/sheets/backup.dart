import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import '../../models/selected_data.dart';
import '../../models/app_settings.dart';
import '../../database/app_database.dart';
import '../../services/google_drive_service.dart';
import '../../utils/file_import.dart';
import '../../utils/backup.dart';
import 'sheet.dart';

class BackupSheetContent extends StatefulWidget {
  final Function(SelectedData) onRestore;
  final VoidCallback? onBack;

  const BackupSheetContent({super.key, required this.onRestore, this.onBack});

  @override
  State<BackupSheetContent> createState() => _BackupSheetContentState();
}

class _BackupSheetContentState extends State<BackupSheetContent> {
  late Future<List<Backup>> _backups;

  String? _localBackupError;
  String? _googleDriveBackupError;
  String? _readBackupError;

  ListTile _backupListTile({
    required BuildContext context,
    required Backup backup,
    required DateFormat dateFormat,
    required DateFormat timeFormat,
  }) {
    return ListTile(
      leading: switch (backup) {
        LocalBackup() => const Icon(Icons.phone_android),
        GoogleDriveBackup() => const Icon(SimpleIcons.googledrive),
      },
      title: switch (backup) {
        LocalBackup() => const Text("Local Backup"),
        GoogleDriveBackup() => const Text("Google Drive Backup"),
      },
      subtitle: Text("Created at: ${dateFormat.format(backup.createdAt.toLocal())} ${timeFormat.format(backup.createdAt.toLocal())}"),
      trailing: IconButton(
        onPressed: () async {
          switch (backup) {
            case LocalBackup():
              final appDatabase = context.read<AppDatabase>();
              final result = await FileImport.readBackup(path: backup.filepath, appDatabase: appDatabase);
              if (result.isError) {
                setState(() => _readBackupError = result.errorMessage);
              } else {
                widget.onRestore(result.appData!);
              }
            case GoogleDriveBackup(): 
              final appDatabase = context.read<AppDatabase>();
              final result = await context.read<GoogleDriveService>().readBackup(fileId: backup.fileId, appDatabase: appDatabase);
              if (result.isError) {
                setState(() => _readBackupError = result.errorMessage);
              } else {
                widget.onRestore(result.appData!);
              }
          }
        },
        icon: const Icon(Icons.upload),
        tooltip: 'Restore backup',
      ),
    );
  }

  @override @override
  void initState() {
    super.initState();
    _backups = _fetchBackups();
  }

  Future<List<Backup>> _fetchBackups() async {
    final appSettings = context.read<AppSettings>();

    final results = await Future.wait([
      _fetchLocalBackups(),
      if (appSettings.enableGoogleDrive)
        _fetchGoogleDriveBackups(),
    ]);

    if (mounted) { 
      setState(() {}); // rebuild error ListTiles
    }
    
    final backups = results.expand((list) => list).toList();
    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return backups;
  }

  Future<List<LocalBackup>> _fetchLocalBackups() async {
    final result = await FileImport.getBackups();
    if (result.isError) _localBackupError = result.errorMessage;
    return result.backups;
  }
  
  Future<List<GoogleDriveBackup>> _fetchGoogleDriveBackups() async {
    final result = await context.read<GoogleDriveService>().getBackups();
    if (result.isError) _googleDriveBackupError = result.errorMessage;
    return result.backups;
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();
    final dateFormat = DateFormat(appSettings.dateFormat);
    final timeFormat = DateFormat(appSettings.timeFormat);

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
                if (widget.onBack != null)
                  sheetBackButton(context, onPressed: widget.onBack!),
                sheetTitle(context, 'Import Backup'),
                sheetCloseButton(context),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Backups are created once per day. To restore a backup, you can choose to overwrite current data or merge backup data into existing data.'),
                    dense: true,
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Backups older than 30 days are permanently deleted and cannot be restored.'),
                    dense: true,
                  ),
                  if (_localBackupError != null)
                    ListTile(
                      leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                      title: SelectableText(_localBackupError!),
                      dense: true,
                    ),
                  if (_googleDriveBackupError != null)
                    ListTile(
                      leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                      title: SelectableText(_googleDriveBackupError!),
                      dense: true,
                    ),
                  if (_readBackupError != null)
                    ListTile(
                      leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                      title: SelectableText(_readBackupError!),
                      dense: true,
                    ),
                  const Divider(),
                  FutureBuilder<List<Backup>>(
                    future: _backups, 
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: LinearProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return const ListTile(title: Text("Error loading backups"));
                      }

                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final List<Backup> backups = snapshot.data!;
                        
                        backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: backups.length,
                          itemBuilder: (context, index) {
                            return _backupListTile(
                              context: context,
                              backup: backups[index],
                              dateFormat: dateFormat,
                              timeFormat: timeFormat,
                            );
                          },
                          separatorBuilder: (context, index) => const Divider(),
                        );
                      }

                      return const ListTile(
                        title: Text('No backups found.'),
                        leading: Icon(Icons.search_off),
                      );
                    },
                  ),
                  const Divider(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
