import 'package:bike_setup_tracker/models/strava/strava_entitlement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StravaEntitlement.fromMap', () {
    test('parses trial billing phase', () {
      final entitlement = StravaEntitlement.fromMap({
        'plan': 'yearly',
        'expiresAt': '2026-08-28T12:00:00Z',
        'productId': 'strava_sync_yearly',
        'platform': 'ios',
        'autoRenewing': true,
        'billingPhase': 'trial',
      });

      expect(entitlement?.billingPhase, StravaBillingPhase.trial);
    });

    test('defaults older records to standard billing', () {
      final entitlement = StravaEntitlement.fromMap({
        'plan': 'monthly',
        'expiresAt': '2026-09-21T12:00:00Z',
      });

      expect(entitlement?.billingPhase, StravaBillingPhase.standard);
    });
  });
}
