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

    return ListTile(
      dense: true,
      titleAlignment: ListTileTitleAlignment.titleHeight,
      minLeadingWidth: 0,
      horizontalTitleGap: 8,
      contentPadding: contentPadding,
      onTap: () async {
        await Navigator.push<void>(context, MaterialPageRoute(builder: (context) => StravaActivityDetailsPage(
          stravaActivity: stravaActivity,
        )));
      },
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
          foregroundColor: const Color(0xFFFC5200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        child: const Text("View on Strava"),
      ),
    );
  }
}
