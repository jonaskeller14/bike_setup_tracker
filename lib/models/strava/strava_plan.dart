import 'dart:io';
import 'package:collection/collection.dart';

enum StravaPlan {
  monthly(
    label: 'Monthly',
    tagline: 'Try it month to month',
    price: '€0.99',
    period: '/ month',
    iosProductId: 'strava_sync_monthly',
    androidBasePlanId: 'monthly',
  ),
  yearly(
    label: 'Yearly',
    tagline: 'Best for the full season',
    price: '€8.99',
    period: '/ year',
    perMonth: '€0.75',
    save: '25%',
    iosProductId: 'strava_sync_yearly',
    androidBasePlanId: 'yearly',
  );

  final String label;
  final String tagline;
  final String price;
  final String period;
  final String? perMonth;
  final String? save;
  final String iosProductId;
  final String androidBasePlanId;

  /// Single Android subscription product containing both base plans.
  static const String androidProductId = 'strava_sync';

  const StravaPlan({
    required this.label,
    required this.tagline,
    required this.price,
    required this.period,
    required this.iosProductId,
    required this.androidBasePlanId,
    this.perMonth,
    this.save,
  });

  /// Identifier used to query / purchase this plan on the current platform.
  /// On iOS this is a distinct product per plan; on Android both plans share
  /// the same product id and differ only by base plan tag.
  String get storeProductId => Platform.isIOS ? iosProductId : androidProductId;

  static bool isStravaProductId(String id) =>
      id == androidProductId || values.any((p) => p.iosProductId == id);

  static StravaPlan? fromIosProductId(String id) {
    return values.firstWhereOrNull((p) => p.iosProductId == id);
  }

  static StravaPlan? fromAndroidBasePlanId(String basePlanId) {
    return values.firstWhereOrNull((p) => p.androidBasePlanId == basePlanId);
  }
}
