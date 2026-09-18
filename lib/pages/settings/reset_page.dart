import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../repositories/app_repository.dart';
import '../../services/backup_service.dart';
import '../../utils/data_actions.dart';

class ResetPage extends StatefulWidget {
  const ResetPage({super.key});

  @override
  State<ResetPage> createState() => _ResetPageState();
}

class _ResetPageState extends State<ResetPage> {
  late final Stream<bool> _hasUserData;
  bool _hasBackups = false;

  @override
  void initState() {
    super.initState();
    _hasUserData = context.read<AppRepository>().database.watchHasUserData();
    unawaited(_refreshHasBackups());
  }

  Future<void> _refreshHasBackups() async {
    final hasBackups = await BackupService.hasBackups();
    if (!mounted) return;
    setState(() => _hasBackups = hasBackups);
  }

  Future<void> _runAndRefresh(Future<void> Function(BuildContext context) action) async {
    await action(context);
    await _refreshHasBackups();
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final hasDefaultSettings = context.select<AppSettings, bool>((settings) => settings.hasDefaultValues);

    return Scaffold(
      appBar: AppBar(title: const Text('Reset & Delete')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                enabled: !hasDefaultSettings,
                leading: const Icon(Icons.settings_backup_restore),
                title: const Text('Reset Settings'),
                subtitle: Text(
                  hasDefaultSettings
                      ? 'All settings are at their defaults'
                      : 'Restore all preferences and features to their defaults',
                ),
                onTap: () => DataActions.resetAppSettings(context),
              ),
              ListTile(
                enabled: _hasBackups,
                leading: const Icon(Icons.folder_delete_outlined),
                title: const Text('Delete All Backups'),
                subtitle: Text(
                  _hasBackups ? 'Remove all automatic backups stored on this device' : 'No backups on this device',
                ),
                onTap: () => _runAndRefresh(DataActions.deleteAllBackups),
              ),
              StreamBuilder<bool>(
                stream: _hasUserData,
                builder: (context, snapshot) {
                  final hasUserData = snapshot.data ?? false;
                  final color = hasUserData ? errorColor : null;
                  return ListTile(
                    enabled: hasUserData,
                    leading: Icon(Icons.delete_forever, color: color),
                    title: Text('Clear Database', style: TextStyle(color: color)),
                    subtitle: Text(
                      hasUserData ? 'Delete all bikes, components, setups and other data' : 'The database is empty',
                    ),
                    onTap: () => _runAndRefresh(DataActions.clearDatabase),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
