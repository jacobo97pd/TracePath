import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../coins_service.dart';
import '../shop/coin_pack.dart';

enum IapStoreState {
  idle,
  loading,
  unavailable,
  ready,
  error,
}

class IapService extends ChangeNotifier {
  IapService({required CoinsService coinsService})
      : _coinsService = coinsService;

  final CoinsService _coinsService;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  final Map<String, ProductDetails> _productById = <String, ProductDetails>{};
  final Map<String, CoinPack> _packByProductId = <String, CoinPack>{};

  IapStoreState _state = IapStoreState.idle;
  String _message = '';
  String _pendingProductId = '';
  List<String> _notFoundIds = const <String>[];
  bool _initialized = false;
  bool _storeAvailable = false;

  Completer<BuyCoinPackResult>? _pendingBuyCompleter;

  IapStoreState get state => _state;
  String get message => _message;
  String get pendingProductId => _pendingProductId;
  List<String> get notFoundIds => _notFoundIds;
  bool get isStoreReady => _state == IapStoreState.ready;
  bool get isStoreLoading => _state == IapStoreState.loading;
  bool get isStoreUnavailable => _state == IapStoreState.unavailable;
  bool get isStoreError => _state == IapStoreState.error;
  bool get storeAvailable => _storeAvailable;
  List<String> get loadedProductIds =>
      List<String>.unmodifiable(_productById.keys.toList(growable: false));

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (kIsWeb) {
      _storeAvailable = false;
      _setState(
        IapStoreState.unavailable,
        'Coin packs are not available on web builds.',
      );
      _log('[IAP] initialize skipped on web');
      return;
    }
    _log('[IAP] initialize');
    try {
      _purchaseSub = _iap.purchaseStream.listen(
        _onPurchaseUpdates,
        onDone: () {
          _log('[IAP] purchase stream done');
          _purchaseSub = null;
        },
        onError: (Object e, StackTrace st) {
          _log('[IAP] purchase stream error: $e');
          debugPrintStack(stackTrace: st);
          _failPendingPurchase('Purchase stream error');
        },
      );
    } catch (e, st) {
      _log('[IAP] initialize stream attach failed: $e');
      debugPrintStack(stackTrace: st);
      _storeAvailable = false;
      _setState(
        IapStoreState.error,
        'Store initialization failed. Please try again later.',
      );
    }
  }

  Future<void> refreshCatalog(List<CoinPack> packs) async {
    if (kIsWeb) {
      _storeAvailable = false;
      _setState(
        IapStoreState.unavailable,
        'Coin packs are not available on web builds.',
      );
      return;
    }
    await initialize();
    if (_state == IapStoreState.unavailable || _state == IapStoreState.error) {
      return;
    }
    _setState(IapStoreState.loading, 'Loading store products...');
    _pendingProductId = '';
    _message = '';
    _notFoundIds = const <String>[];
    _storeAvailable = false;
    _productById.clear();
    _packByProductId.clear();
    notifyListeners();

    bool available;
    try {
      available = await _iap.isAvailable();
    } catch (e, st) {
      _log('[IAP] isAvailable failed: $e');
      debugPrintStack(stackTrace: st);
      _setState(
        IapStoreState.error,
        'Store check failed. Please try again later.',
      );
      return;
    }
    _storeAvailable = available;
    _log('[IAP] store available=$available');
    if (!available) {
      _setState(IapStoreState.unavailable, 'Store is not available right now.');
      return;
    }

    final productIds = <String>{};
    for (final pack in packs) {
      final id = _productIdForCurrentPlatform(pack);
      if (id.isNotEmpty) {
        productIds.add(id);
        _packByProductId[id] = pack;
        _log('${_platformTag()} mapped pack=${pack.id} -> productId=$id');
      }
    }

    _log('[IAP] queryProductDetails ids=${productIds.join(",")}');
    if (productIds.isEmpty) {
      _setState(
          IapStoreState.error, 'No product ids configured for this platform.');
      return;
    }

    ProductDetailsResponse response;
    try {
      response = await _iap.queryProductDetails(productIds);
    } catch (e, st) {
      _log('[IAP] queryProductDetails failed: $e');
      debugPrintStack(stackTrace: st);
      _setState(
        IapStoreState.error,
        'Store products are not available right now. Please try again later.',
      );
      return;
    }
    if (response.error != null) {
      _setState(
        IapStoreState.error,
        response.error!.message.isEmpty
            ? 'Store products are not available right now. Please try again later.'
            : response.error!.message,
      );
      _log('[IAP] query error=${response.error}');
      return;
    }

    _notFoundIds = List<String>.unmodifiable(response.notFoundIDs);
    _log('[IAP] notFoundIDs=${_notFoundIds.join(",")}');
    for (final p in response.productDetails) {
      _productById[p.id] = p;
      _log('[IAP] found product id=${p.id} price=${p.price}');
    }

    if (_productById.isEmpty) {
      _setState(
        IapStoreState.error,
        'Store products are not available right now. Please try again later.',
      );
      return;
    }
    _log(
      '[IAP] catalog ready products=${_productById.length} ids=${_productById.keys.join(",")}',
    );
    _setState(IapStoreState.ready, '');
  }

  String displayPriceForPack(CoinPack pack) {
    final productId = _productIdForCurrentPlatform(pack);
    final product = _productById[productId];
    if (product != null && product.price.trim().isNotEmpty) {
      return product.price;
    }
    return pack.priceLabel.trim().isEmpty ? 'Unavailable' : pack.priceLabel;
  }

  bool isPackAvailable(CoinPack pack) {
    final id = _productIdForCurrentPlatform(pack);
    return id.isNotEmpty && _productById.containsKey(id);
  }

  bool isPackPending(CoinPack pack) {
    final id = _productIdForCurrentPlatform(pack);
    return _pendingProductId == id && id.isNotEmpty;
  }

  Future<BuyCoinPackResult> buyPack(CoinPack pack) async {
    await initialize();
    _log('[SHOP-IAP] tap buy pack=${pack.id}');
    final productId = _productIdForCurrentPlatform(pack);
    _log('[SHOP-IAP] resolved productId="$productId" for pack=${pack.id}');
    if (productId.isEmpty) {
      _log('[SHOP-IAP] buy blocked: missing product id for pack=${pack.id}');
      return const BuyCoinPackResult(
        status: BuyCoinPackStatus.failed,
        addedCoins: 0,
        message: 'Missing product id for this platform.',
      );
    }
    if (_pendingBuyCompleter != null) {
      _log('[SHOP-IAP] buy blocked: another purchase already pending');
      return const BuyCoinPackResult(
        status: BuyCoinPackStatus.failed,
        addedCoins: 0,
        message: 'Another purchase is already in progress.',
      );
    }
    final product = _productById[productId];
    if (product == null) {
      _log(
        '[SHOP-IAP] buy blocked: product not loaded productId=$productId loaded=${_productById.keys.join(",")}',
      );
      return const BuyCoinPackResult(
        status: BuyCoinPackStatus.failed,
        addedCoins: 0,
        message: 'Store product is not available right now.',
      );
    }

    _pendingProductId = productId;
    _pendingBuyCompleter = Completer<BuyCoinPackResult>();
    _log('[IAP] purchase start productId=$productId');
    notifyListeners();

    final started = await _iap.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
      autoConsume: true,
    );
    _log('[SHOP-IAP] launch buy UI result=$started productId=$productId');
    if (!started) {
      _pendingProductId = '';
      _pendingBuyCompleter = null;
      notifyListeners();
      return const BuyCoinPackResult(
        status: BuyCoinPackStatus.failed,
        addedCoins: 0,
        message: 'Could not start purchase.',
      );
    }

    try {
      return await _pendingBuyCompleter!.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () {
          _pendingProductId = '';
          _pendingBuyCompleter = null;
          notifyListeners();
          return const BuyCoinPackResult(
            status: BuyCoinPackStatus.failed,
            addedCoins: 0,
            message: 'Purchase timed out. Please try again.',
          );
        },
      );
    } finally {
      _pendingProductId = '';
      _pendingBuyCompleter = null;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    await initialize();
    _log('[IAP-IOS] restorePurchases start');
    await _iap.restorePurchases();
  }

  String debugProductIdForPack(CoinPack pack) {
    return _productIdForCurrentPlatform(pack);
  }

  void debugLogShopSummary(List<CoinPack> packs) {
    final loadedIds = loadedProductIds;
    _log(
      '[SHOP-IAP] summary storeAvailable=$storeAvailable state=${_state.name} loadedCount=${loadedIds.length} loadedIds=${loadedIds.join(",")} missingIds=${_notFoundIds.join(",")}',
    );
    for (final pack in packs) {
      final productId = debugProductIdForPack(pack);
      final mapped = _productById.containsKey(productId);
      _log(
        '[SHOP-IAP] card packId=${pack.id} productId=$productId mapped=$mapped enabled=${mapped && isStoreReady && _pendingProductId.isEmpty}',
      );
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    if (purchases.isEmpty) return;
    for (final purchase in purchases) {
      _log(
        '[IAP] purchase update id=${purchase.productID} status=${purchase.status.name}',
      );
      await _processPurchase(purchase);
    }
  }

  Future<void> _processPurchase(PurchaseDetails purchase) async {
    try {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _pendingProductId = purchase.productID;
          notifyListeners();
          return;
        case PurchaseStatus.canceled:
          _completePendingPurchase(
            const BuyCoinPackResult(
              status: BuyCoinPackStatus.cancelled,
              addedCoins: 0,
              message: 'Purchase cancelled.',
            ),
          );
          break;
        case PurchaseStatus.error:
          _completePendingPurchase(
            BuyCoinPackResult(
              status: BuyCoinPackStatus.failed,
              addedCoins: 0,
              message: purchase.error?.message.isNotEmpty == true
                  ? purchase.error!.message
                  : 'Purchase failed.',
            ),
          );
          break;
        case PurchaseStatus.restored:
          // Consumables are not re-granted on restore.
          _completePendingPurchase(
            const BuyCoinPackResult(
              status: BuyCoinPackStatus.success,
              addedCoins: 0,
              message: 'Purchase restore processed.',
            ),
          );
          break;
        case PurchaseStatus.purchased:
          final pack = _packByProductId[purchase.productID];
          if (pack == null) {
            _completePendingPurchase(
              const BuyCoinPackResult(
                status: BuyCoinPackStatus.failed,
                addedCoins: 0,
                message: 'Purchased product is not mapped to any coin pack.',
              ),
            );
            break;
          }
          final purchaseId = (purchase.purchaseID ??
                  purchase.verificationData.serverVerificationData)
              .trim();
          final added = await _coinsService.grantVerifiedCoinPackPurchase(
            pack: pack,
            productId: purchase.productID,
            purchaseId: purchaseId,
            purchaseStatus: purchase.status.name,
            verificationData: purchase.verificationData.serverVerificationData,
          );
          _log(
            added > 0
                ? '[IAP] coins granted=$added product=${purchase.productID}'
                : '[IAP] duplicate purchase ignored product=${purchase.productID}',
          );
          _completePendingPurchase(
            BuyCoinPackResult(
              status: BuyCoinPackStatus.success,
              addedCoins: added,
              message: added > 0
                  ? 'Added +$added coins'
                  : 'Purchase already processed',
            ),
          );
          break;
      }
    } finally {
      if (purchase.pendingCompletePurchase) {
        _log('[IAP] completePurchase product=${purchase.productID}');
        await _iap.completePurchase(purchase);
      }
    }
  }

  String _productIdForCurrentPlatform(CoinPack pack) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return pack.productIdAndroid.trim();
      case TargetPlatform.iOS:
        return pack.productIdIos.trim();
      default:
        return '';
    }
  }

  void _setState(IapStoreState next, String msg) {
    _state = next;
    _message = msg;
    notifyListeners();
  }

  void _completePendingPurchase(BuyCoinPackResult result) {
    if (_pendingBuyCompleter != null && !_pendingBuyCompleter!.isCompleted) {
      _pendingBuyCompleter!.complete(result);
    }
  }

  void _failPendingPurchase(String message) {
    _completePendingPurchase(
      BuyCoinPackResult(
        status: BuyCoinPackStatus.failed,
        addedCoins: 0,
        message: message,
      ),
    );
  }

  void _log(String message) {
    debugPrint(message);
  }

  String _platformTag() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '[IAP-ANDROID]';
      case TargetPlatform.iOS:
        return '[IAP-IOS]';
      default:
        return '[IAP]';
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}
