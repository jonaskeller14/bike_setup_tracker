import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../models/strava/strava_activity.dart';
import '../../pages/details/strava_activitiy_details_page.dart';

Future<void> showStravaActivitySheet({required BuildContext context, required StravaActivity stravaActivity}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) => SafeArea(
      child: StravaActivitiyPageContent(
        stravaActivity: stravaActivity,
        showCloseButton: true,
        onMapPressed: stravaActivity.startLat != null && stravaActivity.startLon != null
            ? () {
                final String urlScheme = Theme.of(context).platform == TargetPlatform.iOS ? 'maps' : 'geo';
                unawaited(launchUrlString(
                  '$urlScheme:${stravaActivity.startLat},${stravaActivity.startLon}'
                  '?q=${stravaActivity.startLat},${stravaActivity.startLon}'
                  '(${Uri.encodeComponent(stravaActivity.name)})',
                ));
              }
            : null,
      ),
    ),
  );
}
