import 'package:flutter/material.dart';
import '../../models/strava/strava_activity.dart';
import '../../pages/details/strava_activitiy_details_page.dart';

Future<void> showStravaActivitySheet({required BuildContext context, required StravaActivity stravaActivity}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (BuildContext context) => SafeArea(
      child: StravaActivitiyPageContent(stravaActivity: stravaActivity)
    ),
  );
}
