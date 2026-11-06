import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../icons/simple_icons.dart';
import '../../l10n/l10n.dart';
import '../../services/strava_service.dart';
import '../../services/subscription_service.dart';
import '../items/strava_subscription_card.dart';
import 'strava_dashboard.dart';

class StravaSuccess extends StatelessWidget {
  static const _successFgColor = Color(0xFF1F8A5B);
  static const _successBgColor = Color(0xFFE7F6EE);

  const StravaSuccess({super.key});

  @override
  Widget build(BuildContext context) {
    final stravaService = context.watch<StravaService>();
    final subscription = context.watch<SubscriptionService>();
    final failure = stravaService.failure;
    final justPurchased = subscription.justPurchasedStrava;
    final isTrial = subscription.entitlement?.billingPhase ==
        StravaBillingPhase.trial;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (justPurchased) ...[
                      Container(
                        width: 84,
                        height: 84,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _successBgColor,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 48,
                          color: _successFgColor,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isTrial ? context.l10n.stravaSuccessTrialTitle : context.l10n.stravaSuccessTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          isTrial ? context.l10n.stravaSuccessTrialBody : context.l10n.stravaSuccessBody,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      StravaSubscriptionCard(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    ] else ...[
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFC4C02).withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          Icons.login,
                          size: 48,
                          color: Color(0xFFFC4C02),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        context.l10n.stravaConnectTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          context.l10n.stravaConnectBody,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            ),
            const SizedBox(height: 16),
            if (failure != null) StravaErrorTile(failure: failure),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(SimpleIcons.strava),
                label: Text(context.l10n.stravaSignIn),
                onPressed: () {
                  stravaService.clearError();
                  unawaited(stravaService.launchStravaLogin());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC4C02),
                  foregroundColor: Colors.white,
                  iconSize: 18,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              child: Text(context.l10n.stravaConnectLater),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
