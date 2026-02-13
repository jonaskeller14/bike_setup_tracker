import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import '../../models/app_data.dart';
import '../../models/app_settings.dart';
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
    final appSettings = context.read<AppSettings>();
    final appData = context.watch<AppData>();
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
                    Icon(SimpleIcons.strava, color: const Color(0xFFFC4C02)), // Strava Brand Orange
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
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: stravaService.isConnected
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.surfaceContainerHigh,
                        child: Icon(
                          stravaService.isConnected ? Icons.person : Icons.person_off,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      title: Text(
                        stravaService.isConnected ? "Strava User" : "Not connected",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        stravaService.isConnected 
                            ? "Athlete ID: ${stravaService.userId?.substring(0, 8)}..." 
                            : "Connect to sync your rides",
                      ),
                      trailing: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 48,
                          maxWidth: 80,
                        ),
                        child: Image.asset(
                          'assets/strava/1.2-Strava-API-Logos/1.2-Strava-API-Logos/Powered by Strava/pwrdBy_strava_orange/api_logo_pwrdBy_strava_stack_orange.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (stravaService.isConnected) ...[
                      ListTile(
                        leading: const Icon(Icons.sync_alt),
                        title: Text("Auto-sync is active"),
                        subtitle: const Text("Activities import automatically after your ride"),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (appData.stravaActivities.isNotEmpty) ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text("Synced Activities:", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...appData.stravaActivities.values.map((activity) => ListTile(
                            title: Text(activity.name),
                            subtitle: Text(activity.sportType),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("${DateFormat(appSettings.dateFormat).format(activity.startDate)} • ${DateFormat(appSettings.timeFormat).format(activity.startDate)}"),
                                GestureDetector(
                                  onTap: () => StravaService.openActivityOnStrava(activity.id),
                                  child: const Text(
                                    "View on Strava",
                                    style: TextStyle(
                                      color: Color(0xFFFC5200),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 16,
              children: [
                if (stravaService.isConnected) ...[
                  OutlinedButton.icon(
                    onPressed: stravaService.status == StravaServiceStatus.syncing 
                        ? null 
                        : () => _showDisconnectConfirmation(context, stravaService),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(color: Theme.of(context).colorScheme.error),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text("Disconnect"),
                  ),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: stravaService.status == StravaServiceStatus.syncing
                            ? null
                            : () => stravaService.triggerManualSync(),
                        icon: stravaService.status == StravaServiceStatus.syncing
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync),
                        label: const Text("Sync"),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: stravaService.status == StravaServiceStatus.syncing
                            ? null
                            : () => stravaService.launchStravaLogin(),
                        icon: const Icon(Icons.login),
                        label: const Text("Sign in to Strava"),
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

  void _showDisconnectConfirmation(BuildContext context, StravaService stravaService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Disconnect Strava?"),
        content: const Text(
          "This will revoke the app's access and delete all your synced activities from our secure storage. "
          "Your Strava account itself will not be affected."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              stravaService.disconnect();
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text("Disconnect"),
          ),
        ],
      ),
    );
  }
}
