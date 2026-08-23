import 'package:in_app_purchase/in_app_purchase.dart';

/// The exact store offer selected for a plan on the current store account.
class StravaStoreOffer {
  static const String trialOfferTag = 'strava-trial-7d';

  /// Percentage saved by paying yearly instead of for 12 monthly periods.
  /// Returns null when the prices cannot be safely compared or yearly costs
  /// the same or more.
  static int? yearlySavingsPercent({
    required double monthlyPrice,
    required String monthlyCurrencyCode,
    required double yearlyPrice,
    required String yearlyCurrencyCode,
  }) {
    if (monthlyCurrencyCode != yearlyCurrencyCode ||
        !monthlyPrice.isFinite ||
        !yearlyPrice.isFinite ||
        monthlyPrice <= 0 ||
        yearlyPrice <= 0) {
      return null;
    }

    final monthlyYearlyCost = monthlyPrice * 12;
    final savingsPercent = ((1 - yearlyPrice / monthlyYearlyCost) * 100).round();
    return savingsPercent > 0 ? savingsPercent : null;
  }

  final ProductDetails productDetails;
  final String localizedRecurringPrice;
  final double recurringPrice;
  final String currencyCode;
  final bool isTrialEligible;
  final String? offerToken;

  const StravaStoreOffer({
    required this.productDetails,
    required this.localizedRecurringPrice,
    required this.recurringPrice,
    required this.currencyCode,
    required this.isTrialEligible,
    this.offerToken,
  });
}

String androidStravaOfferSelectionKey({
  required List<String> offerTags,
  required String offerToken,
  String? offerId,
}) {
  final priority = offerTags.contains(StravaStoreOffer.trialOfferTag)
      ? 0
      : offerId == null
      ? 1
      : 2;
  return '$priority:${offerId ?? ''}:$offerToken';
}
