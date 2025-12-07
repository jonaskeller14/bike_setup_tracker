import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/google_drive_service.dart';

Future<void> showGoogleDriveDialog({required BuildContext context, required GoogleDriveService googleDriveService}) async {
  return await showDialog<void>(
    context: context, 
    builder: (BuildContext context) => ShowGoogleDriveDialog(googleDriveService: googleDriveService),
  );
}

class ShowGoogleDriveDialog extends StatefulWidget {
  final GoogleDriveService googleDriveService;

  const ShowGoogleDriveDialog({
    super.key,
    required this.googleDriveService
  });

  @override
  State<StatefulWidget> createState() => _ShowGoogleDriveDialogState();
}

class _ShowGoogleDriveDialogState extends State<ShowGoogleDriveDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSignedIn = widget.googleDriveService.isSignedIn;
    return AlertDialog(
      title: const Text("Google Drive Synchronisation"),
      content: Column(
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
          Text("Last Sync: ${widget.googleDriveService.lastSync != null ? DateFormat("yyyy-MM-dd HH:mm").format(widget.googleDriveService.lastSync!) : '-'}"),
          if (widget.googleDriveService.errorMessage.isNotEmpty)
            Text(widget.googleDriveService.errorMessage, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ),
      actionsOverflowAlignment: OverflowBarAlignment.start,
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel")
        ),
        ElevatedButton(
          onPressed: isSignedIn && !_isLoading ? () async {
            setState(() {_isLoading = true;});
            await widget.googleDriveService.interactiveSync();
            setState(() {_isLoading = false;});
          } : null, 
          child: Text("Sync")
        ),
        ElevatedButton(
          onPressed: !isSignedIn && !_isLoading ? () async {
            setState(() {_isLoading = true;});
            await widget.googleDriveService.interactiveSignIn();
            setState(() {_isLoading = false;});
          } : null, 
          child: const Text("Sign in"),
        ),
        ElevatedButton(
          onPressed: isSignedIn && !_isLoading ? () async {
            setState(() {_isLoading = true;});
            await widget.googleDriveService.signOut();
            setState(() {_isLoading = false;});
          } : null, 
          child: const Text("Sign out"),
        ),
      ],
    );
  }
}
