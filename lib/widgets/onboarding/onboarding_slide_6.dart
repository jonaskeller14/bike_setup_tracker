import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../icons/simple_icons.dart';
import '../../models/strava/strava_plan.dart';
import '../../services/strava_service.dart';
import '../../services/subscription_service.dart';
import '../sheets/strava.dart';
import 'onboarding_motion.dart';
import 'onboarding_slide_scaffold.dart';
import 'onboarding_slide_utils.dart';

/// The honest close: what the app does for free, and the one thing that is
/// paid. Onboarding finishes through the primary action only — opening the
/// Strava sheet leaves the user on this slide.
class OnboardingSlide6 extends StatelessWidget {
  const OnboardingSlide6({super.key, required this.onFinish});

  final VoidCallback onFinish;

  /// The plan the paywall preselects. The trial label may only promise what
  /// the sheet will actually show once it opens.
  static const StravaPlan _ctaPlan = StravaPlan.yearly;

  static const List<String> _freeFeatures = [
    'As many bikes, components and setups as you want',
    'Custom adjustments, with weather and location on every setup',
    'Tasks, calendar and installation history',
    'Export to Excel, CSV or JSON — your data stays yours',
  ];

  static const List<String> _stravaFeatures = [
    'Setups matched to the rides you actually rode — available in map and calendar',
    'Ridden distance and time stats per bike and component',
    'Maintenance reminders based on your riding activity',
  ];

  /// Derived from live state on every build: onboarding is replayable, so the
  /// same slide has to speak to a first-time rider and to a subscriber.
  String _stravaActionLabel(SubscriptionService subscription, StravaService strava) {
    if (subscription.hasStravaEntitlement) {
      return strava.isConnected ? 'Open Strava Sync' : 'Connect Strava';
    }
    // Until the store and the slot check have answered, the label promises
    // nothing — the sheet owns the offline, waitlist and loading states.
    if (!subscription.offersReady || strava.availability != StravaAvailability.available) {
      return 'Explore Strava Sync';
    }
    return subscription.offerFor(_ctaPlan)?.isTrialEligible == true ? 'Start 7-day free trial' : 'Subscribe';
  }

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionService>();
    final strava = context.watch<StravaService>();

    return OnboardingSlideScaffold(
      onNext: onFinish,
      // Nothing is left to decline once the subscription is held.
      nextLabel: subscription.hasStravaEntitlement ? "Continue" : "Continue free",
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Yours, for free',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Strava Sync is the only paid extra — everything else stays free.",
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const DelayedFade(
            delay: Duration.zero,
            child: _Section(
              label: 'FREE FOREVER',
              icon: Icon(Icons.all_inclusive),
              features: _freeFeatures,
            ),
          ),
          const SizedBox(height: 16),
          DelayedFade(
            delay: kOnboardingStageDelay * 2,
            child: _Section(
              label: 'OPTIONAL ADD-ON',
              icon: const Icon(SimpleIcons.strava, color: Color(0xFFFC4C02)),
              features: _stravaFeatures,
              action: FilledButton.tonal(
                onPressed: () => showStravaSheet(context: context),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: Text(_stravaActionLabel(subscription, strava), overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One half of the split: a labelled card listing what it includes.
class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.icon,
    required this.features,
    this.action,
  });

  final String label;
  final Widget icon;
  final List<String> features;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTheme.merge(data: const IconThemeData(size: 20), child: icon),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final feature in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          if (action case final action?) ...[
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: action),
          ],
        ],
      ),
    );
  }
}
