import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import '../../models/app_settings.dart';
import '../../services/google_drive_service.dart';
import 'sheet.dart';

Future<void> showGoogleDriveSheet({required BuildContext context}) async {
  return await showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (BuildContext context) => GoogleDriveSheet(),
  );
}

class GoogleDriveSheet extends StatelessWidget {
  const GoogleDriveSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final googleDriveService = context.watch<GoogleDriveService>();
    final isSignedIn = googleDriveService.isSignedIn;
    final isSyncing = googleDriveService.status == GoogleDriveServiceStatus.syncing;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  spacing: 6,
                  children: [
                    Icon(SimpleIcons.googledrive, color: Theme.of(context).colorScheme.onSurface),
                    sheetTitle(context, 'Google Drive Sync'),
                  ],
                ),
                sheetCloseButton(context),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _accountListTile(context),
                    if (isSignedIn) 
                      _buildSyncInfoSection(context, googleDriveService),
                    if (googleDriveService.errorMessage.isNotEmpty)
                      ListTile(
                        leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                        title: SelectableText(googleDriveService.errorMessage, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 16,
              children: [
                if (isSignedIn) ...[
                  OutlinedButton.icon(
                    icon: Icon(Icons.logout),
                    onPressed: !isSyncing ? () async {
                      await googleDriveService.signOut();
                    } : null,
                    label: const Text("Sign out"),
                  ),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: !isSyncing ? () async {
                          await googleDriveService.interactiveSync();
                        } : null,
                        icon: isSyncing ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ) : const Icon(Icons.sync),
                        label: const Text("Sync"),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: !isSyncing ? () async {
                          await googleDriveService.interactiveSignIn();
                        } : null,
                        icon: const Icon(Icons.login),
                        label: const Text("Sign in to Google Drive"),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountListTile(BuildContext context) {
    final googleDriveService = context.watch<GoogleDriveService>();
    final isSignedIn = googleDriveService.isSignedIn;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isSignedIn
            ? Colors.transparent
            : Theme.of(context).colorScheme.surfaceContainerHigh,
        foregroundImage: (isSignedIn && googleDriveService.photoUrl != null)
            ? NetworkImage(googleDriveService.photoUrl!)
            : null,
        child: !isSignedIn
            ? Icon(Icons.person_off, color: Theme.of(context).colorScheme.onSurfaceVariant)
            : Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      title: Text(
        isSignedIn
            ? (googleDriveService.displayName ?? 'Unknown User')
            : 'Not signed in',
        style: const TextStyle(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        isSignedIn
            ? (googleDriveService.email ?? '')
            : 'Sign in to sync your data',
        overflow: TextOverflow.ellipsis,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSyncInfoSection(BuildContext context, GoogleDriveService googleDriveService) {
    final appSettings = context.watch<AppSettings>();
    final lastSync = googleDriveService.lastSync;

    return ListTile(
      leading: const Icon(Icons.sync_alt),
      title: const Text("Auto-sync is active"),
      subtitle: const Text("Changes automatically sync with Google Drive."),
      dense: true,
      contentPadding: EdgeInsets.zero,
      trailing: Tooltip(
        triggerMode: TooltipTriggerMode.tap,
        preferBelow: false,
        showDuration: const Duration(seconds: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow, blurRadius: 4, offset: const Offset(0, 2))],
        ),
        richMessage: WidgetSpan(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text("Bike Setup Tracker automatically syncs changes with your private Google Drive Cloud. "
                  "Additionally daily backups are created which can be restored via 'Import Data -> Backup'. "
                  "Backups are permanently deleted after 30 days. "
                  "You can also trigger a manual sync.", 
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary,
                  )),
              const SizedBox(height: 6),
              Text(
                lastSync != null
                    ? "Last sync: ${DateFormat(appSettings.dateFormat).format(lastSync)} ${DateFormat(appSettings.timeFormat).format(lastSync)}"
                    : "No sync history found.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ],
          )
        ),
        child: Icon(
          Icons.info_outline,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: Theme.of(context).textTheme.bodyLarge?.fontSize,
        ),
      ),
    );
  }
}
