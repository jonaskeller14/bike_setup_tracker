import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/entity_names.dart';
import '../../l10n/enum_labels.dart';
import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/component/component.dart';
import '../../models/feedback/ride_feedback.dart';
import '../../models/setup.dart';
import '../../models/strava/activity_timeline.dart';
import '../../models/strava/strava_activity.dart';
import '../../repositories/app_repository.dart';
import '../../services/strava_service.dart';
import '../../utils/automation_ids.dart';
import '../../utils/component_actions.dart';
import '../../utils/feedback_actions.dart';
import '../../utils/localized_number.dart';
import '../../utils/map_actions.dart';
import '../../utils/url.dart';
import '../../widgets/empty_state_placeholder.dart';
import '../../widgets/empty_state_placeholder2.dart';
import '../../widgets/feedback/strava_feedback_prompt.dart';
import '../../widgets/items/component_list_card.dart';
import '../../widgets/sheets/sheet.dart';
import '../../widgets/strava_activity_timeline.dart';
import '../forms/setup_page.dart';

class StravaActivityDetailsPage extends StatefulWidget {
  final int activityId;

  const StravaActivityDetailsPage({super.key, required this.activityId});

  @override
  State<StravaActivityDetailsPage> createState() => _StravaActivityDetailsPageState();
}

class _StravaActivityDetailsPageState extends State<StravaActivityDetailsPage> {
  late final Stream<StravaActivity?> _activityStream;
  late final StravaActivity? _initialActivity;

  @override
  void initState() {
    super.initState();
    final appRepository = context.read<AppRepository>();
    _activityStream = appRepository.watchStravaActivity(widget.activityId);
    _initialActivity = appRepository.stravaActivities[widget.activityId];
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StravaActivity?>(
      stream: _activityStream,
      initialData: _initialActivity,
      builder: (context, snapshot) {
        final stravaActivity = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.stravaActivityTitle),
            centerTitle: true,
            actions: [
              if (stravaActivity != null)
                Semantics(
                  container: true,
                  identifier: AutomationIds.stravaActivityActions,
                  child: StravaActivityActionsMenu(stravaActivity: stravaActivity),
                ),
            ],
          ),
          body: SafeArea(
            child: switch (snapshot) {
              _ when stravaActivity != null => StravaActivityPageContent(stravaActivity: stravaActivity),
              AsyncSnapshot(hasError: true) => EmptyStatePlaceholder.error(title: context.l10n.stravaActivityLoadErrorTitle),
              AsyncSnapshot(connectionState: ConnectionState.waiting) => const Center(child: CircularProgressIndicator()),
              _ => EmptyStatePlaceholder.error(
                title: context.l10n.stravaActivityNotFoundTitle,
                subtitle: context.l10n.stravaActivityNotFoundSubtitle,
              ),
            },
          ),
        );
      },
    );
  }
}

class StravaActivityPageContent extends StatelessWidget {
  final StravaActivity stravaActivity;
  final bool showCloseButton;
  final bool showSheetActions;
  final bool showViewOnMap;

  const StravaActivityPageContent({
    super.key,
    required this.stravaActivity,
    this.showCloseButton = false,
    this.showSheetActions = false,
    this.showViewOnMap = true,
  });

  String _formatDistance(double? meters, String distanceUnit, String locale) {
    if (meters == null) return "-";
    final value = AppSettings.convertDistanceFromMeters(meters, distanceUnit)!;
    return "${formatLocalizedDouble(value, fractionDigits: 2, locale: locale)} $distanceUnit";
  }

  String _formatElevation(double? meters, String altitudeUnit) {
    if (meters == null) return "-";
    final value = AppSettings.convertElevationFromMeters(meters, altitudeUnit)!;
    return "${value.round()} $altitudeUnit";
  }

  String _formatSpeed(double? meters, Duration duration, String distanceUnit, String locale) {
    if (meters == null || duration.inSeconds == 0) return "-";
    final dist = AppSettings.convertDistanceFromMeters(meters, distanceUnit)!;
    final hours = duration.inSeconds / 3600;
    return "${formatLocalizedDouble(dist / hours, fractionDigits: 1, locale: locale)} ${AppSettings.speedUnitForDistance(distanceUnit)}";
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "${duration.inMinutes}:$twoDigitSeconds";
    }
  }

  Widget _statWidget(BuildContext context, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w400,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();
    final stravaGear = appRepository.stravaGears[stravaActivity.gearId];
    final athlete = appRepository.stravaAthletes[stravaActivity.athlete];
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    foregroundImage: athlete?.profile != null && athlete!.profile!.startsWith("http")
                        ? NetworkImage(athlete.profile!)
                        : null,
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  title: Text(
                    athlete != null ? "${athlete.firstname ?? ""} ${athlete.lastname ?? ""}".trim() : context.l10n.stravaActivityAthleteFallback,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${DateFormat(appSettings.dateFormat, context.l10n.localeName).format(stravaActivity.startDateLocal)} • ${DateFormat(appSettings.timeFormat, context.l10n.localeName).format(stravaActivity.startDateLocal)}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (showSheetActions) ...[
                const SizedBox(width: 8),
                StravaActivityActionsMenu(stravaActivity: stravaActivity, showViewOnMap: showViewOnMap, filled: true),
              ],
              if (showCloseButton) ...[
                const SizedBox(width: 8),
                sheetCloseButton(context),
              ],
              if (showSheetActions || showCloseButton) const SizedBox(width: 16),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stravaActivity.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          stravaActivity.sportType.getIconData(),
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          stravaActivity.sportType.label(context.l10n),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (stravaActivity.workout.isNotable)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            stravaActivity.workout.icon,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            stravaActivity.workout.label(context.l10n),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _statWidget(context, context.l10n.initialStatsDistance, _formatDistance(stravaActivity.distance, appSettings.distanceUnit, context.l10n.localeName)),
                _statWidget(context, context.l10n.stravaActivityElevGain, _formatElevation(stravaActivity.totalElevationGain, appSettings.altitudeUnit)),
                _statWidget(context, context.l10n.stravaActivityAvgSpeed, _formatSpeed(stravaActivity.distance, stravaActivity.movingTime, appSettings.distanceUnit, context.l10n.localeName)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _statWidget(context, context.l10n.initialStatsMovingTime, _formatDuration(stravaActivity.movingTime)),
                _statWidget(context, context.l10n.initialStatsElapsedTime, _formatDuration(stravaActivity.elapsedTime)),
                _PowerStatTile(averageWatts: stravaActivity.averageWatts, kilojoules: stravaActivity.kilojoules),
              ],
            ),
          ),
          
          StravaFeedbackPrompt(stravaActivity: stravaActivity),
          const Divider(height: 1),
          if (stravaGear != null) ...[
            Builder(
              builder: (context) {
                final linkedBike = appRepository.bikes.values.where((b) => b.stravaGear == stravaGear.id).firstOrNull;
                final activityTimeUtc = stravaActivity.startDateLocal.toUtc();
                final installedComponents = appRepository.components.values
                    .where((c) => linkedBike != null && appRepository.componentHierarchy.bikeAt(c.id, activityTimeUtc) == linkedBike.id)
                    .toList();
                final unlinkedBikes = appRepository.bikes.values.where((bike) => bike.stravaGear == null).toList();
                return ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  leading: const Icon(Icons.pedal_bike),
                  title: Text(
                    linkedBike?.name ?? context.l10n.stravaActivityNoBikeLinked,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    stravaGear.name,
                  ),
                  childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  children: [
                    if (linkedBike == null) ...[
                      EmptyStatePlaceholder2(
                        iconData: Icons.pedal_bike,
                        title: context.l10n.stravaActivityNoBikeLinked,
                        subtitle: unlinkedBikes.isEmpty
                            ? context.l10n.stravaActivityAddBikeHint
                            : context.l10n.stravaActivityLinkBikeHint,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        spacing: 8,
                        children: [
                          if (unlinkedBikes.isNotEmpty)
                            Expanded(
                              child: MenuAnchor(
                                menuChildren: unlinkedBikes
                                    .map(
                                      (bike) => MenuItemButton(
                                        onPressed: () => appRepository.editBikes([
                                          bike.copyWith(stravaGear: stravaGear.id),
                                        ]),
                                        child: Text(
                                          bike.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                builder: (context, controller, child) => FilledButton.icon(
                                  onPressed: controller.open,
                                  icon: const Icon(Icons.link),
                                  label: Text(context.l10n.stravaActivityLinkBike),
                                ),
                              ),
                            ),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => appRepository.addBikes(
                                [Bike(name: stravaGear.name, person: appRepository.persons.values.firstOrNull?.id, stravaGear: stravaGear.id)],
                              ),
                              icon: const Icon(Icons.add),
                              label: Text(context.l10n.stravaActivityAddNew),
                            ),
                          ),
                        ],
                      ),
                    ] else if (installedComponents.isEmpty) ...[
                      EmptyStatePlaceholder2(
                        iconData: Component.iconData,
                        title: context.l10n.noComponentsTitle,
                        subtitle: context.l10n.bikeDetailsNoComponentsSubtitle,
                        onTap: () => ComponentActions.addComponent(context, initialBike: linkedBike.id)
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => ComponentActions.addComponent(context, initialBike: linkedBike.id),
                          icon: const Icon(Icons.add),
                          label: Text(context.l10n.addComponent),
                        ),
                      ),
                    ] else ...[
                      ...installedComponents.map(
                        (c) => ComponentListCard(
                          component: c,
                          showCurrentAdjustmentValues: false,
                        ),
                      ),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => ComponentActions.addComponent(context, initialBike: linkedBike.id),
                          icon: const Icon(Icons.add),
                          label: Text(context.l10n.addComponent),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            const Divider(height: 1),
            
            // Add Setups related to this activity
            Builder(
              builder: (context) {
                final feedbacks = appSettings.enableRating
                    ? appRepository.feedbacksForActivity(stravaActivity)
                    : const <RideFeedback>[];
                final timeline = ActivityTimeline.of(
                  stravaActivity,
                  setups: appRepository.setups.values.where((s) => appRepository.bikes[s.bike]?.stravaGear == stravaGear.id),
                  feedbacks: feedbacks,
                );

                // A setup recorded now would land between the runs of a session.
                final linkedBike = appRepository.bikes.values.where((b) => b.stravaGear == stravaGear.id).firstOrNull;
                final running = linkedBike == null ? null : appRepository.runningSessionFor(linkedBike.id);
                final VoidCallback? addSetup = running == null ? () => _addSetup(context, appRepository) : null;
                final runningHint = running == null
                    ? null
                    : context.l10n.stravaActivitySessionRunning(running.label(context.l10n));

                return ExpansionTile(
                  leading: const Icon(Setup.iconData),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  initiallyExpanded: false,
                  title: Semantics(
                    identifier: AutomationIds.stravaActivitySetups,
                    child: Text(
                      context.l10n.stravaActivitySetupsTitle(timeline.setupCount),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  subtitle: feedbacks.isEmpty
                      ? null
                      : Text(context.l10n.stravaActivityFeedbackCount(feedbacks.length)),
                  childrenPadding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: StravaActivityTimeline(timeline: timeline, onAddSetup: addSetup, addSetupHint: runningHint),
                    ),
                    Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: addSetup,
                            icon: const Icon(Icons.add),
                            label: Text(context.l10n.homeAddSetup),
                          ),
                          if (appSettings.enableRating)
                            TextButton.icon(
                              onPressed: () => unawaited(
                                FeedbackActions.addFeedbackFromStravaActivity(context, stravaActivity: stravaActivity),
                              ),
                              icon: const Icon(Icons.add),
                              label: Text(context.l10n.setupOptionAddFeedback),
                            ),
                        ],
                      ),
                    if (runningHint != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          runningHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
                        ),
                      ),
                  ],
                );
              },
            ),
            const Divider(height: 1),
          ],
          
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/strava/1.2-Strava-API-Logos/1.2-Strava-API-Logos/Powered by Strava/pwrdBy_strava_orange/api_logo_pwrdBy_strava_stack_orange.png',
                  height: 50,
                ),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => StravaService.openActivityOnStrava(stravaActivity.id),
                  icon: const Icon(Icons.open_in_new, size: 16, color: Color(0xFFFC5200)),
                  label: const Text(
                    "VIEW ON STRAVA",
                    style: TextStyle(
                      color: Color(0xFFFC5200),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24 + MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Future<void> _addSetup(BuildContext context, AppRepository appRepository) async {
    final result = await Navigator.push<Setup>(
      context,
      MaterialPageRoute<Setup>(
        builder: (context) => SetupPage.addFromStravaActivity(
          context: context,
          stravaActivity: stravaActivity,
        ),
      ),
    );
    if (result is Setup) {
      await appRepository.addSetups([result]);
    }
  }
}

/// Map and Strava links for an activity. The map entries stay listed but
/// disabled when the activity has no start position, so the reason is visible.
class StravaActivityActionsMenu extends StatelessWidget {
  final StravaActivity stravaActivity;
  final bool showViewOnMap;
  final bool filled;

  const StravaActivityActionsMenu({
    super.key,
    required this.stravaActivity,
    this.showViewOnMap = true,
    this.filled = false,
  });

  Future<void> _onSelected(BuildContext context, _StravaActivityAction action) async {
    switch (action) {
      case _StravaActivityAction.viewOnMap:
        await MapActions.openActivityOnMap(context, stravaActivity);
      case _StravaActivityAction.openInMapsApp:
        await launchLocationOnMap(context, stravaActivity.startLat!, stravaActivity.startLon!, stravaActivity.name);
      case _StravaActivityAction.viewOnStrava:
        StravaService.openActivityOnStrava(stravaActivity.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasStartPosition = stravaActivity.hasStartPosition;
    final actions = <_StravaActivityAction>[
      if (showViewOnMap) _StravaActivityAction.viewOnMap,
      _StravaActivityAction.openInMapsApp,
      _StravaActivityAction.viewOnStrava,
    ];
    return PopupMenuButton<_StravaActivityAction>(
      tooltip: context.l10n.stravaActivityActionsTooltip,
      onSelected: (action) => _onSelected(context, action),
      itemBuilder: (context) => [
        for (final action in actions)
          PopupMenuItem(
            value: action,
            enabled: hasStartPosition || !action.needsStartPosition,
            child: Row(
              spacing: 10,
              children: [
                Icon(action.icon),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        identifier: action == _StravaActivityAction.viewOnMap ? AutomationIds.stravaActivityViewOnMap : null,
                        child: Text(action.label(context.l10n)),
                      ),
                      if (!hasStartPosition && action.needsStartPosition)
                        Text(
                          context.l10n.stravaActivityNoStartLocation,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
      child: filled
          ? AbsorbPointer(
              child: IconButton.filled(
                iconSize: 20,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {},
                icon: const Icon(Icons.more_vert),
              ),
            )
          : null,
    );
  }
}

enum _StravaActivityAction {
  viewOnMap(Icons.map, needsStartPosition: true),
  openInMapsApp(Icons.directions, needsStartPosition: true),
  viewOnStrava(Icons.open_in_new, needsStartPosition: false);

  final IconData icon;
  final bool needsStartPosition;

  const _StravaActivityAction(this.icon, {required this.needsStartPosition});

  /// "View on Strava" stays as Strava's brand guidelines word it.
  String label(AppLocalizations l10n) => switch (this) {
    viewOnMap => l10n.setupOptionViewOnMap,
    openInMapsApp => l10n.setupOptionOpenInMaps,
    viewOnStrava => 'View on Strava',
  };
}

class _PowerStatTile extends StatefulWidget {
  final double? averageWatts;
  final double? kilojoules;

  const _PowerStatTile({required this.averageWatts, required this.kilojoules});

  @override
  State<_PowerStatTile> createState() => _PowerStatTileState();
}

class _PowerStatTileState extends State<_PowerStatTile> {
  bool _showKilojoules = false;

  String _formatPower(double? watts) {
    if (watts == null) return "-";
    return "${watts.round()} W";
  }

  String _formatKilojoules(double? kilojoules) {
    if (kilojoules == null) return "-";
    return "${kilojoules.round()} kJ";
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          setState(() => _showKilojoules = !_showKilojoules);
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _showKilojoules ? context.l10n.stravaActivityEnergy : context.l10n.stravaActivityAvgPower,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _showKilojoules ? _formatKilojoules(widget.kilojoules) : _formatPower(widget.averageWatts),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
