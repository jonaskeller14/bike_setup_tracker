import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../icons/simple_icons.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/strava/strava_activity.dart';
import '../../models/strava/strava_athlete.dart';
import '../../repositories/app_repository.dart';
import '../../services/strava_service.dart';
import '../dialogs/strava_disconnect.dart';
import '../hints/strava_gear_link_hint.dart';
import '../hints/strava_no_gears_hint.dart';
import '../items/strava_list_tile.dart';
import '../text/sheet_section_title.dart';
import 'sheet.dart';
import 'sheet_header.dart';

class StravaDashboardSheet extends StatefulWidget {
  const StravaDashboardSheet({super.key});

  @override
  State<StravaDashboardSheet> createState() => _StravaDashboardSheetState();
}

class _StravaDashboardSheetState extends State<StravaDashboardSheet> {
  final GlobalKey<TooltipState> _syncInfoTooltipKey = GlobalKey<TooltipState>();

  @override
  Widget build(BuildContext context) {
    final appRepository = context.watch<AppRepository>();
    final appSettings = context.watch<AppSettings>();
    final stravaService = context.watch<StravaService>();
    final athletes = appRepository.stravaAthletes.values;
    final gears = appRepository.stravaGears.values;
    final hasUnlinkedGears = gears.any(
      (g) => appRepository.bikes.values.every((b) => b.stravaGear != g.id),
    );
    
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHeader(
            title: 'Strava Sync',
            leadingIcon: Icon(SimpleIcons.strava, color: Color(0xFFFC4C02)),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  switch (stravaService.state) {
                    StravaSyncing() => _busyTile(context, label: "Syncing..."),
                    StravaDisconnecting() => _busyTile(context, label: "Disconnecting..."),
                    StravaFailed(:final message) => StravaErrorTile(message: message),
                    _ => const SizedBox.shrink(),
                  },
                  const SizedBox(height: 8),
                  
                  if (athletes.isEmpty)
                    _emptyAthletePlaceholder(context),
                  ...athletes.map((a) => _athleteListTile(context, stravaAthletes: a)),

                  if (stravaService.isConnected)
                    _buildSyncInfoSection(context, stravaService: stravaService, appSettings: appSettings),
                  
                  if (gears.isEmpty && stravaService.isConnected) ...[
                    const Divider(),
                    const StravaNoGearsHint(),
                  ] else if (gears.isNotEmpty) ...[
                    const Divider(),
                    const SheetSectionTitle(title: "Strava Gear:"),
                    if (hasUnlinkedGears && appSettings.showStravaLinkGearHint) ...[
                      const StravaGearLinkHint(),
                      const SizedBox(height: 4),
                    ],
                    Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 4,
                      children: gears.map((g) {
                        final linkedBikes = appRepository.bikes.values.where((b) => b.stravaGear == g.id);
                        final unlinkedBikes = appRepository.bikes.values.where((b) => b.stravaGear == null).toList();

                        final Widget chip = Chip(
                          avatar: linkedBikes.isEmpty
                              ? Icon(Icons.link_off, color: Theme.of(context).colorScheme.error)
                              : const Icon(Icons.link),
                          label: Text(g.name),
                        );

                        return PopupMenuButton<_StravaGearMenuOption>(
                          tooltip: "Bike Options",
                          onSelected: (_StravaGearMenuOption option) async {
                            switch (option) {
                              case _LinkToBike():
                                final updatedBike = option.bike.copyWith(stravaGear: g.id);
                                await context.read<AppRepository>().editBike(updatedBike);
                              case _AddNewBike():
                                final newBike = Bike(
                                  name: g.name,
                                  person: null,
                                  stravaGear: g.id,
                                );
                                await context.read<AppRepository>().addBike(newBike);
                              case _UnlinkBike():
                                final updatedBike = option.bike.copyWith(stravaGear: null);
                                await context.read<AppRepository>().editBike(updatedBike);
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              if (linkedBikes.isNotEmpty) ...[
                                ...linkedBikes.map((Bike linkedBike) {
                                  return PopupMenuItem<_StravaGearMenuOption>(
                                    value: _UnlinkBike(linkedBike),
                                    child: Row(
                                      spacing: 8,
                                      children: [
                                        const Icon(Icons.link_off),
                                        Expanded(child: Text("Unlink Bike '${linkedBike.name}'", overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                  );
                                })
                              ]
                              else ... [
                                if (unlinkedBikes.isNotEmpty) ...[
                                  ...unlinkedBikes.map((Bike bike) {
                                    return PopupMenuItem<_StravaGearMenuOption>(
                                      value: _LinkToBike(bike),
                                      child: Row(
                                        spacing: 8,
                                        children: [
                                          const Icon(Icons.link),
                                          Expanded(child: Text("Link to '${bike.name}'", overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                    );
                                  }),
                                  const PopupMenuDivider(),
                                ],
                                const PopupMenuItem<_StravaGearMenuOption>(
                                  value: _AddNewBike(),
                                  child: Row(
                                    spacing: 8,
                                    children: [
                                      Icon(Icons.add),
                                      Text("Add as new Bike"),
                                    ],
                                  ),
                                ),
                              ]
                            ];
                          },
                          child: chip,
                        );
                      }).toList(),
                    ),
                  ],
                  
                  FutureBuilder<List<StravaActivity>>(
                    future: appRepository.latestStravaActivities,
                    builder: (context, snapshot) {
                      final latestActivities = snapshot.data ?? [];
                      if (latestActivities.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const SheetSectionTitle(title: "Latest Synced Activities:"),
                            ...latestActivities.map((activity) => StravaListTile(
                              stravaActivity: activity,
                              contentPadding: EdgeInsets.zero,
                            )),
                          ],
                        );
                      } else if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                      } else {
                        return const SheetFilterEmptyHint(
                          icon: Icons.directions_bike,
                          title: "No activities synced yet.",
                          hint: "Connect Strava and sync your rides to see activities here.",
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 16,
              children: [
                if (stravaService.isConnected) ...[
                  OutlinedButton.icon(
                    onPressed: stravaService.isBusy
                        ? null
                        : () async {
                            final confirmed = await showStravaDisconnectDialog(context);
                            if (confirmed) await stravaService.disconnect();
                          },
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
                        icon: stravaService.isBusy
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync),
                        label: Text(
                          stravaService.isBusy
                              ? "Syncing"
                              : stravaService.canSyncRecent
                                  ? "Sync"
                                  : "Recently Synced",
                        ),
                      ),
                    ),
                  ),
                  // Expanded(
                  //   flex: 2,
                  //   child: SizedBox(
                  //     width: double.infinity,
                  //     child: FilledButton.icon(
                  //       onPressed: stravaService.isBusy
                  //           ? null
                  //           : () => stravaService.triggerFullHistorySync(),
                  //       icon: stravaService.isBusy
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
                        onPressed: stravaService.isBusy
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
      title: const Text("Not connected", style: TextStyle(fontWeight: FontWeight.bold)),
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
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundImage: (stravaAthletes.profile != null && stravaAthletes.profile!.startsWith('http'))
            ? NetworkImage(stravaAthletes.profile!)
            : null,
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

  Widget _buildSyncInfoSection(BuildContext context, {required StravaService stravaService, required AppSettings appSettings}) {
    final lastFull = stravaService.lastFullSync;
    final nextFull = stravaService.nextFullSync;
    final manualAvailableAt = stravaService.manualSyncAvailableAt;

    return ListTile(
      leading: const Icon(Icons.sync_alt),
      title: const Text("Auto-sync is active"),
      subtitle: const Text("Activities import automatically after your ride."),
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: () => _syncInfoTooltipKey.currentState?.ensureTooltipVisible(),
      trailing: Tooltip(
        key: _syncInfoTooltipKey,
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
                  "You can also trigger a manual sync once per hour.",
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

Widget _busyTile(BuildContext context, {required String label}) {
  return ListTile(
    leading: const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    ),
    title: Text(label),
    dense: true,
    contentPadding: EdgeInsets.zero,
  );
}

class StravaErrorTile extends StatelessWidget {
  final String message;

  const StravaErrorTile({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return ListTile(
      leading: Icon(
        message.startsWith("No internet") ? Icons.wifi_off : Icons.error_outline,
        color: color,
      ),
      title: SelectableText(message, style: TextStyle(color: color)),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}

sealed class _StravaGearMenuOption {
  const _StravaGearMenuOption();
}

class _LinkToBike extends _StravaGearMenuOption {
  final Bike bike;
  const _LinkToBike(this.bike);
}

class _AddNewBike extends _StravaGearMenuOption {
  const _AddNewBike();
}
class _UnlinkBike extends _StravaGearMenuOption {
  final Bike bike;
  const _UnlinkBike(this.bike);
}

