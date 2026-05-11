import 'package:flutter/material.dart';
import 'strava_dashboard.dart';
import 'strava_paywall.dart';
import 'strava_success.dart';

Future<void> showStravaSheet({required BuildContext context}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context, 
    builder: (BuildContext context) {
      return const AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: 
        //TODO: switch between states
        // StravaDashboardSheet(),
        // StravaSuccess(),
        StravaPaywall(),
      );
    },
  );
}