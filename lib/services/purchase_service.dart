import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  static PurchaseService get instance => _instance;

  // 제품 ID
  static const String removeAdsProductId = 'com.spanishstep.app.removeads';
  static const Set<String> _productIds = {removeAdsProductId};

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  String? _errorMessage;
  bool _adsRemoved = false;

  // Getters
  bool get isAvailable => _isAvailable;
  bool get purchasePending => _purchasePending;
  String? get errorMessage => _errorMessage;
  bool get adsRemoved => _adsRemoved;
  List<ProductDetails> get products => _products;

  PurchaseService._internal();

  Future<void> initialize() async {
    if (kIsWeb) return;

    // 저장된 구매 상태 로드
    final prefs = await SharedPreferences.getInstance();
    _adsRemoved = prefs.getBool('ads_removed') ?? false;

    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      debugPrint('IAP not available');
      return;
    }

    // 구매 스트림 구독
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );

    // 제품 정보 로드
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final response = await _inAppPurchase.queryProductDetails(_productIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
    debugPrint('Products loaded: ${_products.length}');
    for (var product in _products) {
      debugPrint('Product: ${product.id} - ${product.price}');
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      _handlePurchase(purchaseDetails);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.status == PurchaseStatus.pending) {
      _purchasePending = true;
      debugPrint('Purchase pending...');
    } else {
      if (purchaseDetails.status == PurchaseStatus.error) {
        _purchasePending = false;
        _errorMessage = purchaseDetails.error?.message ?? 'Unknown error';
        debugPrint('Purchase error: $_errorMessage');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        _purchasePending = false;

        // 구매 확인
        if (purchaseDetails.productID == removeAdsProductId) {
          await _deliverProduct();
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        _purchasePending = false;
        debugPrint('Purchase canceled');
      }

      // 구매 완료 처리
      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _deliverProduct() async {
    _adsRemoved = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ads_removed', true);
    // ProgressProvider와 동기화
    await prefs.setBool('isPremium', true);
    debugPrint('Ads removed successfully!');
  }

  void _updateStreamOnDone() {
    _subscription?.cancel();
  }

  void _updateStreamOnError(Object error) {
    debugPrint('Purchase stream error: $error');
  }

  // 광고 제거 구매
  Future<bool> buyRemoveAds() async {
    debugPrint('buyRemoveAds called');

    if (!_isAvailable) {
      _errorMessage = 'Store not available';
      debugPrint(_errorMessage);
      return false;
    }

    if (_products.isEmpty) {
      await _loadProducts();
    }

    final product =
        _products.where((p) => p.id == removeAdsProductId).firstOrNull;

    if (product == null) {
      _errorMessage = 'Product "$removeAdsProductId" not found';
      debugPrint(_errorMessage);
      return false;
    }

    debugPrint('Purchasing product: ${product.id}');

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      final success =
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('Purchase initiated: $success');
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Purchase error: $_errorMessage');
      return false;
    }
  }

  // 구매 복원
  Future<void> restorePurchases() async {
    debugPrint('Restoring purchases...');
    await _inAppPurchase.restorePurchases();
  }

  // 광고 제거 가격 가져오기
  String? getRemoveAdsPrice() {
    final product =
        _products.where((p) => p.id == removeAdsProductId).firstOrNull;
    return product?.price;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
