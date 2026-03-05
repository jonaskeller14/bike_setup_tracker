import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/filtered_data.dart';
import '../models/strava/strava_activity.dart';
import '../models/setup.dart';
import '../services/strava_service.dart';
import '../widgets/setup_list_card.dart';

class StravaActivityPage extends StatelessWidget {
  final StravaActivity stravaActivity;

  const StravaActivityPage({super.key, required this.stravaActivity});

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
      body: StravaActivitiyPageContent(stravaActivity: stravaActivity),
    );
  }
}

class StravaActivitiyPageContent extends StatelessWidget {
  final StravaActivity stravaActivity;

  const StravaActivitiyPageContent({super.key, required this.stravaActivity});

  String _formatDistance(double? meters) {
    if (meters == null) return "-";
    return "${(meters / 1000).toStringAsFixed(2)} km";
  }

  String _formatElevation(double? meters) {
    if (meters == null) return "-";
    return "${meters.round()} m";
  }

  String _formatSpeed(double? meters, Duration duration) {
    if (meters == null || duration.inSeconds == 0) return "-";
    final km = meters / 1000;
    final hours = duration.inSeconds / 3600;
    return "${(km / hours).toStringAsFixed(1)} km/h";
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
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
    final filteredData = context.watch<FilteredData>();
    final stravaGear = filteredData.stravaGears[stravaActivity.gearId];
    final athlete = filteredData.stravaAthletes[stravaActivity.athlete];
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  backgroundImage: athlete?.profile != null && athlete!.profile!.startsWith("http") 
                      ? NetworkImage(athlete.profile!) 
                      : null,
                  child: athlete?.profile == null || !athlete!.profile!.startsWith("http")
                      ? Icon(Icons.person, color: Theme.of(context).colorScheme.onSurfaceVariant)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        athlete != null 
                            ? "${athlete.firstname ?? ""} ${athlete.lastname ?? ""}".trim()
                            : "Strava Athlete",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        "${DateFormat(appSettings.dateFormat).format(stravaActivity.startDateLocal)} • ${DateFormat(appSettings.timeFormat).format(stravaActivity.startDateLocal)}",
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
                Row(
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
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _statWidget(context, "Distance", _formatDistance(stravaActivity.distance)),
                _statWidget(context, "Elev Gain", _formatElevation(stravaActivity.totalElevationGain)),
                _statWidget(context, "Avg Speed", _formatSpeed(stravaActivity.distance, stravaActivity.movingTime)),
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
          
          Divider(height: 1, thickness: 0.5, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          if (stravaGear != null) ...[
            const SizedBox(height: 2),
            ListTile(
              leading: const Icon(Icons.pedal_bike),
              title: Text(
                stravaGear.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Gear used",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              dense: true,
            ),
            const SizedBox(height: 2),
            Divider(height: 1, thickness: 0.5, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
            
            // Add Setups related to this activity
            Builder(
              builder: (context) {
                final allSetupsForGear = filteredData.filteredSetups.values
                    .where((s) => filteredData.bikes[s.bike]?.stravaGear == stravaGear.id)
                    .toList();
                
                // Setups added after activity started, but before it ended
                final activityEnd = stravaActivity.startDateLocal.add(stravaActivity.elapsedTime);
                final setupsDuringActivity = allSetupsForGear.where((s) => 
                  s.datetimeLocal.isAfter(stravaActivity.startDateLocal) &&
                  s.datetimeLocal.isBefore(activityEnd)
                ).toList();

                // Setup active at the start of the activity (latest one before/on start)
                final setupsBeforeOrOnStart = allSetupsForGear.where((s) => 
                  s.datetimeLocal.isBefore(stravaActivity.startDateLocal) || 
                  s.datetimeLocal.isAtSameMomentAs(stravaActivity.startDateLocal)
                ).toList();
                setupsBeforeOrOnStart.sort((a, b) => b.datetimeLocal.compareTo(a.datetimeLocal));
                
                final List<Setup> relevantSetups = [];
                if (setupsBeforeOrOnStart.isNotEmpty) {
                  relevantSetups.add(setupsBeforeOrOnStart.first); // active setup
                }
                relevantSetups.addAll(setupsDuringActivity);

                // Filter out duplicates (just in case) and sort chronologically
                final uniqueSetups = relevantSetups.toSet().toList();
                uniqueSetups.sort((a, b) => b.datetimeLocal.compareTo(a.datetimeLocal));

                if (uniqueSetups.isEmpty) {
                  return const SizedBox.shrink();
                }

                return ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  initiallyExpanded: false,
                  title: Text(
                    "Setups (${uniqueSetups.length})",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: uniqueSetups.map((setup) {
                    return SetupListCard(
                      setupId: setup.id,
                      displayOnlyChanges: false,
                      displayBikeAdjustmentValues: true,
                      displayPersonAdjustmentValues: true,
                      displayRatingAdjustmentValues: true,
                      onTap: null,
                    );
                  }).toList(),
                );
              }
            ),
            Divider(height: 1, thickness: 0.5, color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
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
