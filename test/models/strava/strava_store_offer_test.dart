import 'package:bike_setup_tracker/models/strava/strava_store_offer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StravaStoreOffer.yearlySavingsPercent', () {
    test('calculates the rounded saving from comparable recurring prices', () {
      expect(
        StravaStoreOffer.yearlySavingsPercent(
          monthlyPrice: 0.99,
          monthlyCurrencyCode: 'EUR',
          yearlyPrice: 8.99,
          yearlyCurrencyCode: 'EUR',
        ),
        24,
      );
    });

    test('returns null for incomparable or non-saving prices', () {
      expect(
        StravaStoreOffer.yearlySavingsPercent(
          monthlyPrice: 0.99,
          monthlyCurrencyCode: 'EUR',
          yearlyPrice: 8.99,
          yearlyCurrencyCode: 'USD',
        ),
        isNull,
      );
      expect(
        StravaStoreOffer.yearlySavingsPercent(
          monthlyPrice: 0.99,
          monthlyCurrencyCode: 'EUR',
          yearlyPrice: 11.88,
          yearlyCurrencyCode: 'EUR',
        ),
        isNull,
      );
    });
  });

  test('trial offer sorts before base plan and unrelated offers', () {
    final keys = [
      androidStravaOfferSelectionKey(
        offerTags: const [],
        offerId: 'retention',
        offerToken: 'c',
      ),
      androidStravaOfferSelectionKey(
        offerTags: const [],
        offerToken: 'b',
      ),
      androidStravaOfferSelectionKey(
        offerTags: const [StravaStoreOffer.trialOfferTag],
        offerId: 'trial',
        offerToken: 'a',
      ),
    ]..sort();

    expect(keys, ['0:trial:a', '1::b', '2:retention:c']);
  });
}
