import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../database/app_database.dart';
import '../../icons/simple_icons.dart';
import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../models/selected_data.dart';
import '../../models/service_error.dart';
import '../../services/google_drive_service.dart';
import '../../utils/backup.dart';
import '../../utils/file_import.dart';
import '../sticky_section.dart';
import '../timeline_day_header.dart';
import 'sheet_header.dart';

class BackupSheetContent extends StatefulWidget {
  final void Function(SelectedData) onRestore;
  final VoidCallback? onBack;

  const BackupSheetContent({super.key, required this.onRestore, this.onBack});

  @override
  State<BackupSheetContent> createState() => _BackupSheetContentState();
}

class _BackupSheetContentState extends State<BackupSheetContent> {
  late Future<List<Backup>> _backups;

  DataError? _localBackupError;
  DataError? _googleDriveBackupError;
  DataError? _readBackupError;
  Backup? _restoringBackup;

  ListTile _backupListTile({
    required BuildContext context,
    required Backup backup,
    required DateFormat timeFormat,
  }) {
    final isRestoring = identical(backup, _restoringBackup);
    return ListTile(
      leading: switch (backup) {
        LocalBackup() => const Icon(Icons.phone_android),
        GoogleDriveBackup() => const Icon(SimpleIcons.googledrive),
      },
      title: switch (backup) {
        LocalBackup() => Text(context.l10n.backupLocal),
        GoogleDriveBackup() => Text(context.l10n.backupGoogleDrive),
      },
      subtitle: Text(isRestoring
          ? switch (backup) {
              LocalBackup() => context.l10n.backupReading,
              GoogleDriveBackup() => context.l10n.backupDownloading,
            }
          : context.l10n.backupCreatedAt(timeFormat.format(backup.createdAt.toLocal()))),
      trailing: isRestoring ? const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2)),
      ) : IconButton(
        onPressed: _restoringBackup != null ? null : () async {
          setState(() => _restoringBackup = backup);
          switch (backup) {
            case LocalBackup():
              final appDatabase = context.read<AppDatabase>();
              final result = await FileImport.readBackup(path: backup.filepath, appDatabase: appDatabase);
              if (!mounted) return;
              setState(() => _restoringBackup = null);
              if (result.isError) {
                setState(() => _readBackupError = result.error);
              } else {
                widget.onRestore(result.appData!);
              }
            case GoogleDriveBackup(): 
              final appDatabase = context.read<AppDatabase>();
              final result = await context.read<GoogleDriveService>().readBackup(fileId: backup.fileId, appDatabase: appDatabase);
              if (!mounted) return;
              setState(() => _restoringBackup = null);
              if (result.isError) {
                setState(() => _readBackupError = result.error);
              } else {
                widget.onRestore(result.appData!);
              }
          }
        },
        icon: const Icon(Icons.upload),
        tooltip: context.l10n.backupRestoreTooltip,
      ),
    );
  }

  Widget _backupDaySection({
    required BuildContext context,
    required DateTime day,
    required List<Backup> backups,
    required DateFormat timeFormat,
  }) {
    return StickySection(
      header: TimelineDayHeader(day: day, margin: EdgeInsets.zero),
      content: Column(
        children: [
          for (var index = 0; index < backups.length; index++) ...[
            _backupListTile(
              context: context,
              backup: backups[index],
              timeFormat: timeFormat,
            ),
            if (index + 1 < backups.length) const Divider(),
          ],
        ],
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
    if (result.isError) _localBackupError = result.error;
    return result.backups;
  }
  
  Future<List<GoogleDriveBackup>> _fetchGoogleDriveBackups() async {
    final result = await context.read<GoogleDriveService>().getBackups();
    if (result.isError) _googleDriveBackupError = result.error;
    return result.backups;
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();
    final timeFormat = DateFormat(appSettings.timeFormat, context.l10n.localeName);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            title: context.l10n.backupSheetTitle,
            onBack: widget.onBack,
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
                    title: Text(context.l10n.backupInfoDaily),
                    dense: true,
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(context.l10n.backupInfoRetention),
                    dense: true,
                  ),
                  if (_localBackupError != null)
                    ListTile(
                      leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                      title: SelectableText(_localBackupError!.message(context.l10n)),
                      dense: true,
                    ),
                  if (_googleDriveBackupError != null)
                    ListTile(
                      leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                      title: SelectableText(_googleDriveBackupError!.message(context.l10n)),
                      dense: true,
                    ),
                  if (_readBackupError != null)
                    ListTile(
                      leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                      title: SelectableText(_readBackupError!.message(context.l10n)),
                      dense: true,
                    ),
                  FutureBuilder<List<Backup>>(
                    future: _backups, 
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: LinearProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return ListTile(title: Text(context.l10n.backupLoadError));
                      }

                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final List<Backup> backups = snapshot.data!;
                        
                        backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                        final sections = <({DateTime day, List<Backup> backups})>[];
                        for (final backup in backups) {
                          final local = backup.createdAt.toLocal();
                          final day = DateTime(local.year, local.month, local.day);
                          if (sections.isEmpty || sections.last.day != day) {
                            sections.add((day: day, backups: []));
                          }
                          sections.last.backups.add(backup);
                        }

                        return Column(
                          children: [
                            for (final section in sections)
                              _backupDaySection(
                                context: context,
                                day: section.day,
                                backups: section.backups,
                                timeFormat: timeFormat,
                              ),
                          ],
                        );
                      }

                      return ListTile(
                        title: Text(context.l10n.backupNone),
                        leading: const Icon(Icons.search_off),
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
