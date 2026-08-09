import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_settings.dart';
import '../../models/bike.dart';
import '../../models/strava/strava_activity.dart';
import '../../pages/details/strava_activitiy_details_page.dart';
import '../../repositories/app_repository.dart';
import '../../services/strava_service.dart';
import 'strava_context_wrapper.dart';

class StravaListTile extends StatelessWidget {
  final StravaActivity stravaActivity;
  final EdgeInsetsGeometry? contentPadding;
  final bool showDate;

  const StravaListTile({
    super.key,
    required this.stravaActivity,
    this.contentPadding,
    this.showDate = true,
  });

  Widget _buildStatItem(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        Icon(icon, size: 10, color: StravaContextWrapper.stravaOrange.withValues(alpha: 0.7)),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: StravaContextWrapper.stravaOrange,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appSettings = context.watch<AppSettings>();
    final appRepository = context.watch<AppRepository>();

    final bike = stravaActivity.gearId == null
        ? null
        : appRepository.bikes.values.firstWhereOrNull((b) => b.stravaGear == stravaActivity.gearId);

    final dateText = DateFormat(appSettings.dateFormat).format(stravaActivity.startDateLocal);
    final timeText = DateFormat(appSettings.timeFormat).format(stravaActivity.startDateLocal);

    final distance = AppSettings.convertDistanceFromMeters(stravaActivity.distance, appSettings.distanceUnit);
    final elevation = AppSettings.convertElevationFromMeters(stravaActivity.totalElevationGain, appSettings.altitudeUnit);
    final movingTime = stravaActivity.movingTime;
    final showStats = distance != null || elevation != null || movingTime > Duration.zero;

    final resolvedPadding = (contentPadding ?? const EdgeInsets.symmetric(horizontal: 16))
        .resolve(Directionality.of(context));

    return InkWell(
      onTap: () async {
        await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => StravaActivityDetailsPage(
          stravaActivity: stravaActivity,
        )));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            titleAlignment: ListTileTitleAlignment.titleHeight,
            minLeadingWidth: 0,
            horizontalTitleGap: 8,
            contentPadding: resolvedPadding,
            leading: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                stravaActivity.workout.isNotable ? stravaActivity.workout.icon : stravaActivity.sportType.getIconData(),
              ),
            ),
            title: Text(
              stravaActivity.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    Text(
                      showDate ? "$dateText • $timeText" : timeText,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    if (bike != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        spacing: 2,
                        children: [
                          Icon(Bike.iconData, size: 12, color: colorScheme.onSurfaceVariant),
                          Text(
                            bike.name,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            trailing: TextButton(
              onPressed: () => StravaService.openActivityOnStrava(stravaActivity.id),
              style: TextButton.styleFrom(
                foregroundColor: StravaContextWrapper.stravaOrange,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              child: const Text("View on Strava"),
            ),
          ),
          if (showStats)
            Padding(
              padding: EdgeInsets.only(
                left: resolvedPadding.left,
                right: resolvedPadding.right,
                bottom: 8,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: StravaContextWrapper.stravaOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (distance != null)
                      _buildStatItem(context, Icons.route, '${NumberFormat.decimalPattern().format(distance.round())} ${appSettings.distanceUnit}'),
                    if (elevation != null)
                      _buildStatItem(context, Icons.terrain, '${NumberFormat.decimalPattern().format(elevation.round())} ${appSettings.altitudeUnit}'),
                    if (movingTime > Duration.zero)
                      _buildStatItem(context, Icons.timer, '${NumberFormat.decimalPattern().format(movingTime.inHours)}h ${movingTime.inMinutes.remainder(60)}m'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
