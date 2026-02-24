import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_icons/simple_icons.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/app_data.dart';
import '../../models/filtered_data.dart';
import '../../models/strava/strava_athlete.dart';
import '../../services/strava_service.dart';
import 'sheet.dart';
import '../strava_list_tile.dart';

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
    final filteredData = context.watch<FilteredData>();
    final stravaService = context.watch<StravaService>();
    final athletes = filteredData.stravaAthletes.values;
    final gears = filteredData.stravaGears.values;
    final latestActivities = filteredData.stravaActivities.values.sortedBy((a) => a.startDate).reversed.take(3);
    
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
                    
                    if (athletes.isEmpty)
                      _emptyAthletePlaceholder(context),
                    ...athletes.map((a) => _athleteListTile(context, stravaAthletes: a)),

                    if (stravaService.isConnected)
                      _buildSyncInfoSection(context, stravaService),
                    
                    if (gears.isNotEmpty) ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text("Strava Gear:", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 4,
                        runSpacing: 4,
                        children: gears.map((g) {
                          final linkedBike = filteredData.bikes.values.firstWhereOrNull((b) => b.stravaGear == g.id);
                          final unlinkedBikes = filteredData.bikes.values.where((b) => b.stravaGear == null).toList();

                          final Widget chip = Chip(
                            avatar: linkedBike == null
                                ? Icon(Icons.link_off, color: Theme.of(context).colorScheme.error)
                                : const Icon(Icons.link),
                            label: Text(g.name),
                          );

                          if (linkedBike == null && unlinkedBikes.isNotEmpty) {
                            return PopupMenuButton<Bike>(
                              tooltip: "Link to Bike",
                              onSelected: (Bike bike) {
                                final updatedBike = bike.copyWith(stravaGear: g.id);
                                context.read<AppData>().editBike(updatedBike);
                              },
                              itemBuilder: (BuildContext context) {
                                return unlinkedBikes.map((Bike bike) {
                                  return PopupMenuItem<Bike>(
                                    value: bike,
                                    child: Text("Link to '${bike.name}'"),
                                  );
                                }).toList();
                              },
                              child: chip,
                            );
                          }

                          return Tooltip(
                            triggerMode: TooltipTriggerMode.tap,
                            preferBelow: false,
                            showDuration: const Duration(seconds: 5),
                            message: linkedBike == null
                                ? "Strava Gear '${g.name}' is not linked yet. For linking, edit the Bike you want to link in the Bike tab."
                                : "Strava Gear '${g.name}' is linked to the Bike '${linkedBike.name}'",
                            child: chip,
                          );
                        }).toList(),
                      ),
                    ],
                    
                    if (latestActivities.isNotEmpty) ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text("Latest Synced Activities:", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...latestActivities.map((activity) => StravaListTile(
                        stravaActivity: activity,
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
                        onPressed: stravaService.canSyncRecent
                            ? () => stravaService.triggerManualSync()
                            : null,
                        icon: stravaService.status == StravaServiceStatus.syncing
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync),
                        label: Text(stravaService.canSyncRecent ? "Sync" : "Recently Synced"),
                      ),
                    ),
                  ),
                  // Expanded(
                  //   flex: 2,
                  //   child: SizedBox(
                  //     width: double.infinity,
                  //     child: FilledButton.icon(
                  //       onPressed: stravaService.status == StravaServiceStatus.syncing
                  //           ? null
                  //           : () => stravaService.triggerFullHistorySync(),
                  //       icon: stravaService.status == StravaServiceStatus.syncing
                  //           ? const SizedBox(
                  //               height: 16,
                  //               width: 16,
                  //               child: CircularProgressIndicator(strokeWidth: 2),
                  //             )
                  //           : const Icon(Icons.sync),
                  //       label: const Text("Full Sync"),
                  //     ),
                  //   ),
                  // ),
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

  Widget _emptyAthletePlaceholder(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Icon(Icons.person_off, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      title: Text("Not connected", style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text("Connect to sync your rides"),
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
    );
  }

  Widget _athleteListTile(BuildContext context, {required StravaAthlete stravaAthletes}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.transparent, 
        foregroundImage: stravaAthletes.profile == null 
            ? null 
            : NetworkImage(stravaAthletes.profile!), 
        child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      title: Text(
        "${stravaAthletes.firstname} ${stravaAthletes.lastname}", 
        style: const TextStyle(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text("Athlete ID: ${stravaAthletes.id}", overflow: TextOverflow.ellipsis),
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
    );
  }

  Widget _buildSyncInfoSection(BuildContext context, StravaService stravaService) {
    final appSettings = context.watch<AppSettings>();
    final lastFull = stravaService.lastFullSync;
    final nextFull = stravaService.nextFullSync;
    final manualAvailableAt = stravaService.manualSyncAvailableAt;

    return ListTile(
      leading: const Icon(Icons.sync_alt),
      title: const Text("Auto-sync is active"),
      subtitle: const Text("Activities import automatically after your ride."),
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
              Text("Bike Setup Tracker automatically imports new, updated, or deleted Strava activities in real-time. "
                  "While most updates are instant, a full background sync also runs weekly to catch any missed changes. "
                  "You can also trigger a manual sync once a week.", 
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary,
                  )),
              const SizedBox(height: 6),
              Text(
                lastFull != null
                    ? "Last full sync: ${DateFormat(appSettings.dateFormat).format(lastFull)} ${DateFormat(appSettings.timeFormat).format(lastFull)}"
                    : "No full sync yet",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              if (nextFull != null)
                Text(
                  "Next scheduled sync: ${DateFormat(appSettings.dateFormat).format(nextFull)} ${DateFormat(appSettings.timeFormat).format(nextFull)}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              if (manualAvailableAt != null)
                Text(
                  "Next Manual sync available: ${DateFormat(appSettings.dateFormat).format(manualAvailableAt)} ${DateFormat(appSettings.timeFormat).format(manualAvailableAt)}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
            ],
          ),
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
