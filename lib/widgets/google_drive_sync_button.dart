import 'package:flutter/material.dart';
import '../services/google_drive_service.dart';
import 'dialogs/google_drive_sync.dart';

class GoogleDriveSyncButton extends StatelessWidget {
  final GoogleDriveService googleDriveService;
  final bool isSyncing;

  const GoogleDriveSyncButton({
    super.key,
    required this.googleDriveService,
    required this.isSyncing,
  });

  @override
  Widget build(BuildContext context) {
    final isLinked = googleDriveService.isSignedIn;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(isLinked ? (isSyncing ? Icons.cloud_upload : Icons.cloud_done_outlined) : Icons.cloud_off),
          onPressed: isSyncing ? null : () => showGoogleDriveDialog(context: context, googleDriveService: googleDriveService),
          tooltip: isLinked ? "Sync Now" : "Connect Google Drive",
        ),
        
        // The "Badge" with loading circle
        if (isSyncing)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 14,
              height: 14,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}
