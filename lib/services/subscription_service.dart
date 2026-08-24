import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

import '../models/strava/strava_entitlement.dart';
import '../models/strava/strava_plan.dart';
import '../models/strava/strava_store_offer.dart';

export '../models/strava/strava_entitlement.dart';

sealed class SubscriptionState {
  const SubscriptionState();
}

class SubscriptionIdle extends SubscriptionState {
  const SubscriptionIdle();
}

class SubscriptionLoadingProducts extends SubscriptionState {
  const SubscriptionLoadingProducts();
}

class SubscriptionPurchasing extends SubscriptionState {
  const SubscriptionPurchasing();
}

class SubscriptionVerifying extends SubscriptionState {
  const SubscriptionVerifying();
}

class SubscriptionRestoring extends SubscriptionState {
  const SubscriptionRestoring();
}

class SubscriptionError extends SubscriptionState {
  final String message;
  const SubscriptionError(this.message);
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

  final Map<StravaPlan, StravaStoreOffer> _planOffers = {};

  SubscriptionState _state = const SubscriptionIdle();
  StravaEntitlement? _entitlement;

  bool get isBusy => switch (_state) {
    SubscriptionIdle() || SubscriptionError() => false,
    SubscriptionPurchasing() ||
    SubscriptionVerifying() ||
    SubscriptionRestoring() ||
    SubscriptionLoadingProducts() => true,
  };

  /// True while `restorePurchases` is in flight at app launch — the cached
  /// `expiresAt` in Firestore may be stale until the platform-side restore
  /// completes and `verifySubscription` writes a fresh value. UI uses this
  /// to avoid flashing the paywall during the brief verification window.
  bool _isRestoring = false;
  Timer? _restoreTimeoutTimer;
  DateTime? _lastAutoRestoreAt;
  static const Duration _autoRestoreCooldown = Duration(minutes: 30);

  // Bounded retry for transient verify failures (auth/App Check not ready,
  // network). verifySubscription is idempotent server-side, so retrying is safe.
  static const int _maxVerifyAttempts = 3;

  // Restore triggered by paywall button
  // --> timeout can surface "nothing found" without flashing errors during
  // the silent launch/resume/lapse auto-restores.
  bool _userInitiatedRestore = false;

  SubscriptionState get state => _state;
  String? get errorMessage {
    final s = _state;
    return s is SubscriptionError ? s.message : null;
  }

  bool get storeAvailable => _storeAvailable;
  bool get isInitialized => _isInitialized;
  String? get userId => _userId;
  StravaEntitlement? get entitlement => _entitlement;
  bool get hasStravaEntitlement => _entitlement?.isActive ?? false;
  StravaPlan? get activePlan => _entitlement?.plan;
  bool get isRestoring => _isRestoring;
  bool get offersReady => StravaPlan.values.every(_planOffers.containsKey) && !isBusy;
  StravaStoreOffer? offerFor(StravaPlan plan) => _planOffers[plan];
  String? localizedPrice(StravaPlan plan) => _planOffers[plan]?.localizedRecurringPrice;

  int? get yearlySavingsPercent {
    final monthly = _planOffers[StravaPlan.monthly];
    final yearly = _planOffers[StravaPlan.yearly];
    if (monthly == null || yearly == null) return null;
    return StravaStoreOffer.yearlySavingsPercent(
      monthlyPrice: monthly.recurringPrice,
      monthlyCurrencyCode: monthly.currencyCode,
      yearlyPrice: yearly.recurringPrice,
      yearlyCurrencyCode: yearly.currencyCode,
    );
  }

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
    if (state != AppLifecycleState.resumed) {
      return;
    }
    if (hasStravaEntitlement || !_storeAvailable || _isRestoring) {
      return;
    }
    final now = DateTime.now();
    if (_lastAutoRestoreAt != null && now.difference(_lastAutoRestoreAt!) < _autoRestoreCooldown) {
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
    _restoreTimeoutTimer = Timer(const Duration(seconds: 5), _onRestoreTimeout);
  }

  // Fires only when no purchaseStream event arrived in the window — the store
  // returned nothing to restore. For a user-initiated restore with no active
  // entitlement, tell the user explicitly (also pinpoints the "no restored
  // event" failure mode). Auto-restores stay silent.
  void _onRestoreTimeout() {
    // Only fire "nothing found" when the stream stayed silent — i.e. no
    // purchase event arrived. Any event moves the state out of
    // SubscriptionRestoring (to Verifying/Purchasing/Idle), and the event
    // handlers then own the outcome. Without this guard a slow verify (cold
    // Cloud Function start or the bounded transient retries) could still be in
    // flight at 5s and we'd wrongly tell the user no purchase was found.
    if (_userInitiatedRestore && _state is SubscriptionRestoring && !hasStravaEntitlement) {
      _setState(
        const SubscriptionError(
          'No previous purchase found for this account. Make sure you are '
          'signed in to the same Google/Apple account that bought the subscription.',
        ),
      );
    }
    _endRestore();
  }

  void _endRestore() {
    _restoreTimeoutTimer?.cancel();
    _restoreTimeoutTimer = null;
    _userInitiatedRestore = false;
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
        onError: (Object e) => _setState(SubscriptionError('Purchase stream error: $e')),
      );

      // Make sure Apple's StoreKit delegate is registered, otherwise some
      // store-initiated events (Ask to Buy, deferred purchases) can't be
      // surfaced. Safe no-op on Android.
      if (Platform.isIOS) {
        final addition = _iap.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await addition.setDelegate(_StoreKitPaymentQueueDelegate());
      }

      // Sign in and attach the entitlement listener BEFORE any restore. A
      // restored purchase triggers verifySubscription, which requires an
      // authenticated user — restoring first races sign-in and the first
      // verify call lands unauthenticated.
      await _bindUser();

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
    } catch (e) {
      _setState(SubscriptionError('Subscription init failed: $e'));
      _isInitialized = false; // allow retry
    }
  }

  /// Resolve the anonymous Firebase user (reused with StravaService) and
  /// start streaming the entitlement field. Called once on first init and on
  /// every auth change.
  Future<void> _bindUser() async {
    final user = await AuthService.ensureSignedIn();
    _userId = user?.uid;
    if (_userId == null) return;

    await _entitlementSub?.cancel();
    _entitlementSub = FirebaseFirestore.instance.collection('users').doc(_userId).snapshots().listen((snap) {
      final previousEntitlement = _entitlement;
      final data = snap.data();
      final entitlementMap = data?[_firestoreField] as Map<String, dynamic>?;
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
    }, onError: (Object e) => _setState(SubscriptionError('Entitlement stream error: $e')));
  }

  Future<void> _loadProducts() async {
    _setState(const SubscriptionLoadingProducts());
    try {
      late final Set<String> ids;
      if (Platform.isIOS) {
        ids = StravaPlan.values.map((p) => p.iosProductId).toSet();
      } else if (Platform.isAndroid) {
        ids = {StravaPlan.androidProductId};
      } else {
        _setState(const SubscriptionIdle());
        return;
      }

      final response = await _iap.queryProductDetails(ids);
      if (response.error != null) {
        _setState(SubscriptionError('Could not load plans: ${response.error!.message}'));
        return;
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('SubscriptionService: products not found in store: ${response.notFoundIDs}');
      }

      _planOffers.clear();
      if (Platform.isAndroid) {
        _loadAndroidOffers(response.productDetails);
      } else if (Platform.isIOS) {
        await _loadIosOffers(response.productDetails);
      }
      if (!StravaPlan.values.every(_planOffers.containsKey)) {
        _setState(
          const SubscriptionError(
            'Subscription plans are not fully available. Please try again later.',
          ),
        );
        return;
      }
      _setState(const SubscriptionIdle());
    } catch (e) {
      _setState(SubscriptionError('Could not load plans: $e'));
    }
  }

  void _loadAndroidOffers(List<ProductDetails> products) {
    final candidates = <StravaPlan, List<GooglePlayProductDetails>>{};
    for (final pd in products.whereType<GooglePlayProductDetails>()) {
      final idx = pd.subscriptionIndex;
      final offers = pd.productDetails.subscriptionOfferDetails;
      if (idx == null || offers == null || idx >= offers.length) continue;
      final plan = StravaPlan.fromAndroidBasePlanId(offers[idx].basePlanId);
      if (plan != null) candidates.putIfAbsent(plan, () => []).add(pd);
    }

    for (final entry in candidates.entries) {
      entry.value.sort((a, b) => _androidOfferSortKey(a).compareTo(_androidOfferSortKey(b)));
      final selected = entry.value.first;
      final details = selected.productDetails.subscriptionOfferDetails![selected.subscriptionIndex!];
      final recurringPhase = details.pricingPhases.last;
      _planOffers[entry.key] = StravaStoreOffer(
        productDetails: selected,
        localizedRecurringPrice: recurringPhase.formattedPrice,
        recurringPrice: recurringPhase.priceAmountMicros / 1000000,
        currencyCode: recurringPhase.priceCurrencyCode,
        isTrialEligible: details.offerTags.contains(
          StravaStoreOffer.trialOfferTag,
        ),
        offerToken: selected.offerToken,
      );
    }
  }

  String _androidOfferSortKey(GooglePlayProductDetails product) {
    final details = product.productDetails.subscriptionOfferDetails![product.subscriptionIndex!];
    return androidStravaOfferSelectionKey(
      offerTags: details.offerTags,
      offerId: details.offerId,
      offerToken: details.offerIdToken,
    );
  }

  Future<void> _loadIosOffers(List<ProductDetails> products) async {
    for (final product in products) {
      final plan = StravaPlan.fromIosProductId(product.id);
      if (plan == null) continue;
      var eligible = false;
      try {
        eligible = await SK2Product.isIntroductoryOfferEligible(product.id);
      } on PlatformException catch (error) {
        debugPrint(
          'SubscriptionService: intro eligibility unavailable for '
          '${product.id}: ${error.message}',
        );
      }
      _planOffers[plan] = StravaStoreOffer(
        productDetails: product,
        localizedRecurringPrice: product.price,
        recurringPrice: product.rawPrice,
        currencyCode: product.currencyCode,
        isTrialEligible: eligible,
      );
    }
  }

  /// Initiates a purchase for the given plan. Resolves when the platform
  /// purchase dialog has been launched (not when the purchase completes —
  /// the result is delivered asynchronously via [purchaseStream]).
  Future<void> buy(StravaPlan plan) async {
    if (!_storeAvailable) {
      _setState(const SubscriptionError('Store is not available on this device.'));
      return;
    }
    final offer = _planOffers[plan];
    if (offer == null || !offersReady) {
      _setState(const SubscriptionError('Plan not loaded yet — try again in a moment.'));
      return;
    }

    _setState(const SubscriptionPurchasing());
    try {
      final PurchaseParam param;
      final product = offer.productDetails;
      if (Platform.isAndroid && product is GooglePlayProductDetails) {
        param = GooglePlayPurchaseParam(
          productDetails: product,
          offerToken: offer.offerToken,
          applicationUserName: _userId,
        );
      } else {
        param = PurchaseParam(
          productDetails: product,
          applicationUserName: _userId,
        );
      }
      final launched = await _iap.buyNonConsumable(purchaseParam: param);
      if (!launched && _state is SubscriptionPurchasing) {
        _setState(const SubscriptionIdle());
      }
    } catch (e) {
      _setState(SubscriptionError('Purchase failed: $e'));
    }
  }

  /// Re-emits past purchases on [purchaseStream] (status: restored). Apple
  /// requires apps with non-consumable / subscription IAPs to offer this.
  Future<void> restorePurchases() async {
    if (!_storeAvailable) {
      _setState(const SubscriptionError('Store is not available on this device.'));
      return;
    }
    if (_isRestoring) return;
    _userInitiatedRestore = true;
    _beginRestore();
    _setState(const SubscriptionRestoring());
    try {
      await _iap.restorePurchases(applicationUserName: _userId);
      // If nothing was restored the stream emits no events, so status would
      // stay stuck at restoring forever. Reset it here; stream events that
      // arrive after this point will override the status as needed.
      // TODO: Review, is this correct?
      if (_state is SubscriptionRestoring) {
        _setState(const SubscriptionIdle());
      }
    } catch (e) {
      _endRestore();
      _setState(SubscriptionError('Restore failed: $e'));
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final pd in purchases) {
      // Google Play reports a user-cancelled billing dialog without a product
      // ID, so handle cancellation before filtering for Strava products.
      if (pd.status == PurchaseStatus.canceled && _state is SubscriptionPurchasing) {
        _setState(const SubscriptionIdle());
        continue;
      }
      if (!StravaPlan.isStravaProductId(pd.productID)) continue;
      debugPrint(
        'SubscriptionService _onPurchaseUpdate: ${pd.productID} → ${pd.status} (source=${pd.verificationData.source})',
      );
      bool granted = false;
      switch (pd.status) {
        case PurchaseStatus.pending:
          _setState(const SubscriptionPurchasing());
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          granted = await _verifyAndAcknowledge(pd);
        case PurchaseStatus.error:
          if (Platform.isAndroid && pd.error?.code == '7') {
            // ITEM_ALREADY_OWNED — subscription is active on this Play account; restore instead.
            // Do NOT call _beginRestore() here: _endRestore() fires at the end of this same
            // _onPurchaseUpdate call, which would immediately cancel the restore flag before
            // the actual restore events arrive in the next call.
            debugPrint('SubscriptionService: ITEM_ALREADY_OWNED — auto-restoring');
            _setState(const SubscriptionRestoring());
            unawaited(_iap.restorePurchases());
          } else {
            _setState(SubscriptionError('Purchase failed: ${pd.error?.message ?? 'unknown'}'));
          }
        case PurchaseStatus.canceled:
          _setState(const SubscriptionIdle());
      }
      // Acknowledge a *new* purchase only after the server has granted the
      // entitlement. An un-completed purchase is redelivered on purchaseStream
      // every launch by the store, giving a durable, store-backed retry queue
      // (and on Android avoids paid-but-not-acknowledged → auto-refund). Restored
      // purchases are already acknowledged on the store, so completing is safe.
      if (pd.pendingCompletePurchase && (pd.status != PurchaseStatus.purchased || granted)) {
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

  /// Verifies a purchase with the backend and returns whether the entitlement
  /// was granted. Callers use the result to decide whether it is safe to
  /// acknowledge/complete the purchase.
  Future<bool> _verifyAndAcknowledge(PurchaseDetails pd, {int attempt = 0}) async {
    _setState(const SubscriptionVerifying());

    // Skip re-verification for a restored purchase if the entitlement is already
    // active — webhooks keep Firestore current and a redundant CF call isn't needed.
    if (pd.status == PurchaseStatus.restored && (_entitlement?.isActive ?? false)) {
      _setState(const SubscriptionIdle());
      return true;
    }

    try {
      debugPrint('SubscriptionService _verifyAndAcknowledge: calling verifySubscription for ${pd.productID}');
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west3');
      // On iOS, the App Store Server API expects a numeric transactionId
      // (e.g. "2000000123456789"), not the base64 receipt that
      // serverVerificationData contains. pd.purchaseID is the
      // transactionIdentifier from SKPaymentTransaction. On Android, the
      // server-side Play API uses the purchase token, which IS what
      // serverVerificationData contains.
      final iosTxId = pd.purchaseID;
      if (Platform.isIOS && (iosTxId == null || iosTxId.isEmpty)) {
        _setState(const SubscriptionError('Missing transaction id for iOS purchase.'));
        return false;
      }
      await functions.httpsCallable('verifySubscription').call<void>({
        'platform': Platform.isIOS ? 'ios' : 'android',
        'productId': pd.productID,
        'purchaseToken': Platform.isIOS ? iosTxId : pd.verificationData.serverVerificationData,
        'source': pd.verificationData.source,
        // Android needs the package name on the backend (Play API call).
        // It's not available on PurchaseDetails directly, but the Cloud
        // Function can derive it from the authenticated user's app context
        // or it can be set here from a build-time constant later.
      });
      if (pd.status == PurchaseStatus.purchased) {
        _justPurchasedStrava = true;
      }
      _setState(const SubscriptionIdle());
      // The Firestore listener will pick up the new entitlement and emit
      // notifyListeners on its own — no need to set state here.
      return true;
    } on FirebaseFunctionsException catch (e) {
      // Transient (auth/App Check not ready, network) → bounded retry with
      // backoff. ensureSignedIn() is cheap when already signed in.
      final isTransient = e.code == 'unauthenticated' || e.code == 'unavailable' || e.code == 'deadline-exceeded';
      if (isTransient && attempt < _maxVerifyAttempts - 1) {
        debugPrint('SubscriptionService: verify failed (${e.code}) — retry ${attempt + 1}/${_maxVerifyAttempts - 1}');
        await AuthService.ensureSignedIn();
        await Future<void>.delayed(Duration(seconds: 1 << attempt));
        return _verifyAndAcknowledge(pd, attempt: attempt + 1);
      }
      // A restored purchase is safe to ignore ONLY when an active entitlement is
      // already cached (webhooks keep it fresh). With no active entitlement —
      // e.g. after a reinstall — the failure must surface, not be swallowed.
      if (pd.status == PurchaseStatus.restored && (_entitlement?.isActive ?? false)) {
        debugPrint('SubscriptionService: restore verify failed (${e.code}), using cached entitlement');
        _setState(const SubscriptionIdle());
        return false;
      }
      // The store reports the subscription as lapsed/expired (CF returns
      // permission-denied "Purchase is not active."). Terminal — no retry, and a
      // clear, non-alarming message rather than a raw verify error.
      if (e.code == 'permission-denied' && (e.message ?? '').toLowerCase().contains('not active')) {
        _setState(
          const SubscriptionError(
            'This subscription is no longer active on your store account. '
            'If you renewed recently, try again in a moment.',
          ),
        );
        return false;
      }
      _setState(SubscriptionError(_friendlyVerifyError(e) ?? 'Could not verify purchase: [${e.code}] ${e.message}'));
      return false;
    } catch (e) {
      _setState(SubscriptionError('Could not verify purchase: $e'));
      return false;
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

  void _setState(SubscriptionState newState) {
    if (_state == newState) return;
    if (newState is SubscriptionError) debugPrint('SubscriptionService error: ${newState.message}');
    _state = newState;
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
  ) => true;

  @override
  bool shouldShowPriceConsent() => false;
}

/// Multiple services ([StravaService], [SubscriptionService]) need the same
/// anonymous UID at startup. If each calls [FirebaseAuth.signInAnonymously]
/// independently, concurrent calls on a fresh install create *two* anonymous
/// users — the captured UID then mismatches the token the Firestore SDK uses,
/// causing transient PERMISSION_DENIED on per-user document listeners.
class AuthService {
  AuthService._();

  static Future<User?>? _inFlight;

  static Future<User?> ensureSignedIn() => _inFlight ??= _resolve();

  static Future<User?> _resolve() async {
    try {
      User? user = await FirebaseAuth.instance.authStateChanges().first;
      user ??= (await FirebaseAuth.instance.signInAnonymously()).user;
      return user;
    } catch (_) {
      _inFlight = null;
      rethrow;
    }
  }
}
