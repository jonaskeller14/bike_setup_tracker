import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../utils/file_import.dart';

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  ListTile _backupListTile({
    required BuildContext context,
    required DateTime datetime,
    required String path,
    required DateFormat dateFormat,
    required DateFormat timeFormat,
  }) {
    return ListTile(
      title: Text("Backup"),
      subtitle: Text("Created at: ${dateFormat.format(datetime)} ${timeFormat.format(datetime)}"),
      trailing: IconButton(
        onPressed: () => Navigator.pop(context, path),
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
            FutureBuilder(
              future: FileImport.getBackups(context),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final backups = snapshot.data!;
                  final sortedBackups = SplayTreeMap<DateTime, String>.from(backups, (a, b) => b.compareTo(a));
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: sortedBackups.length,
                    itemBuilder: (context, index) {
                      return _backupListTile(
                        context: context,
                        datetime: sortedBackups.keys.toList()[index],
                        path: sortedBackups.values.toList()[index],
                        dateFormat: dateFormat,
                        timeFormat: timeFormat,
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(),
                  );
                }
                return const Text('No backups found.');
              },
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
