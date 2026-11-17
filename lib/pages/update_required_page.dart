import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../l10n/l10n.dart';
import '../services/file_save_service.dart';
import '../utils/app_update_actions.dart';

/// Shown instead of the app when this build is below `min_supported_build`.
class UpdateRequiredPage extends StatelessWidget {
  final AppDatabase database;
  final FileSaveService? fileSaveService;

  const UpdateRequiredPage({
    super.key,
    required this.database,
    this.fileSaveService,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Icon(Icons.system_update, color: theme.colorScheme.primary, size: 60),
                  Text(
                    l10n.updateRequiredTitle,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    l10n.updateRequiredMessage,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l10n.updateRequiredUpdate),
                    onPressed: () => openStorePage(context),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.folder_zip_outlined),
                    label: Text(l10n.updateRequiredExportBackup),
                    onPressed: () => exportBackupForUpdate(context, database, fileSaveService: fileSaveService),
                  ),
                  Text(
                    l10n.updateRequiredNoUpdateHint,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
