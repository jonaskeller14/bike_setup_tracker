import 'package:flutter/material.dart';

import '../../models/strava/strava_activity.dart';
import '../../pages/details/strava_activity_details_page.dart';

Future<void> showStravaActivitySheet({
  required BuildContext context,
  required StravaActivity stravaActivity,
  bool showViewOnMap = true,
}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) => SafeArea(
      child: StravaActivityPageContent(
        stravaActivity: stravaActivity,
        showCloseButton: true,
        showSheetActions: true,
        showViewOnMap: showViewOnMap,
      ),
    ),
  );
}
