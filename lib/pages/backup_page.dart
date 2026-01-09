import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import '../models/app_settings.dart';
import '../services/google_drive_service.dart';
import '../utils/file_import.dart';
import '../utils/backup.dart';

class BackupPage extends StatelessWidget {
  final GoogleDriveService? googleDriveService;
  const BackupPage({super.key, this.googleDriveService});

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
        _ => const Icon(Icons.question_mark),
      },
      title: const Text("Backup"),
      subtitle: Text("Created at: ${dateFormat.format(backup.createdAt)} ${timeFormat.format(backup.createdAt)}"),
      trailing: IconButton(
        onPressed: () => Navigator.pop(context, backup),
        icon: const Icon(Icons.upload),
        tooltip: 'Restore backup',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();
    final dateFormat = DateFormat(appSettings.dateFormat);
    final timeFormat = DateFormat(appSettings.timeFormat);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Backup'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const Divider(),
            FutureBuilder<List<Backup>>(
              future: Future.wait([
                FileImport.getBackups(context),
                googleDriveService?.getBackups(context) ?? Future.value(<Backup>[]),
              ]).then((results) => results.expand((list) => list).toList()), 
              
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
    );
  }
}
