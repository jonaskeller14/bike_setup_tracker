import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../models/strava/strava_activity.dart';
import '../services/strava_service.dart';
import '../pages/strava_activitiy_page.dart';

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
      title: Text(stravaActivity.name),
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
        ],
      ),
      dense: true,
      contentPadding: contentPadding,
      onTap: () async {
        Navigator.push<void>(context, MaterialPageRoute(builder: (context) => StravaActivityPage(
          stravaActivity: stravaActivity,
        )));
      },
      trailing: GestureDetector(
        onTap: () => StravaService.openActivityOnStrava(stravaActivity.id),
        child: const Text(
          "View on Strava",
          style: TextStyle(
            color: Color(0xFFFC5200),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
