import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/subscription_service.dart';

class PremiumFeaturesService {
  // Check if user can access a premium feature
  static bool canAccessFeature(BuildContext context, PremiumFeature feature) {
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    
    switch (feature) {
      case PremiumFeature.unlimitedActivities:
        return subscriptionService.isPro;
      case PremiumFeature.unlimitedHistory:
        return subscriptionService.isPro;
      case PremiumFeature.advancedReports:
        return subscriptionService.isPro;
      case PremiumFeature.dataExport:
        return subscriptionService.isPro;
      case PremiumFeature.customThemes:
        return subscriptionService.isPro || 
               subscriptionService.purchasedThemes.isNotEmpty;
      case PremiumFeature.removeAds:
        return subscriptionService.removeAds;
      default:
        return false;
    }
  }
  
  // Get activity limit based on subscription
  static int getActivityLimit(BuildContext context) {
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    return subscriptionService.activityLimit;
  }
  
  // Get history days limit based on subscription
  static int getHistoryDaysLimit(BuildContext context) {
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    return subscriptionService.historyDaysLimit;
  }
  
  // Show premium feature promotion dialog
  static Future<void> showPremiumFeatureDialog(
    BuildContext context, 
    PremiumFeature feature,
  ) async {
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    
    String title;
    String description;
    
    switch (feature) {
      case PremiumFeature.unlimitedActivities:
        title = 'Unlimited Activities';
        description = 'Upgrade to Pro to track unlimited activities. Free users are limited to ${subscriptionService.activityLimit} activities.';
        break;
      case PremiumFeature.unlimitedHistory:
        title = 'Unlimited History';
        description = 'Upgrade to Pro to access your complete tracking history. Free users can only access the last ${subscriptionService.historyDaysLimit} days.';
        break;
      case PremiumFeature.advancedReports:
        title = 'Advanced Reports';
        description = 'Upgrade to Pro to access detailed analytics and advanced reporting features.';
        break;
      case PremiumFeature.dataExport:
        title = 'Data Export';
        description = 'Upgrade to Pro to export your data in CSV or PDF format.';
        break;
      case PremiumFeature.customThemes:
        title = 'Custom Themes';
        description = 'Upgrade to Pro to access all premium themes or purchase individual theme packs.';
        break;
      case PremiumFeature.removeAds:
        title = 'Remove Ads';
        description = 'Upgrade to Pro to remove all advertisements or purchase the ad-free option separately.';
        break;
      default:
        title = 'Premium Feature';
        description = 'This feature is only available with a Pro subscription.';
    }
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 16),
            Text(
              'Upgrade to Pro for just \$2.99/month or \$24.99/year.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/subscription');
            },
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }
}

// Premium features enum
enum PremiumFeature {
  unlimitedActivities,
  unlimitedHistory,
  advancedReports,
  dataExport,
  customThemes,
  removeAds,
}

// Widget that shows a premium feature lock overlay
class PremiumFeatureLock extends StatelessWidget {
  final Widget child;
  final PremiumFeature feature;
  final bool showLockIcon;
  
  const PremiumFeatureLock({
    Key? key,
    required this.child,
    required this.feature,
    this.showLockIcon = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final canAccess = PremiumFeaturesService.canAccessFeature(context, feature);
    
    if (canAccess) {
      return child;
    }
    
    return Stack(
      children: [
        Opacity(
          opacity: 0.5,
          child: child,
        ),
        if (showLockIcon)
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 24,
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => PremiumFeaturesService.showPremiumFeatureDialog(
                context,
                feature,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
