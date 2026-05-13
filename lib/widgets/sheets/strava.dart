import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/strava_service.dart';
import '../../services/subscription_service.dart';
import 'strava_dashboard.dart';
import 'strava_paywall.dart';
import 'strava_success.dart';
import 'strava_waitlist.dart';

Future<void> showStravaSheet({required BuildContext context}) async {
  return showModalBottomSheet<void>(
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    context: context,
    builder: (BuildContext context) {
      final subscription = context.watch<SubscriptionService>();
      final strava = context.watch<StravaService>();

      final Widget child;

      // Pre-paywall gate: never offer subscriptions to users who can't
      // actually be onboarded due to Strava API rate-limit caps. Users
      // already subscribed/connected skip this check entirely — they
      // already hold a slot.
      if (!subscription.hasStravaEntitlement && !strava.isConnected) {
        final availability = strava.isStravaAvailable;
        if (availability == null) {
          unawaited(strava.checkAvailability());
          child = const _StravaSheetLoading();
        } else if (!availability) {
          child = const StravaWaitlist();
        } else {
          child = const StravaPaywall();
        }
      } else if (!subscription.hasStravaEntitlement) {
        child = const StravaPaywall();
      } else if (!strava.isConnected) {
        child = const StravaSuccess();
      } else {
        child = const StravaDashboardSheet();
      }

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey(child.runtimeType),
          child: child,
        ),
      );
    },
  );
}


class _StravaSheetLoading extends StatelessWidget {
  const _StravaSheetLoading();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
