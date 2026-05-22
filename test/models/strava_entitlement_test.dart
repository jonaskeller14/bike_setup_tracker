import 'package:bike_setup_tracker/models/strava/strava_entitlement.dart';
import 'package:bike_setup_tracker/models/strava/strava_plan.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Grace period in tests is 2 minutes (kDebugMode = true in test environment).
const _gracePeriod = Duration(minutes: 2);

StravaEntitlement _make({
  required DateTime expiresAt,
  required bool autoRenewing,
  StravaPlan plan = StravaPlan.monthly,
}) =>
    StravaEntitlement(
      plan: plan,
      expiresAt: expiresAt,
      productId: 'strava_sync_monthly',
      platform: 'ios',
      autoRenewing: autoRenewing,
    );

void main() {
  final now = DateTime.now();

  // ── isActive ────────────────────────────────────────────────────────────────

  group('isActive — non-autoRenewing', () {
    test('active when expiresAt is in the future', () {
      final e = _make(expiresAt: now.add(const Duration(hours: 1)), autoRenewing: false);
      expect(e.isActive, isTrue);
    });

    test('inactive when expiresAt is in the past', () {
      final e = _make(expiresAt: now.subtract(const Duration(seconds: 1)), autoRenewing: false);
      expect(e.isActive, isFalse);
    });

    test('inactive even 1 second past expiry — no grace period', () {
      final e = _make(expiresAt: now.subtract(const Duration(seconds: 1)), autoRenewing: false);
      expect(e.isActive, isFalse);
    });
  });

  group('isActive — autoRenewing (grace period = $_gracePeriod in debug)', () {
    test('active when expiresAt is in the future', () {
      final e = _make(expiresAt: now.add(const Duration(hours: 1)), autoRenewing: true);
      expect(e.isActive, isTrue);
    });

    test('active when just expired but within grace period', () {
      final e = _make(
        expiresAt: now.subtract(_gracePeriod - const Duration(seconds: 10)),
        autoRenewing: true,
      );
      expect(e.isActive, isTrue);
    });

    test('inactive when expired beyond grace period', () {
      final e = _make(
        expiresAt: now.subtract(_gracePeriod + const Duration(seconds: 10)),
        autoRenewing: true,
      );
      expect(e.isActive, isFalse);
    });
  });

  // ── billingSource ────────────────────────────────────────────────────────────

  group('billingSource', () {
    StravaEntitlement entitlementWith(String platform) => StravaEntitlement(
          plan: StravaPlan.monthly,
          expiresAt: now.add(const Duration(days: 30)),
          productId: '',
          platform: platform,
          autoRenewing: true,
        );

    test('ios → Apple App Store', () {
      expect(entitlementWith('ios').billingSource, 'Apple App Store');
    });

    test('android → Google Play Store', () {
      expect(entitlementWith('android').billingSource, 'Google Play Store');
    });

    test('unknown platform → returned as-is', () {
      expect(entitlementWith('web').billingSource, 'web');
    });
  });

  // ── fromMap ──────────────────────────────────────────────────────────────────

  group('fromMap', () {
    test('returns null for null input', () {
      expect(StravaEntitlement.fromMap(null), isNull);
    });

    test('returns null when plan is missing', () {
      expect(StravaEntitlement.fromMap({'expiresAt': now.toIso8601String()}), isNull);
    });

    test('returns null when expiresAt is missing', () {
      expect(StravaEntitlement.fromMap({'plan': 'monthly'}), isNull);
    });

    test('returns null when expiresAt is an unparseable string', () {
      expect(
        StravaEntitlement.fromMap({'plan': 'monthly', 'expiresAt': 'not-a-date'}),
        isNull,
      );
    });

    test('parses expiresAt from ISO 8601 string', () {
      final expiry = DateTime(2026, 6, 1, 12, 0, 0).toUtc();
      final e = StravaEntitlement.fromMap({
        'plan': 'monthly',
        'expiresAt': expiry.toIso8601String(),
      });
      expect(e, isNotNull);
      expect(e!.expiresAt.toUtc(), expiry);
    });

    test('parses expiresAt from Firestore Timestamp', () {
      final expiry = DateTime(2026, 6, 1, 12, 0, 0).toUtc();
      final ts = Timestamp.fromDate(expiry);
      final e = StravaEntitlement.fromMap({'plan': 'monthly', 'expiresAt': ts});
      expect(e, isNotNull);
      expect(e!.expiresAt.toUtc(), expiry);
    });

    test('maps known plan names correctly', () {
      final monthly = StravaEntitlement.fromMap({
        'plan': 'monthly',
        'expiresAt': now.add(const Duration(days: 30)).toIso8601String(),
      });
      final yearly = StravaEntitlement.fromMap({
        'plan': 'yearly',
        'expiresAt': now.add(const Duration(days: 365)).toIso8601String(),
      });
      expect(monthly!.plan, StravaPlan.monthly);
      expect(yearly!.plan, StravaPlan.yearly);
    });

    test('unknown plan name falls back to monthly', () {
      final e = StravaEntitlement.fromMap({
        'plan': 'unknown_plan',
        'expiresAt': now.add(const Duration(days: 30)).toIso8601String(),
      });
      expect(e!.plan, StravaPlan.monthly);
    });

    test('autoRenewing defaults to false when absent', () {
      final e = StravaEntitlement.fromMap({
        'plan': 'monthly',
        'expiresAt': now.add(const Duration(days: 30)).toIso8601String(),
      });
      expect(e!.autoRenewing, isFalse);
    });

    test('reads autoRenewing correctly', () {
      final base = {
        'plan': 'monthly',
        'expiresAt': now.add(const Duration(days: 30)).toIso8601String(),
      };
      expect(
        StravaEntitlement.fromMap({...base, 'autoRenewing': true})!.autoRenewing,
        isTrue,
      );
      expect(
        StravaEntitlement.fromMap({...base, 'autoRenewing': false})!.autoRenewing,
        isFalse,
      );
    });

    test('productId and platform default to empty string when absent', () {
      final e = StravaEntitlement.fromMap({
        'plan': 'monthly',
        'expiresAt': now.add(const Duration(days: 30)).toIso8601String(),
      });
      expect(e!.productId, '');
      expect(e.platform, '');
    });

    test('reads productId and platform when present', () {
      final e = StravaEntitlement.fromMap({
        'plan': 'monthly',
        'expiresAt': now.add(const Duration(days: 30)).toIso8601String(),
        'productId': 'strava_sync_monthly',
        'platform': 'ios',
      });
      expect(e!.productId, 'strava_sync_monthly');
      expect(e.platform, 'ios');
    });
  });
}
