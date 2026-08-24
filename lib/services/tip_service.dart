import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../models/tip_product.dart';

sealed class TipState {
  const TipState();
}

class TipIdle extends TipState {
  const TipIdle();
}

class TipLoadingProducts extends TipState {
  const TipLoadingProducts();
}

class TipPurchasing extends TipState {
  const TipPurchasing();
}

class TipError extends TipState {
  final String message;
  const TipError(this.message);
}

class TipService extends ChangeNotifier {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _storeAvailable = false;

  final Map<TipProduct, ProductDetails> _products = {};

  TipState _state = const TipIdle();
  bool _justTipped = false;

  TipState get state => _state;
  bool get isBusy => switch (_state) {
    TipIdle() || TipError() => false,
    TipLoadingProducts() || TipPurchasing() => true,
  };
  bool get storeAvailable => _storeAvailable;
  bool get justTipped => _justTipped;
  bool get productsReady => TipProduct.values.every(_products.containsKey) && !isBusy;

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
        onError: (Object e) => _setState(TipError('Purchase stream error: $e')),
      );

      if (_storeAvailable) {
        await _loadProducts();
      } else {
        _setState(const TipError('Store is not available on this device.'));
      }
    } catch (e) {
      debugPrint('TipService: init failed: $e');
      _setState(TipError('Tip purchase initialization failed: $e'));
      _isInitialized = false; // allow retry
    }
  }

  Future<void> _loadProducts() async {
    _setState(const TipLoadingProducts());
    try {
      final ids = TipProduct.values.map((t) => t.productId).toSet();
      final response = await _iap.queryProductDetails(ids);
      if (response.error != null) {
        _setState(TipError('Could not load tips: ${response.error!.message}'));
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
      if (!TipProduct.values.every(_products.containsKey)) {
        _setState(
          const TipError('Tips are not fully available. Please try again later.'),
        );
        return;
      }
      _setState(const TipIdle());
    } catch (e) {
      _setState(TipError('Could not load tips: $e'));
    }
  }

  Future<void> buyTip(TipProduct tip) async {
    if (!_storeAvailable) {
      _setState(const TipError('Store is not available on this device.'));
      return;
    }
    final product = _products[tip];
    if (product == null) {
      _setState(const TipError('Tip not loaded yet — try again in a moment.'));
      return;
    }

    _setState(const TipPurchasing());
    try {
      final PurchaseParam param;
      if (Platform.isAndroid && product is GooglePlayProductDetails) {
        param = GooglePlayPurchaseParam(productDetails: product);
      } else {
        param = PurchaseParam(productDetails: product);
      }
      // Consumable: autoConsume (default true) makes it re-buyable on Android.
      final launched = await _iap.buyConsumable(purchaseParam: param);
      if (!launched && _state is TipPurchasing) {
        _setState(const TipIdle());
      }
    } catch (e) {
      _setState(TipError('Tip purchase failed: $e'));
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final pd in purchases) {
      debugPrint('TipService _onPurchaseUpdate: ${pd.productID} → ${pd.status}');
      final isTipProduct = TipProduct.isTipProductId(pd.productID);

      // A canceled/failed purchase can arrive with an empty productID,
      // so allow those terminal states to end an active tip purchase. Ignore
      // all other events because the purchase stream is shared with the
      // subscription service.
      final isEmptyIdTipTerminalState =
          pd.productID.isEmpty &&
          _state is TipPurchasing &&
          (pd.status == PurchaseStatus.error ||
              pd.status == PurchaseStatus.canceled);
      if (!isTipProduct && !isEmptyIdTipTerminalState) continue;

      switch (pd.status) {
        case PurchaseStatus.pending:
          _setState(const TipPurchasing());
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _justTipped = true;
          _setState(const TipIdle());
        case PurchaseStatus.error:
          _setState(
            TipError('Tip purchase failed: ${pd.error?.message ?? 'unknown'}'),
          );
        case PurchaseStatus.canceled:
          _setState(const TipIdle());
      }

      // Consumables need no server verification — complete immediately so the
      // store doesn't redeliver / auto-refund.
      if (isTipProduct && pd.pendingCompletePurchase) {
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

  void _setState(TipState state) {
    if (state is TipError) {
      debugPrint('TipService error: ${state.message}');
    }
    _state = state;
    notifyListeners();
  }
}
