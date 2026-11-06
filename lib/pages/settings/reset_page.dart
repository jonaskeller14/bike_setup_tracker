import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../repositories/app_repository.dart';
import '../../services/backup_service.dart';
import '../../utils/data_actions.dart';
import '../loading_error_page.dart';

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
    final l10n = context.l10n;
    final errorColor = Theme.of(context).colorScheme.error;
    final hasDefaultSettings = context.select<AppSettings, bool>((settings) => settings.hasDefaultValues);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                enabled: !hasDefaultSettings,
                leading: const Icon(Icons.settings_backup_restore),
                title: Text(l10n.resetSettings),
                subtitle: Text(hasDefaultSettings ? l10n.resetSettingsDefaults : l10n.resetSettingsRestore),
                onTap: () => DataActions.resetAppSettings(context),
              ),
              ListTile(
                enabled: _hasBackups,
                leading: const Icon(Icons.folder_delete_outlined),
                title: Text(l10n.resetDeleteBackups),
                subtitle: Text(_hasBackups ? l10n.resetDeleteBackupsSubtitle : l10n.resetNoBackups),
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
                    title: Text(l10n.resetClearDatabase),
                    subtitle: Text(hasUserData ? l10n.resetClearDatabaseSubtitle : l10n.resetDatabaseEmpty),
                    onTap: () => _runAndRefresh(DataActions.clearDatabase),
                  );
                },
              ),
              if (context.select<AppSettings, bool>((settings) => settings.developerMode))
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Show Loading Error Page'),
                  subtitle: const Text('Debug only: preview the page shown when the app fails to load'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const LoadingErrorPage()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
