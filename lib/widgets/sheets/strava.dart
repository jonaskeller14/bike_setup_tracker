import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import '../../services/strava_service.dart';
import 'sheet.dart';

Future<void> showStravaSheet({required BuildContext context}) async {
  return await showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (BuildContext context) => StravaSheet(),
  );
}

class StravaSheet extends StatelessWidget {
  const StravaSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final stravaService = context.watch<StravaService>();
    
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
                    sheetTitle(context, 'Strava Sync'),
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
                    if (stravaService.status == StravaServiceStatus.syncing)
                      ListTile(
                        leading: const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        title: Text(stravaService.errorMessage.isEmpty ? "Syncing..." : stravaService.errorMessage),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      )
                    else if (stravaService.errorMessage.isNotEmpty)
                      ListTile(
                        leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                        title: Text(stravaService.errorMessage, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    const SizedBox(height: 8),
                    Text("User ID: ${stravaService.userId ?? 'Loading...'}", 
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          stravaService.isConnected ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: stravaService.isConnected ? Colors.green : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          stravaService.isConnected ? "Connected to Strava" : "Not connected",
                          style: TextStyle(
                            color: stravaService.isConnected ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (stravaService.activities.isNotEmpty) ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text("Synced Activities (Debug):", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...stravaService.activities.map((activity) => ListTile(
                            title: Text(activity.name),
                            subtitle: Text("${activity.type} • ${(activity.distance / 1000).toStringAsFixed(2)} km"),
                            trailing: Text(activity.startDate.toString().split(' ')[0]),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          )),
                    ] else
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text("No activities synced yet.", style: TextStyle(fontStyle: FontStyle.italic)),
                        ),
                      ),
                  ],
                ),
              )
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (stravaService.isConnected || stravaService.status == StravaServiceStatus.syncing)
                    ? null 
                    : () => stravaService.launchStravaLogin(),
                icon: Icon(stravaService.isConnected ? Icons.check : Icons.login),
                label: Text(stravaService.isConnected ? "Successfully Connected" : "Sign in to Strava"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
