import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../icons/simple_icons.dart';
import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../models/app_hint.dart';
import '../../models/app_settings.dart';
import '../../models/service_error.dart';
import '../../models/strava/strava_activity.dart';
import '../../models/strava/strava_athlete.dart';
import '../../repositories/app_repository.dart';
import '../../services/strava_service.dart';
import '../dialogs/strava_disconnect.dart';
import '../hints/app_hint_slot.dart';
import '../hints/strava_no_gears_hint.dart';
import '../items/strava_list_tile.dart';
import '../lists/strava_gear_link_list.dart';
import '../text/sheet_section_title.dart';
import 'sheet.dart';
import 'sheet_header.dart';

const EdgeInsets _sectionPadding = EdgeInsets.symmetric(horizontal: 16);

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

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(
            title: context.l10n.stravaSheetTitle,
            leadingIcon: const Icon(SimpleIcons.strava, color: Color(0xFFFC4C02)),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: _sectionPadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        switch (stravaService.state) {
                          StravaSyncing() => _busyTile(context, label: context.l10n.stravaSyncing),
                          StravaDisconnecting() => _busyTile(context, label: context.l10n.stravaDisconnecting),
                          StravaFailed(:final failure) => StravaErrorTile(failure: failure),
                          _ => const SizedBox.shrink(),
                        },
                        const SizedBox(height: 8),

                        if (athletes.isEmpty) _emptyAthletePlaceholder(context),
                        ...athletes.map((a) => _athleteListTile(context, stravaAthletes: a)),

                        if (stravaService.isConnected)
                          _buildSyncInfoSection(context, stravaService: stravaService, appSettings: appSettings),
                      ],
                    ),
                  ),

                  if (gears.isEmpty && stravaService.isConnected) ...[
                    const Divider(),
                    const Padding(padding: _sectionPadding, child: StravaNoGearsHint()),
                  ] else if (gears.isNotEmpty) ...[
                    const Divider(),
                    Padding(
                      padding: _sectionPadding,
                      child: StravaGearLinkList(
                        gears: gears,
                        bikes: appRepository.bikes.values,
                        hint: stravaService.isConnected
                            ? const AppHintSlot(
                                placement: AppHintPlacement.stravaDashboardGear,
                                padding: EdgeInsets.only(top: 6),
                              )
                            : null,
                      ),
                    ),
                  ],

                  const Divider(),
                  Padding(
                    padding: _sectionPadding,
                    child: SheetSectionTitle(title: context.l10n.stravaLatestActivities),
                  ),
                  FutureBuilder<List<StravaActivity>>(
                    future: appRepository.latestStravaActivities,
                    builder: (context, snapshot) {
                      final latestActivities = snapshot.data ?? [];
                      if (latestActivities.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...latestActivities.map(
                              (activity) => StravaListTile(stravaActivity: activity),
                            ),
                          ],
                        );
                      } else if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
                        );
                      } else {
                        return Padding(
                          padding: _sectionPadding,
                          child: SheetFilterEmptyHint(
                            icon: Icons.directions_bike,
                            title: context.l10n.stravaNoActivitiesTitle,
                            hint: context.l10n.stravaNoActivitiesHint,
                          ),
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
                    label: Text(context.l10n.stravaDisconnectConfirm),
                  ),
                  Expanded(
                    flex: 2,
                    child: _StravaSyncButton(stravaService: stravaService),
                  ),
                  if (appSettings.developerMode)
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: stravaService.isBusy
                              ? null
                              : () => stravaService.triggerFullHistorySync(),
                          icon: stravaService.isBusy
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync),
                          label: Text(context.l10n.stravaFullSync),
                        ),
                      ),
                    ),
                ] else ...[
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: stravaService.isBusy ? null : () => stravaService.launchStravaLogin(),
                        icon: const Icon(Icons.login),
                        label: Text(context.l10n.stravaSignIn),
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
      title: Text(context.l10n.stravaNotConnected, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(context.l10n.stravaNotConnectedHint),
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
      subtitle: Text(context.l10n.stravaAthleteId(stravaAthletes.id), overflow: TextOverflow.ellipsis),
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

  Widget _buildSyncInfoSection(
    BuildContext context, {
    required StravaService stravaService,
    required AppSettings appSettings,
  }) {
    final lastFull = stravaService.lastFullSync;
    final nextFull = stravaService.nextFullSync;
    final manualAvailableAt = stravaService.manualSyncAvailableAt;

    return ListTile(
      leading: const Icon(Icons.sync_alt),
      title: Text(context.l10n.stravaAutoSyncTitle),
      subtitle: Text(context.l10n.stravaAutoSyncSubtitle),
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
          boxShadow: [
            BoxShadow(color: Theme.of(context).colorScheme.shadow, blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        richMessage: WidgetSpan(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                context.l10n.stravaSyncInfo,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                lastFull != null
                    ? context.l10n.stravaLastFullSync(
                        DateFormat(appSettings.dateFormat).format(lastFull),
                        DateFormat(appSettings.timeFormat).format(lastFull),
                      )
                    : context.l10n.stravaNoFullSync,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              if (nextFull != null)
                Text(
                  context.l10n.stravaNextScheduledSync(
                    DateFormat(appSettings.dateFormat).format(nextFull),
                    DateFormat(appSettings.timeFormat).format(nextFull),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              if (manualAvailableAt != null)
                Text(
                  context.l10n.stravaNextManualSync(
                    DateFormat(appSettings.dateFormat).format(manualAvailableAt),
                    DateFormat(appSettings.timeFormat).format(manualAvailableAt),
                  ),
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

class _StravaSyncButton extends StatefulWidget {
  final StravaService stravaService;

  const _StravaSyncButton({required this.stravaService});

  @override
  State<_StravaSyncButton> createState() => _StravaSyncButtonState();
}

class _StravaSyncButtonState extends State<_StravaSyncButton> {
  final ValueNotifier<Duration?> _remaining = ValueNotifier(null);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.stravaService.addListener(_handleServiceChanged);
    _handleServiceChanged();
  }

  @override
  void didUpdateWidget(covariant _StravaSyncButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stravaService == widget.stravaService) return;

    oldWidget.stravaService.removeListener(_handleServiceChanged);
    widget.stravaService.addListener(_handleServiceChanged);
    _handleServiceChanged();
  }

  void _handleServiceChanged() {
    _updateRemaining();

    // Service notifications mark state or sync-time changes. The local timer,
    // rather than StravaService, advances the visible countdown each second.
    final remaining = _remaining.value;
    if (remaining != null && remaining > Duration.zero && _timer == null) {
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateRemaining(),
      );
    }
  }

  void _updateRemaining() {
    final remaining = widget.stravaService.manualSyncRemaining;
    _remaining.value = remaining;

    if (remaining == null || remaining <= Duration.zero) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    widget.stravaService.removeListener(_handleServiceChanged);
    _timer?.cancel();
    _remaining.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration?>(
      valueListenable: _remaining,
      builder: (context, remaining, _) {
        final isBusy = widget.stravaService.isBusy;
        final canSync = widget.stravaService.canSyncRecent;
        final label = isBusy
            ? context.l10n.stravaSyncButtonSyncing
            : canSync
            ? context.l10n.stravaSyncButtonSync
            : context.l10n.stravaSyncButtonIn(_formatRemaining(remaining ?? Duration.zero));

        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: canSync ? widget.stravaService.triggerManualSync : null,
            icon: isBusy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1),
            ),
          ),
        );
      },
    );
  }
}

String _formatRemaining(Duration duration) {
  if (duration.inHours > 0) {
    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
  }
  if (duration.inMinutes > 0) {
    return '${duration.inMinutes} min';
  }
  final seconds = (duration.inMilliseconds / Duration.millisecondsPerSecond).ceil();
  return '${seconds}s';
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
  final StravaFailure failure;

  const StravaErrorTile({super.key, required this.failure});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return ListTile(
      leading: Icon(
        failure.kind == StravaErrorKind.noInternet ? Icons.wifi_off : Icons.error_outline,
        color: color,
      ),
      title: SelectableText(failure.message(context.l10n), style: TextStyle(color: color)),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}
