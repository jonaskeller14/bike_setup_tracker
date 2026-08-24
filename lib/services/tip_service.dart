import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../models/tip_product.dart';

class TipService extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _storeAvailable = false;

  final Map<TipProduct, ProductDetails> _products = {};

  bool _isBusy = false;
  String? _errorMessage;
  bool _justTipped = false;

  bool get isBusy => _isBusy;
  bool get storeAvailable => _storeAvailable;
  String? get errorMessage => _errorMessage;
  bool get justTipped => _justTipped;

  String? localizedPrice(TipProduct tip) => _products[tip]?.price;

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_purchaseSub?.cancel());
    super.dispose();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      _storeAvailable = await _iap.isAvailable();

      _purchaseSub = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (Object e) => _setError('Purchase stream error: $e'),
      );

      if (_storeAvailable) {
        await _loadProducts();
      }
    } catch (e) {
      debugPrint('TipService: init failed: $e');
      _isInitialized = false; // allow retry
    }
  }

  Future<void> _loadProducts() async {
    try {
      final ids = TipProduct.values.map((t) => t.productId).toSet();
      final response = await _iap.queryProductDetails(ids);
      if (response.error != null) {
        debugPrint('TipService: could not load products: ${response.error!.message}');
        return;
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('TipService: products not found in store: ${response.notFoundIDs}');
      }

      _products.clear();
      for (final pd in response.productDetails) {
        final tip = TipProduct.fromProductId(pd.id);
        if (tip != null) _products[tip] = pd;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('TipService: could not load products: $e');
    }
  }

  Future<void> buyTip(TipProduct tip) async {
    if (!_storeAvailable) {
      _setError('Store is not available on this device.');
      return;
    }
    final product = _products[tip];
    if (product == null) {
      _setError('Tip not loaded yet — try again in a moment.');
      return;
    }

    _setBusy(true);
    try {
      final PurchaseParam param;
      if (Platform.isAndroid && product is GooglePlayProductDetails) {
        param = GooglePlayPurchaseParam(productDetails: product);
      } else {
        param = PurchaseParam(productDetails: product);
      }
      // Consumable: autoConsume (default true) makes it re-buyable on Android.
      await _iap.buyConsumable(purchaseParam: param);
    } catch (e) {
      _setBusy(false);
      _setError('Tip purchase failed: $e');
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final pd in purchases) {
      debugPrint('TipService _onPurchaseUpdate: ${pd.productID} → ${pd.status}');

      // On iOS a canceled/failed purchase can arrive with an empty productID,
      // so the terminal states must clear our busy spinner regardless of the
      // id — tips are the only purchases this service ever initiates. The
      // success path stays gated to recognised tip products.
      switch (pd.status) {
        case PurchaseStatus.pending:
          if (TipProduct.isTipProductId(pd.productID)) _setBusy(true);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (TipProduct.isTipProductId(pd.productID)) {
            _isBusy = false;
            _errorMessage = null;
            _justTipped = true;
            notifyListeners();
          }
        case PurchaseStatus.error:
          _setError('Tip purchase failed: ${pd.error?.message ?? 'unknown'}');
        case PurchaseStatus.canceled:
          _setBusy(false);
      }

      // Consumables need no server verification — complete immediately so the
      // store doesn't redeliver / auto-refund.
      if (pd.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(pd);
        } catch (e) {
          debugPrint('TipService: completePurchase threw (ignored): $e');
        }
      }
    }
  }

  void acknowledgeThanks() {
    if (!_justTipped) return;
    _justTipped = false;
    notifyListeners();
  }

  void _setBusy(bool value) {
    if (_isBusy == value) return;
    _isBusy = value;
    notifyListeners();
  }

  void _setError(String message) {
    debugPrint('TipService error: $message');
    _errorMessage = message;
    _isBusy = false;
    notifyListeners();
  }
}
