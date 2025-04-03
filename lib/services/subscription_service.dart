import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SubscriptionTier {
  free,
  pro,
}

enum PurchaseStatus {
  pending,
  purchased,
  error,
  canceled,
  restored,
}

class SubscriptionService extends ChangeNotifier {
  static const String _subscriptionStatusKey = 'subscription_status';
  static const String _removeAdsKey = 'remove_ads';
  static const String _purchasedThemesKey = 'purchased_themes';
  
  // Product IDs - these need to match what you set up in Play Console
  static const String monthlySubId = 'com.trackmywork.subscription.monthly';
  static const String yearlySubId = 'com.trackmywork.subscription.yearly';
  static const String removeAdsId = 'com.trackmywork.onetime.removeads';
  static const String themesPackId = 'com.trackmywork.onetime.themepack';
  
  // Subscription state
  SubscriptionTier _currentTier = SubscriptionTier.free;
  bool _removeAds = false;
  List<String> _purchasedThemes = [];
  
  // IAP connection
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Getters
  SubscriptionTier get currentTier => _currentTier;
  bool get isPro => _currentTier == SubscriptionTier.pro;
  bool get removeAds => _removeAds || isPro; // Pro tier includes ad removal
  List<String> get purchasedThemes => _purchasedThemes;
  bool get isLoading => _isLoading;
  bool get isAvailable => _isAvailable;
  String get errorMessage => _errorMessage;
  List<ProductDetails> get products => _products;
  
  // Activity limits based on subscription
  int get activityLimit => isPro ? 999 : 3;
  int get historyDaysLimit => isPro ? 9999 : 7;
  
  // Initialize the service
  Future<void> init() async {
    // Load saved subscription status
    await _loadSavedStatus();
    
    // Initialize IAP
    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      _isAvailable = false;
      _isLoading = false;
      _errorMessage = 'Store is not available.';
      notifyListeners();
      return;
    }
    
    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );
    
    // Load products
    await _loadProducts();
    
    _isAvailable = true;
    _isLoading = false;
    notifyListeners();
  }
  
  // Load saved subscription status
  Future<void> _loadSavedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load subscription tier
    final tierString = prefs.getString(_subscriptionStatusKey);
    if (tierString != null) {
      _currentTier = SubscriptionTier.values.firstWhere(
        (tier) => tier.toString() == tierString,
        orElse: () => SubscriptionTier.free,
      );
    }
    
    // Load remove ads status
    _removeAds = prefs.getBool(_removeAdsKey) ?? false;
    
    // Load purchased themes
    _purchasedThemes = prefs.getStringList(_purchasedThemesKey) ?? [];
    
    notifyListeners();
  }
  
  // Load available products
  Future<void> _loadProducts() async {
    final Set<String> productIds = {
      monthlySubId,
      yearlySubId,
      removeAdsId,
      themesPackId,
    };
    
    try {
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }
      
      _products = response.productDetails;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load products: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show loading UI
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // Handle error
          _errorMessage = purchaseDetails.error?.message ?? 'Unknown error';
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                  purchaseDetails.status == PurchaseStatus.restored) {
          // Handle purchased or restored
          await _handleSuccessfulPurchase(purchaseDetails);
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          // Handle canceled
        }
        
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
    notifyListeners();
  }
  
  // Handle successful purchase
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (purchase.productID == monthlySubId || purchase.productID == yearlySubId) {
      // Handle subscription
      _currentTier = SubscriptionTier.pro;
      await prefs.setString(_subscriptionStatusKey, _currentTier.toString());
    } else if (purchase.productID == removeAdsId) {
      // Handle remove ads
      _removeAds = true;
      await prefs.setBool(_removeAdsKey, true);
    } else if (purchase.productID == themesPackId) {
      // Handle theme pack
      if (!_purchasedThemes.contains(purchase.productID)) {
        _purchasedThemes.add(purchase.productID);
        await prefs.setStringList(_purchasedThemesKey, _purchasedThemes);
      }
    }
    
    notifyListeners();
  }
  
  // Purchase a product
  Future<bool> purchaseProduct(ProductDetails product) async {
    if (!_isAvailable) {
      _errorMessage = 'Store is not available.';
      notifyListeners();
      return false;
    }
    
    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );
      
      if (product.id == monthlySubId || product.id == yearlySubId) {
        return await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        return await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      _errorMessage = 'Purchase failed: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Restore purchases
  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      _errorMessage = 'Restore failed: $e';
      notifyListeners();
    }
  }
  
  // For testing: Set subscription tier manually
  Future<void> setSubscriptionTier(SubscriptionTier tier) async {
    _currentTier = tier;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_subscriptionStatusKey, _currentTier.toString());
    notifyListeners();
  }
  
  // For testing: Toggle remove ads manually
  Future<void> toggleRemoveAds(bool value) async {
    _removeAds = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_removeAdsKey, value);
    notifyListeners();
  }
  
  void _updateStreamOnDone() {
    _subscription?.cancel();
  }
  
  void _updateStreamOnError(dynamic error) {
    _errorMessage = 'Stream error: $error';
    notifyListeners();
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
