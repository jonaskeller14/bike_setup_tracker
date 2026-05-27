import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import '../models/strava/strava_entitlement.dart';
import '../models/strava/strava_plan.dart';
export '../models/strava/strava_entitlement.dart';

enum SubscriptionPurchaseStatus {
  idle,
  loadingProducts,
  purchasing,
  verifying,
  restoring,
  error,
}

class SubscriptionService extends ChangeNotifier with WidgetsBindingObserver {
  static const String _firestoreField = 'entitlement';

  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _entitlementSub;

  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _storeAvailable = false;
  String? _userId;

  bool _justPurchasedStrava = false;
  bool get justPurchasedStrava => _justPurchasedStrava;

  /// Maps a StravaPlan to the ProductDetails that should be used to purchase
  /// it on the current platform. On Android, each entry is a
  /// GooglePlayProductDetails for a specific base plan (carries its
  /// offerToken). On iOS, each entry is a distinct App Store product.
  final Map<StravaPlan, ProductDetails> _planProducts = {};

  SubscriptionPurchaseStatus _status = SubscriptionPurchaseStatus.idle;
  String _errorMessage = '';
  StravaEntitlement? _entitlement;

  /// True while `restorePurchases` is in flight at app launch — the cached
  /// `expiresAt` in Firestore may be stale until the platform-side restore
  /// completes and `verifySubscription` writes a fresh value. UI uses this
  /// to avoid flashing the paywall during the brief verification window.
  bool _isRestoring = false;
  Timer? _restoreTimeoutTimer;
  DateTime? _lastAutoRestoreAt;
  static const Duration _autoRestoreCooldown = Duration(minutes: 30);

  SubscriptionPurchaseStatus get status => _status;
  String get errorMessage => _errorMessage;
  bool get storeAvailable => _storeAvailable;
  bool get isInitialized => _isInitialized;
  StravaEntitlement? get entitlement => _entitlement;
  bool get hasStravaEntitlement => _entitlement?.isActive ?? false;
  StravaPlan? get activePlan => _entitlement?.plan;
  bool get isRestoring => _isRestoring;

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
    WidgetsBinding.instance.removeObserver(this);
    _restoreTimeoutTimer?.cancel();
    unawaited(_purchaseSub?.cancel());
    unawaited(_entitlementSub?.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) { return; }
    if (hasStravaEntitlement || !_storeAvailable || _isRestoring) { return; }
    final now = DateTime.now();
    if (_lastAutoRestoreAt != null &&
        now.difference(_lastAutoRestoreAt!) < _autoRestoreCooldown) {
      return;
    }
    _lastAutoRestoreAt = now;
    debugPrint('SubscriptionService: resumed with inactive entitlement — auto-restoring');
    _beginRestore();
    unawaited(_iap.restorePurchases());
  }

  void _beginRestore() {
    if (_isRestoring) return;
    _isRestoring = true;
    notifyListeners();
    // Hard timeout — if no purchaseStream event arrives in 5s (e.g. store
    // unreachable, no active subscription), drop the restoring flag so the
    // UI can resolve to its real state (paywall, success, dashboard).
    _restoreTimeoutTimer?.cancel();
    _restoreTimeoutTimer = Timer(const Duration(seconds: 5), _endRestore);
  }

  void _endRestore() {
    _restoreTimeoutTimer?.cancel();
    _restoreTimeoutTimer = null;
    if (!_isRestoring) return;
    _isRestoring = false;
    notifyListeners();
  }

  /// Idempotent init — safe to call from a ChangeNotifierProxyProvider's
  /// update callback. Requires that `enableStrava` is true; otherwise we
  /// short-circuit so we don't query the store for users not in the rollout.
  Future<void> initialize({required bool enableStrava}) async {
    if (_isInitialized || !enableStrava) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);

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
        _beginRestore();
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
    User? user = await FirebaseAuth.instance.authStateChanges().first;
    user ??= (await FirebaseAuth.instance.signInAnonymously()).user;
    _userId = user?.uid;
    if (_userId == null) return;

    await _entitlementSub?.cancel();
    _entitlementSub = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .snapshots()
        .listen((snap) {
      final previousEntitlement = _entitlement;
      final data = snap.data();
      final entitlementMap =
          data?[_firestoreField] as Map<String, dynamic>?;
      final stravaMap = entitlementMap?['strava'] as Map<String, dynamic>?;
      _entitlement = StravaEntitlement.fromMap(stravaMap);
      notifyListeners();

      // Auto-restore when entitlement lapses while the app is running.
      // Catches renewal timing gaps (webhook delay or failure) without requiring
      // a manual "Restore purchase" tap. While restoring, strava.dart routes to
      // the dashboard (isRestoring=true + isConnected=true), so the user sees
      // no interruption if the webhook updates Firestore within seconds.
      if (previousEntitlement?.isActive == true &&
          !(_entitlement?.isActive ?? false) &&
          _storeAvailable &&
          !_isRestoring) {
        debugPrint('SubscriptionService: entitlement lapsed — auto-restoring');
        _beginRestore();
        unawaited(_iap.restorePurchases());
      }
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
    if (_isRestoring) return;
    _beginRestore();
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
      _endRestore();
      _setError('Restore failed: $e');
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final pd in purchases) {
      debugPrint('SubscriptionService _onPurchaseUpdate: ${pd.productID} → ${pd.status} (source=${pd.verificationData.source})');
      switch (pd.status) {
        case PurchaseStatus.pending:
          _setStatus(SubscriptionPurchaseStatus.purchasing);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndAcknowledge(pd);
        case PurchaseStatus.error:
          if (Platform.isAndroid && pd.error?.code == '7') {
            // ITEM_ALREADY_OWNED — subscription is active on this Play account; restore instead.
            // Do NOT call _beginRestore() here: _endRestore() fires at the end of this same
            // _onPurchaseUpdate call, which would immediately cancel the restore flag before
            // the actual restore events arrive in the next call.
            debugPrint('SubscriptionService: ITEM_ALREADY_OWNED — auto-restoring');
            _setStatus(SubscriptionPurchaseStatus.restoring);
            unawaited(_iap.restorePurchases());
          } else {
            _setError('Purchase failed: ${pd.error?.message ?? 'unknown'}');
          }
        case PurchaseStatus.canceled:
          _setStatus(SubscriptionPurchaseStatus.idle);
      }
      if (pd.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(pd);
        } catch (e) {
          debugPrint('SubscriptionService: completePurchase threw (ignored): $e');
        }
      }
    }
    // Restore has produced its events — entitlement is now authoritative.
    _endRestore();
  }

  Future<void> _verifyAndAcknowledge(PurchaseDetails pd) async {
    _setStatus(SubscriptionPurchaseStatus.verifying);

    // Skip re-verification for a restored purchase if the entitlement is already
    // active — webhooks keep Firestore current and a redundant CF call isn't needed.
    if (pd.status == PurchaseStatus.restored && (_entitlement?.isActive ?? false)) {
      _setStatus(SubscriptionPurchaseStatus.idle);
      return;
    }

    try {
      debugPrint('SubscriptionService _verifyAndAcknowledge: calling verifySubscription for ${pd.productID}');
      final functions =
          FirebaseFunctions.instanceFor(region: 'europe-west3');
      // On iOS, the App Store Server API expects a numeric transactionId
      // (e.g. "2000000123456789"), not the base64 receipt that
      // serverVerificationData contains. pd.purchaseID is the
      // transactionIdentifier from SKPaymentTransaction. On Android, the
      // server-side Play API uses the purchase token, which IS what
      // serverVerificationData contains.
      final iosTxId = pd.purchaseID;
      if (Platform.isIOS && (iosTxId == null || iosTxId.isEmpty)) {
        _setError('Missing transaction id for iOS purchase.');
        return;
      }
      await functions.httpsCallable('verifySubscription').call({
        'platform': Platform.isIOS ? 'ios' : 'android',
        'productId': pd.productID,
        'purchaseToken': Platform.isIOS
            ? iosTxId
            : pd.verificationData.serverVerificationData,
        'source': pd.verificationData.source,
        // Android needs the package name on the backend (Play API call).
        // It's not available on PurchaseDetails directly, but the Cloud
        // Function can derive it from the authenticated user's app context
        // or it can be set here from a build-time constant later.
      });
      if (pd.status == PurchaseStatus.purchased) {
        _justPurchasedStrava = true;
      }
      _setStatus(SubscriptionPurchaseStatus.idle);
      // The Firestore listener will pick up the new entitlement and emit
      // notifyListeners on its own — no need to set state here.
    } on FirebaseFunctionsException catch (e) {
      // Restore re-verification failing for any CF reason is non-fatal —
      // Firestore entitlement is cached locally and is the source of truth.
      if (pd.status == PurchaseStatus.restored) {
        debugPrint('SubscriptionService: restore verify failed (${e.code}), using cached entitlement');
        _setStatus(SubscriptionPurchaseStatus.idle);
        return;
      }
      _setError(_friendlyVerifyError(e) ?? 'Could not verify purchase: [${e.code}] ${e.message}');
    } catch (e) {
      _setError('Could not verify purchase: $e');
    }
  }

  String? _friendlyVerifyError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'deadline-exceeded':
      case 'unavailable':
        return 'No internet connection. Please check your connection and try again.';
      case 'unauthenticated':
        return 'Authentication error. Please try again.';
      default:
        return null;
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
