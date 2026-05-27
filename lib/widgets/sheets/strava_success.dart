import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../icons/simple_icons.dart';
import '../../services/strava_service.dart';
import '../items/strava_subscription_card.dart';

class StravaSuccess extends StatelessWidget {
  static const _successFgColor = Color(0xFF1F8A5B);
  static const _successBgColor = Color(0xFFE7F6EE);

  const StravaSuccess({super.key});

  @override
  Widget build(BuildContext context) {
    final stravaService = context.watch<StravaService>();
    final isAwaitingAuth = stravaService.isAwaitingStravaAuth;
    final authError = stravaService.stravaAuthError;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      "You're in.",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Strava Sync is active on this account. Connect your Strava login next so we can start importing activities.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const StravaSubscriptionCard(backgroundColor: Colors.white),
                  ],
                ),
              )
            ),
            const SizedBox(height: 16),
            if (authError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        authError,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: isAwaitingAuth
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(SimpleIcons.strava),
                label: Text(
                  isAwaitingAuth
                      ? 'Signing in…'
                      : (authError.isNotEmpty ? 'Try again' : 'Sign in to Strava'),
                ),
                onPressed: isAwaitingAuth
                    ? null
                    : () {
                        // Keep the sheet open — the Consumer in strava.dart watches
                        // StravaService.isConnected and automatically animates to
                        // StravaDashboardSheet once exchangeToken completes.
                        stravaService.clearStravaAuthError();
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
              onPressed: isAwaitingAuth ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              child: const Text('Connect later'),
            ),
          ],
        ),
      ),
    );
  }
}
