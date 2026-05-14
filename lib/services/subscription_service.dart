import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import '../models/strava/strava_plan.dart';

enum SubscriptionPurchaseStatus {
  idle,
  loadingProducts,
  purchasing,
  verifying,
  restoring,
  error,
}

/// Snapshot of the user's entitlement to the Strava sync feature, as derived
/// from the backend `users/{uid}.entitlement.strava` document. This document
/// is the source of truth in production — it is written by the Cloud Function
/// `verifySubscription` after server-side validation of the purchase token /
/// App Store receipt, and updated by Play / App Store webhooks on renewal,
/// cancellation, refund, and expiry.
class StravaEntitlement {
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

  bool get isActive => DateTime.now().isBefore(expiresAt);

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

class SubscriptionService extends ChangeNotifier {
  static const String _firestoreField = 'entitlement';

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _entitlementSub;

  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _storeAvailable = false;
  String? _userId;

  /// Maps a StravaPlan to the ProductDetails that should be used to purchase
  /// it on the current platform. On Android, each entry is a
  /// GooglePlayProductDetails for a specific base plan (carries its
  /// offerToken). On iOS, each entry is a distinct App Store product.
  final Map<StravaPlan, ProductDetails> _planProducts = {};

  SubscriptionPurchaseStatus _status = SubscriptionPurchaseStatus.idle;
  String _errorMessage = '';
  StravaEntitlement? _entitlement;

  SubscriptionPurchaseStatus get status => _status;
  String get errorMessage => _errorMessage;
  bool get storeAvailable => _storeAvailable;
  bool get isInitialized => _isInitialized;
  StravaEntitlement? get entitlement => _entitlement;
  bool get hasStravaEntitlement => _entitlement?.isActive ?? false;
  StravaPlan? get activePlan => _entitlement?.plan;

  /// Localized price string from the store for a given plan (e.g. "€0.99",
  /// "$1.09"), or `null` if products haven't loaded yet — callers should fall
  /// back to the hardcoded [StravaPlan.price].
  String? localizedPrice(StravaPlan plan) => _planProducts[plan]?.price;

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_purchaseSub?.cancel());
    unawaited(_entitlementSub?.cancel());
    super.dispose();
  }

  /// Idempotent init — safe to call from a ChangeNotifierProxyProvider's
  /// update callback. Requires that `enableStrava` is true; otherwise we
  /// short-circuit so we don't query the store for users not in the rollout.
  Future<void> initialize({required bool enableStrava}) async {
    if (_isInitialized || !enableStrava) return;
    _isInitialized = true;

    try {
      _storeAvailable = await _iap.isAvailable();

      // Listen to purchase stream regardless of store availability — the
      // platform may surface pending or restored purchases later.
      _purchaseSub = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (Object e) =>
            _setError('Purchase stream error: $e'),
      );

      // Make sure Apple's StoreKit delegate is registered, otherwise some
      // store-initiated events (Ask to Buy, deferred purchases) can't be
      // surfaced. Safe no-op on Android.
      if (Platform.isIOS) {
        final addition = _iap
            .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await addition.setDelegate(_StoreKitPaymentQueueDelegate());
      }

      if (_storeAvailable) {
        await _loadProducts();
        // Silently restore active subscriptions on every launch. Without
        // store webhooks this is the only mechanism that picks up renewals
        // while the app was closed. The purchaseStream delivers any active
        // subscription → _verifyAndAcknowledge → refreshes expiresAt in
        // Firestore. Fire-and-forget: the Firestore listener handles the UI.
        unawaited(_iap.restorePurchases());
      }

      await _bindUser();
    } catch (e) {
      _setError('Subscription init failed: $e');
      _isInitialized = false; // allow retry
    }
  }

  /// Resolve the anonymous Firebase user (reused with StravaService) and
  /// start streaming the entitlement field. Called once on first init and on
  /// every auth change.
  Future<void> _bindUser() async {
    final auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    user ??= (await auth.signInAnonymously()).user;
    _userId = user?.uid;
    if (_userId == null) return;

    await _entitlementSub?.cancel();
    _entitlementSub = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .snapshots()
        .listen((snap) {
      final data = snap.data();
      final entitlementMap =
          data?[_firestoreField] as Map<String, dynamic>?;
      final stravaMap = entitlementMap?['strava'] as Map<String, dynamic>?;
      _entitlement = StravaEntitlement.fromMap(stravaMap);
      notifyListeners();
    }, onError: (Object e) =>
            _setError('Entitlement stream error: $e'));
  }

  Future<void> _loadProducts() async {
    _setStatus(SubscriptionPurchaseStatus.loadingProducts);
    try {
      late final Set<String> ids;
      if (Platform.isIOS) {
        ids = StravaPlan.values.map((p) => p.iosProductId).toSet();
      } else if (Platform.isAndroid) {
        ids = {StravaPlan.androidProductId};
      } else {
        _setStatus(SubscriptionPurchaseStatus.idle);
        return;
      }

      final response = await _iap.queryProductDetails(ids);
      if (response.error != null) {
        _setError('Could not load plans: ${response.error!.message}');
        return;
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
          'SubscriptionService: products not found in store: ${response.notFoundIDs}',
        );
      }

      _planProducts.clear();
      for (final pd in response.productDetails) {
        final plan = _planForProduct(pd);
        if (plan != null) _planProducts[plan] = pd;
      }
      _setStatus(SubscriptionPurchaseStatus.idle);
    } catch (e) {
      _setError('Could not load plans: $e');
    }
  }

  StravaPlan? _planForProduct(ProductDetails pd) {
    if (Platform.isIOS) {
      return StravaPlan.fromIosProductId(pd.id);
    }
    if (Platform.isAndroid && pd is GooglePlayProductDetails) {
      final idx = pd.subscriptionIndex;
      final offers = pd.productDetails.subscriptionOfferDetails;
      if (idx == null || offers == null || idx >= offers.length) return null;
      return StravaPlan.fromAndroidBasePlanId(offers[idx].basePlanId);
    }
    return null;
  }

  /// Initiates a purchase for the given plan. Resolves when the platform
  /// purchase dialog has been launched (not when the purchase completes —
  /// the result is delivered asynchronously via [purchaseStream]).
  Future<void> buy(StravaPlan plan) async {
    if (!_storeAvailable) {
      _setError('Store is not available on this device.');
      return;
    }
    final product = _planProducts[plan];
    if (product == null) {
      _setError('Plan not loaded yet — try again in a moment.');
      return;
    }

    _setStatus(SubscriptionPurchaseStatus.purchasing);
    try {
      final PurchaseParam param;
      if (Platform.isAndroid && product is GooglePlayProductDetails) {
        param = GooglePlayPurchaseParam(
          productDetails: product,
          offerToken: product.offerToken,
          applicationUserName: _userId,
        );
      } else {
        param = PurchaseParam(
          productDetails: product,
          applicationUserName: _userId,
        );
      }
      await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      _setError('Purchase failed: $e');
    }
  }

  /// Re-emits past purchases on [purchaseStream] (status: restored). Apple
  /// requires apps with non-consumable / subscription IAPs to offer this.
  Future<void> restorePurchases() async {
    if (!_storeAvailable) {
      _setError('Store is not available on this device.');
      return;
    }
    _setStatus(SubscriptionPurchaseStatus.restoring);
    try {
      await _iap.restorePurchases(applicationUserName: _userId);
      // If nothing was restored the stream emits no events, so status would
      // stay stuck at restoring forever. Reset it here; stream events that
      // arrive after this point will override the status as needed.
      if (_status == SubscriptionPurchaseStatus.restoring) {
        _setStatus(SubscriptionPurchaseStatus.idle);
      }
    } catch (e) {
      _setError('Restore failed: $e');
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final pd in purchases) {
      switch (pd.status) {
        case PurchaseStatus.pending:
          _setStatus(SubscriptionPurchaseStatus.purchasing);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndAcknowledge(pd);
        case PurchaseStatus.error:
          _setError('Purchase failed: ${pd.error?.message ?? 'unknown'}');
        case PurchaseStatus.canceled:
          _setStatus(SubscriptionPurchaseStatus.idle);
      }
      if (pd.pendingCompletePurchase) {
        await _iap.completePurchase(pd);
      }
    }
  }

  Future<void> _verifyAndAcknowledge(PurchaseDetails pd) async {
    _setStatus(SubscriptionPurchaseStatus.verifying);
    try {
      final functions =
          FirebaseFunctions.instanceFor(region: 'europe-west3');
      await functions.httpsCallable('verifySubscription').call({
        'platform': Platform.isIOS ? 'ios' : 'android',
        'productId': pd.productID,
        'purchaseToken': pd.verificationData.serverVerificationData,
        'source': pd.verificationData.source,
        // Android needs the package name on the backend (Play API call).
        // It's not available on PurchaseDetails directly, but the Cloud
        // Function can derive it from the authenticated user's app context
        // or it can be set here from a build-time constant later.
      });
      _setStatus(SubscriptionPurchaseStatus.idle);
      // The Firestore listener will pick up the new entitlement and emit
      // notifyListeners on its own — no need to set state here.
    } catch (e) {
      _setError('Could not verify purchase: $e');
    }
  }

  void _setStatus(SubscriptionPurchaseStatus s) {
    if (_status == s) return;
    _status = s;
    if (s != SubscriptionPurchaseStatus.error) _errorMessage = '';
    notifyListeners();
  }

  void _setError(String message) {
    debugPrint('SubscriptionService error: $message');
    _errorMessage = message;
    _status = SubscriptionPurchaseStatus.error;
    notifyListeners();
  }
}

/// Required by StoreKit to surface store-initiated payment flows (Ask to
/// Buy, deferred). We accept all queued transactions and disallow showing
/// the price-consent sheet from a non-purchase context.
class _StoreKitPaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) =>
      true;

  @override
  bool shouldShowPriceConsent() => false;
}
