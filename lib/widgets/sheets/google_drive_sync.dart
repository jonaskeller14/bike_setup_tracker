import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import '../../models/app_settings.dart';
import '../../services/google_drive_service.dart';

Future<void> showGoogleDriveSheet({required BuildContext context, required GoogleDriveService googleDriveService}) async {
  return await showModalBottomSheet<void>(
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (BuildContext context) => GoogleDriveSheet(googleDriveService: googleDriveService),
  );
}

class GoogleDriveSheet extends StatefulWidget {
  final GoogleDriveService googleDriveService;

  const GoogleDriveSheet({
    super.key,
    required this.googleDriveService
  });

  @override
  State<StatefulWidget> createState() => _GoogleDriveSheetState();
}

class _GoogleDriveSheetState extends State<GoogleDriveSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final appSettings = context.read<AppSettings>();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSignedIn = widget.googleDriveService.isSignedIn;
    final lastSync = widget.googleDriveService.lastSync;

    Widget lastSyncWidget;
    if (lastSync != null) {
      lastSyncWidget = Row(
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
      );
    } else if (isSignedIn) {
      lastSyncWidget = Text(
        "No sync history found.",
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    } else {
      lastSyncWidget = const SizedBox.shrink();
    }

    final List<Widget> actions = [];

    if (isSignedIn) {
      actions.add(
        OutlinedButton.icon(
          icon: Icon(Icons.logout),
          onPressed: !_isLoading ? () async {
            setState(() {_isLoading = true;});
            await widget.googleDriveService.signOut();
            setState(() {_isLoading = false;});
          } : null,
          label: const Text("Sign out"),
        ),
      );
      actions.add(
        FilledButton.icon(
          onPressed: !_isLoading ? () async {
            setState(() {_isLoading = true;});
            await widget.googleDriveService.interactiveSync();
            setState(() {_isLoading = false;});
          } : null,
          icon: _isLoading ? const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ) : const Icon(Icons.sync),
          label: const Text("Sync"),
        ),
      );
    } else {
      actions.add(
        FilledButton.icon(
          onPressed: !_isLoading ? () async {
            setState(() {_isLoading = true;});
            await widget.googleDriveService.interactiveSignIn();
            setState(() {_isLoading = false;});
          } : null,
          icon: const Icon(Icons.login),
          label: const Text("Sign in to Google Drive"),
        ),
      );
    }

    actions.insert(0,
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text("Cancel"),
      ),
    );
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsGeometry.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              spacing: 4,
              children: [
                Icon(SimpleIcons.googledrive),
                Text(
                  "Google Drive Synchronisation",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isSignedIn
                      ? Colors.transparent
                      : colorScheme.surfaceContainerHigh,
                  foregroundImage: (isSignedIn && widget.googleDriveService.photoUrl != null)
                      ? NetworkImage(widget.googleDriveService.photoUrl!)
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
                            ? (widget.googleDriveService.displayName ?? 'Unknown User')
                            : 'Not signed in',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isSignedIn
                            ? (widget.googleDriveService.email ?? '')
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
            lastSyncWidget,
            
            if (widget.googleDriveService.errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(widget.googleDriveService.errorMessage, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}
