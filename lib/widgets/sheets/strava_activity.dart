import 'package:flutter/material.dart';

import '../../models/strava/strava_activity.dart';
import '../../pages/details/strava_activitiy_details_page.dart';
import '../../utils/url.dart';

Future<void> showStravaActivitySheet({required BuildContext context, required StravaActivity stravaActivity}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) => SafeArea(
      child: StravaActivitiyPageContent(
        stravaActivity: stravaActivity,
        showCloseButton: true,
        onMapPressed: stravaActivity.startLat != null && stravaActivity.startLon != null
            ? () => launchLocationOnMap(context, stravaActivity.startLat!, stravaActivity.startLon!, stravaActivity.name)
            : null,
      ),
    ),
  );
}
