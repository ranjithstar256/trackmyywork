import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  
  @override
  Widget build(BuildContext context) {
    final subscriptionService = Provider.of<SubscriptionService>(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('TrackMyWork Pro'),
      ),
      body: subscriptionService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const SizedBox(height: 16),
                  Icon(
                    Icons.workspace_premium,
                    size: 64,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Upgrade to TrackMyWork Pro',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock premium features and enhance your productivity',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Features comparison
                  _buildFeatureComparisonCard(context),
                  const SizedBox(height: 32),
                  
                  // Subscription options
                  if (subscriptionService.isPro)
                    _buildCurrentSubscriptionCard(context)
                  else
                    _buildSubscriptionOptionsCard(context),
                  const SizedBox(height: 24),
                  
                  // One-time purchases
                  if (!subscriptionService.isPro)
                    _buildOneTimePurchasesCard(context),
                  const SizedBox(height: 16),
                  
                  // Restore purchases button
                  Center(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => _restorePurchases(context),
                      child: const Text('Restore Purchases'),
                    ),
                  ),
                  
                  // Error message
                  if (_errorMessage.isNotEmpty || subscriptionService.errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _errorMessage.isNotEmpty
                            ? _errorMessage
                            : subscriptionService.errorMessage,
                        style: TextStyle(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  // Loading indicator
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildFeatureComparisonCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compare Plans',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildFeatureRow(
              context,
              'Number of Activities',
              'Up to 3',
              'Unlimited',
            ),
            _buildFeatureRow(
              context,
              'History',
              '7 Days',
              'Unlimited',
            ),
            _buildFeatureRow(
              context,
              'Reports',
              'Basic',
              'Advanced',
            ),
            _buildFeatureRow(
              context,
              'Data Export',
              'Not Available',
              'CSV & PDF',
            ),
            _buildFeatureRow(
              context,
              'Advertisements',
              'Yes',
              'No Ads',
            ),
            _buildFeatureRow(
              context,
              'Themes',
              'Basic',
              'All Premium',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureRow(
    BuildContext context,
    String feature,
    String freeValue,
    String proValue, {
    bool isLast = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  feature,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  freeValue,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  proValue,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(),
      ],
    );
  }
  
  Widget _buildCurrentSubscriptionCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      elevation: 4,
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle,
              size: 48,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              'You are a Pro Member!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you for supporting TrackMyWork',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You have access to all premium features',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubscriptionOptionsCard(BuildContext context) {
    final subscriptionService = Provider.of<SubscriptionService>(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    // Find monthly and yearly subscription products
    ProductDetails monthlyProduct;
    try {
      monthlyProduct = subscriptionService.products.firstWhere(
        (product) => product.id == SubscriptionService.monthlySubId,
      );
    } catch (e) {
      // If product not found, use a placeholder
      monthlyProduct = ProductDetails(
        id: SubscriptionService.monthlySubId,
        title: 'Monthly Subscription',
        description: 'Pro features for one month',
        price: '\$2.99',
        rawPrice: 2.99,
        currencyCode: 'USD',
        currencySymbol: '\$',
      );
    }

    ProductDetails yearlyProduct;
    try {
      yearlyProduct = subscriptionService.products.firstWhere(
        (product) => product.id == SubscriptionService.yearlySubId,
      );
    } catch (e) {
      // If product not found, use a placeholder
      yearlyProduct = ProductDetails(
        id: SubscriptionService.yearlySubId,
        title: 'Yearly Subscription',
        description: 'Pro features for one year',
        price: '\$24.99',
        rawPrice: 24.99,
        currencyCode: 'USD',
        currencySymbol: '\$',
      );
    }
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Monthly subscription
            if (monthlyProduct != null)
              _buildSubscriptionOption(
                context,
                title: 'Monthly',
                price: monthlyProduct.price,
                description: 'Billed monthly',
                onTap: () => _purchaseSubscription(context, monthlyProduct),
                recommended: false,
              )
            else
              _buildPlaceholderSubscription(
                context,
                title: 'Monthly',
                price: '\$2.99',
                description: 'Billed monthly',
                recommended: false,
              ),
            const SizedBox(height: 16),
            
            // Yearly subscription
            if (yearlyProduct != null)
              _buildSubscriptionOption(
                context,
                title: 'Yearly',
                price: yearlyProduct.price,
                description: 'Billed annually (Save 30%)',
                onTap: () => _purchaseSubscription(context, yearlyProduct),
                recommended: true,
              )
            else
              _buildPlaceholderSubscription(
                context,
                title: 'Yearly',
                price: '\$24.99',
                description: 'Billed annually (Save 30%)',
                recommended: true,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubscriptionOption(
    BuildContext context, {
    required String title,
    required String price,
    required String description,
    required VoidCallback onTap,
    required bool recommended,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: recommended ? colorScheme.primary : Colors.grey.shade300,
              width: recommended ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: recommended ? colorScheme.primaryContainer.withOpacity(0.3) : null,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _isLoading ? null : onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      price,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (recommended)
          Positioned(
            top: 0,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                'BEST VALUE',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildPlaceholderSubscription(
    BuildContext context, {
    required String title,
    required String price,
    required String description,
    required bool recommended,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: recommended ? colorScheme.primary : Colors.grey.shade300,
              width: recommended ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (recommended)
          Positioned(
            top: 0,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                'BEST VALUE',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildOneTimePurchasesCard(BuildContext context) {
    final subscriptionService = Provider.of<SubscriptionService>(context);
    
    // Find one-time purchase products
    ProductDetails removeAdsProduct;
    try {
      removeAdsProduct = subscriptionService.products.firstWhere(
        (product) => product.id == SubscriptionService.removeAdsId,
      );
    } catch (e) {
      // If product not found, use a placeholder
      removeAdsProduct = ProductDetails(
        id: SubscriptionService.removeAdsId,
        title: 'Remove Ads',
        description: 'Remove all advertisements',
        price: '\$4.99',
        rawPrice: 4.99,
        currencyCode: 'USD',
        currencySymbol: '\$',
      );
    }
    
    ProductDetails themesProduct;
    try {
      themesProduct = subscriptionService.products.firstWhere(
        (product) => product.id == SubscriptionService.themesPackId,
      );
    } catch (e) {
      // If product not found, use a placeholder
      themesProduct = ProductDetails(
        id: SubscriptionService.themesPackId,
        title: 'Theme Pack',
        description: 'Unlock premium themes',
        price: '\$1.99',
        rawPrice: 1.99,
        currencyCode: 'USD',
        currencySymbol: '\$',
      );
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'One-Time Purchases',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Remove ads
            if (subscriptionService.removeAds)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Ads Removed',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            else if (removeAdsProduct != null)
              _buildOneTimePurchaseOption(
                context,
                title: 'Remove Ads',
                price: removeAdsProduct.price,
                icon: Icons.block,
                onTap: () => _purchaseProduct(context, removeAdsProduct),
              )
            else
              _buildOneTimePurchaseOption(
                context,
                title: 'Remove Ads',
                price: '\$4.99',
                icon: Icons.block,
                onTap: null,
              ),
            const Divider(),
            
            // Theme pack
            if (themesProduct != null)
              _buildOneTimePurchaseOption(
                context,
                title: 'Premium Themes',
                price: themesProduct.price,
                icon: Icons.palette,
                onTap: () => _purchaseProduct(context, themesProduct),
              )
            else
              _buildOneTimePurchaseOption(
                context,
                title: 'Premium Themes',
                price: '\$1.99',
                icon: Icons.palette,
                onTap: null,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOneTimePurchaseOption(
    BuildContext context, {
    required String title,
    required String price,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading || onTap == null ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _purchaseSubscription(
    BuildContext context,
    dynamic product,
  ) async {
    if (product == null) {
      setState(() {
        _errorMessage = 'Product not available';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
      final success = await subscriptionService.purchaseProduct(product);
      
      if (!success) {
        setState(() {
          _errorMessage = 'Purchase failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _purchaseProduct(
    BuildContext context,
    dynamic product,
  ) async {
    if (product == null) {
      setState(() {
        _errorMessage = 'Product not available';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
      final success = await subscriptionService.purchaseProduct(product);
      
      if (!success) {
        setState(() {
          _errorMessage = 'Purchase failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _restorePurchases(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
      await subscriptionService.restorePurchases();
    } catch (e) {
      setState(() {
        _errorMessage = 'Restore failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
