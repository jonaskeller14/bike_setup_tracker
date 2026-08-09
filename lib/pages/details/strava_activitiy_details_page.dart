import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/setup.dart';
import '../../models/strava/strava_activity.dart';
import '../../repositories/app_repository.dart';
import '../../services/strava_service.dart';
import '../../widgets/items/component_list_card.dart';
import '../../widgets/items/setup_list_tile.dart';
import '../../widgets/sheets/sheet.dart';
import '../setup_page.dart';

class StravaActivityDetailsPage extends StatelessWidget {
  final StravaActivity stravaActivity;

  const StravaActivityDetailsPage({super.key, required this.stravaActivity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Activity"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: "View on Strava",
            onPressed: () => StravaService.openActivityOnStrava(stravaActivity.id),
          ),
        ],
      ),
      body: SafeArea(child: StravaActivitiyPageContent(stravaActivity: stravaActivity)),
    );
  }
}

class StravaActivitiyPageContent extends StatelessWidget {
  final StravaActivity stravaActivity;
  final bool showCloseButton;
  final VoidCallback? onMapPressed;

  const StravaActivitiyPageContent({
    super.key,
    required this.stravaActivity,
    this.showCloseButton = false,
    this.onMapPressed,
  });

  String _formatDistance(double? meters, String distanceUnit) {
    if (meters == null) return "-";
    final value = AppSettings.convertDistanceFromMeters(meters, distanceUnit)!;
    return "${value.toStringAsFixed(2)} $distanceUnit";
  }

  String _formatElevation(double? meters, String altitudeUnit) {
    if (meters == null) return "-";
    final value = AppSettings.convertElevationFromMeters(meters, altitudeUnit)!;
    return "${value.round()} $altitudeUnit";
  }

  String _formatSpeed(double? meters, Duration duration, String distanceUnit) {
    if (meters == null || duration.inSeconds == 0) return "-";
    final dist = AppSettings.convertDistanceFromMeters(meters, distanceUnit)!;
    final hours = duration.inSeconds / 3600;
    return "${(dist / hours).toStringAsFixed(1)} ${AppSettings.speedUnitForDistance(distanceUnit)}";
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
                    athlete != null ? "${athlete.firstname ?? ""} ${athlete.lastname ?? ""}".trim() : "Strava Athlete",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${DateFormat(appSettings.dateFormat).format(stravaActivity.startDateLocal)} • ${DateFormat(appSettings.timeFormat).format(stravaActivity.startDateLocal)}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (onMapPressed != null) ...[
                const SizedBox(width: 8),
                sheetMapButton(context, onPressed: onMapPressed!),
              ],
              if (showCloseButton) ...[
                const SizedBox(width: 8),
                sheetCloseButton(context),
              ],
              if (onMapPressed != null || showCloseButton) const SizedBox(width: 16),
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
                          stravaActivity.sportType.label,
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
                            stravaActivity.workout.label,
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
                _statWidget(context, "Distance", _formatDistance(stravaActivity.distance, appSettings.distanceUnit)),
                _statWidget(context, "Elev Gain", _formatElevation(stravaActivity.totalElevationGain, appSettings.altitudeUnit)),
                _statWidget(context, "Avg Speed", _formatSpeed(stravaActivity.distance, stravaActivity.movingTime, appSettings.distanceUnit)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _statWidget(context, "Moving Time", _formatDuration(stravaActivity.movingTime)),
                _statWidget(context, "Elapsed Time", _formatDuration(stravaActivity.elapsedTime)),
                const Expanded(child: SizedBox()), // Placeholder for alignment
              ],
            ),
          ),
          
          const Divider(height: 1),
          if (stravaGear != null) ...[
            Builder(
              builder: (context) {
                final linkedBike = appRepository.bikes.values.where((b) => b.stravaGear == stravaGear.id).firstOrNull;
                final activityTimeUtc = stravaActivity.startDateLocal.toUtc();
                final installedComponents = appRepository.components.values
                    .where((c) => linkedBike != null && c.bikeAt(activityTimeUtc) == linkedBike.id)
                    .toList();
                final bool enabled = installedComponents.isNotEmpty;
                final Color disabledColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38);
                return ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  leading: Icon(Icons.pedal_bike, color: enabled ? null : disabledColor),
                  title: Text(
                    linkedBike?.name ?? "No bike linked to this Strava gear",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: enabled ? null : disabledColor,
                    ),
                  ),
                  subtitle: Text(
                    stravaGear.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: enabled
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : disabledColor,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  enabled: enabled,
                  children: installedComponents
                        .map(
                          (c) => ComponentListCard(
                            component: c,
                            showCurrentAdjustmentValues: false,
                          ),
                        )
                      .toList(),
                );
              },
            ),
            const Divider(height: 1),
            
            // Add Setups related to this activity
            Builder(
              builder: (context) {
                final allSetupsForGear = appRepository.filteredSetups.values
                    .where((s) => appRepository.bikes[s.bike]?.stravaGear == stravaGear.id)
                    .toList();
                
                // Setups added after activity started, but before it ended
                final activityEnd = stravaActivity.startDateLocal.add(stravaActivity.elapsedTime);
                final setupsDuringActivity = allSetupsForGear
                    .where(
                      (s) =>
                  s.datetimeLocal.isAfter(stravaActivity.startDateLocal) &&
                          s.datetimeLocal.isBefore(activityEnd),
                    )
                    .toList();

                // Setup active at the start of the activity (latest one before/on start)
                final setupsBeforeOrOnStart = allSetupsForGear
                    .where(
                      (s) =>
                  s.datetimeLocal.isBefore(stravaActivity.startDateLocal) || 
                          s.datetimeLocal.isAtSameMomentAs(stravaActivity.startDateLocal),
                    )
                    .toList();
                setupsBeforeOrOnStart.sort((a, b) => b.datetimeLocal.compareTo(a.datetimeLocal));
                
                final List<Setup> relevantSetups = [];
                if (setupsBeforeOrOnStart.isNotEmpty) {
                  relevantSetups.add(setupsBeforeOrOnStart.first); // active setup
                }
                relevantSetups.addAll(setupsDuringActivity);

                // Filter out duplicates (just in case) and sort chronologically
                final uniqueSetups = relevantSetups.toSet().toList();
                uniqueSetups.sort((a, b) => b.datetimeLocal.compareTo(a.datetimeLocal));

                return ExpansionTile(
                  leading: const Icon(Setup.iconData),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  initiallyExpanded: false,
                  title: Text(
                    "Setups (${uniqueSetups.length})",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  childrenPadding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ...uniqueSetups.map((setup) {
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        // Rounds the InkWell and the current-setup bar.
                        clipBehavior: Clip.antiAlias,
                        child: SetupListTile(
                          setupId: setup.id,
                          displayBikeAdjustmentValues: true,
                          displayPersonAdjustmentValues: true,
                          onTap: null,
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
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
                            await appRepository.addSetup(result);
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Add Setup"),
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
}
