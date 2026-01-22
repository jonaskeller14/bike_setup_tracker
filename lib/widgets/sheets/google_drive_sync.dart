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

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
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
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: isSignedIn
                              ? Colors.transparent
                              : colorScheme.surfaceContainerHigh,
                          foregroundImage: (isSignedIn && googleDriveService.photoUrl != null)
                              ? NetworkImage(googleDriveService.photoUrl!)
                              : null,
                          child: !isSignedIn
                              ? Icon(Icons.person, color: colorScheme.onSurfaceVariant)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isSignedIn
                                    ? (googleDriveService.displayName ?? 'Unknown User')
                                    : 'Not signed in',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                isSignedIn
                                    ? (googleDriveService.email ?? '')
                                    : 'Sign in to sync your data',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (lastSync != null) 
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(
                            "Last sync: ${DateFormat(appSettings.dateFormat).format(lastSync)} ${DateFormat(appSettings.timeFormat).format(lastSync)}",
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    else if (isSignedIn) 
                      Text(
                        "No sync history found.",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    
                    if (googleDriveService.errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(googleDriveService.errorMessage, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Cancel"),
                        ),

                        if (isSignedIn) ...[
                          OutlinedButton.icon(
                            icon: Icon(Icons.logout),
                            onPressed: !isSyncing ? () async {
                              await googleDriveService.signOut();
                            } : null,
                            label: const Text("Sign out"),
                          ),
                          FilledButton.icon(
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
                        ] else ...[
                          FilledButton.icon(
                            onPressed: !isSyncing ? () async {
                              await googleDriveService.interactiveSignIn();
                            } : null,
                            icon: const Icon(Icons.login),
                            label: const Text("Sign in to Google Drive"),
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
