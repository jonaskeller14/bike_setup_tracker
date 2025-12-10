import 'package:flutter/material.dart';
import '../services/google_drive_service.dart';
import 'dialogs/google_drive_sync.dart';

class GoogleDriveSyncButton extends StatelessWidget {
  final GoogleDriveService googleDriveService;

  const GoogleDriveSyncButton({
    super.key,
    required this.googleDriveService,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: googleDriveService,
      builder: (context, child) {
        final isSyncing = googleDriveService.isSyncing;
        final isLinked = googleDriveService.isSignedIn && googleDriveService.isAuthorized;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(isLinked 
                  ? (isSyncing 
                      ? Icons.cloud_upload
                      : Icons.cloud_done_outlined)
                  : Icons.cloud_off),
              onPressed: isSyncing 
                  ? null 
                  : () => showGoogleDriveDialog(context: context, googleDriveService: googleDriveService),
              tooltip: isLinked ? "Sync Now" : "Connect Google Drive",
            ),
            
            // The "Badge" with loading circle (only shown if isSyncing is true)
            if (isSyncing)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 14,
                  height: 14,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary,
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
      },
    );
  }
}
