import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'strava_plan.dart';

/// Snapshot of the user's entitlement to the Strava sync feature, as derived
/// from the backend `users/{uid}.entitlement.strava` document. This document
/// is the source of truth in production — it is written by the Cloud Function
/// `verifySubscription` after server-side validation of the purchase token /
/// App Store receipt, and updated by Play / App Store webhooks on renewal,
/// cancellation, refund, and expiry.
class StravaEntitlement {
  static const Duration _renewalGracePeriod = kDebugMode ? Duration(minutes: 2) : Duration(hours: 4);

  final StravaPlan plan;
  final DateTime expiresAt;
  final String productId;
  final String platform;
  final bool autoRenewing;

  const StravaEntitlement({
    required this.plan,
    required this.expiresAt,
    required this.productId,
    required this.platform,
    required this.autoRenewing,
  });

  bool get isActive {
    final now = DateTime.now();
    if (autoRenewing) {
      // Grace period absorbs webhook delivery delay at renewal time (typically < 30 s),
      // so a subscription that just renewed doesn't briefly appear lapsed.
      return now.isBefore(expiresAt.add(_renewalGracePeriod));
    }
    return now.isBefore(expiresAt);
  }

  String get billingSource => switch (platform) {
    'ios' => 'Apple App Store',
    'android' => 'Google Play Store',
    _ => platform,
  };

  static StravaEntitlement? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    final planRaw = data['plan'] as String?;
    final expiresRaw = data['expiresAt'];
    if (planRaw == null || expiresRaw == null) return null;

    final plan = StravaPlan.values.firstWhere(
      (p) => p.name == planRaw,
      orElse: () => StravaPlan.monthly,
    );
    final expiresAt = expiresRaw is Timestamp
        ? expiresRaw.toDate()
        : DateTime.tryParse(expiresRaw.toString());
    if (expiresAt == null) return null;

    return StravaEntitlement(
      plan: plan,
      expiresAt: expiresAt,
      productId: data['productId'] as String? ?? '',
      platform: data['platform'] as String? ?? '',
      autoRenewing: data['autoRenewing'] as bool? ?? false,
    );
  }
}
