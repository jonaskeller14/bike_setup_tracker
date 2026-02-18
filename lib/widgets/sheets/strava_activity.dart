import 'package:bike_setup_tracker/models/strava/strava_activity.dart';
import 'package:bike_setup_tracker/pages/strava_activitiy_page.dart';
import 'package:flutter/material.dart';

Future<void> showStravaActivitySheet({required BuildContext context, required StravaActivity stravaActivity}) async {
  return await showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (BuildContext context) => SafeArea(
      child: StravaActivitiyPageContent(stravaActivity: stravaActivity)
    ),
  );
}
