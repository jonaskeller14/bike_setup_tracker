import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import '../../models/app_settings.dart';
import '../../services/google_drive_service.dart';
import 'sheet.dart';

Future<void> showGoogleDriveSheet({required BuildContext context, required GoogleDriveService googleDriveService}) async {
  return await showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (BuildContext context) => GoogleDriveSheet(googleDriveService: googleDriveService),
  );
}

class GoogleDriveSheet extends StatelessWidget {
  final GoogleDriveService googleDriveService;

  const GoogleDriveSheet({
    super.key,
    required this.googleDriveService
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();
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
            ListenableBuilder(
              listenable: googleDriveService, 
              builder: (context, child) {
                final isSignedIn = googleDriveService.isSignedIn;
                final lastSync = googleDriveService.lastSync;
                final isSyncing = googleDriveService.status == GoogleDriveServiceStatus.syncing;
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSignedIn
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.surfaceContainerHigh,
                        foregroundImage: (isSignedIn && googleDriveService.photoUrl != null)
                            ? NetworkImage(googleDriveService.photoUrl!)
                            : null,
                        child: !isSignedIn
                            ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant)
                            : null,
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
                    ),
                    if (lastSync != null || isSignedIn) 
                      ListTile(
                        leading: Icon(Icons.access_time),
                        title: lastSync == null
                            ? Text("No sync history found.")
                            : Text("Last sync: ${DateFormat(appSettings.dateFormat).format(lastSync.toLocal())} ${DateFormat(appSettings.timeFormat).format(lastSync.toLocal())}"),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    if (googleDriveService.errorMessage.isNotEmpty)
                      ListTile(
                        leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                        title: Text(googleDriveService.errorMessage, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
