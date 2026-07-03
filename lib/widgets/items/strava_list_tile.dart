import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../models/strava/strava_activity.dart';
import '../../pages/details/strava_activitiy_details_page.dart';
import '../../services/strava_service.dart';

class StravaListTile extends StatelessWidget {
  final StravaActivity stravaActivity;
  final EdgeInsetsGeometry? contentPadding;

  const StravaListTile({
    super.key,
    required this.stravaActivity,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final appSettings = context.watch<AppSettings>();
    
    return ListTile(
      title: Text(stravaActivity.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 2,
                children: [
                  Icon(Icons.calendar_month, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  Text(
                    DateFormat(appSettings.dateFormat).format(stravaActivity.startDateLocal),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 2,
                children: [
                  Icon(Icons.access_time, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  Flexible(
                    child: Text(
                      DateFormat(appSettings.timeFormat).format(stravaActivity.startDateLocal),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 2,
                children: [
                  Icon(stravaActivity.sportType.getIconData(), size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  Text(
                    stravaActivity.sportType.label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (stravaActivity.workout.isNotable)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 2,
                  children: [
                    Icon(
                      stravaActivity.workout.icon,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    Text(
                      stravaActivity.workout.label,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
      dense: true,
      contentPadding: contentPadding,
      onTap: () async {
        Navigator.push<void>(context, MaterialPageRoute(builder: (context) => StravaActivityDetailsPage(
          stravaActivity: stravaActivity,
        )));
      },
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
