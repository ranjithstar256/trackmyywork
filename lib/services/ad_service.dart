import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../services/subscription_service.dart';

class AdService extends ChangeNotifier {
  static const bool _testMode = true;
  
  // Test ad units
  static const String _testBannerAdUnitIdAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerAdUnitIdiOS = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialAdUnitIdAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialAdUnitIdiOS = 'ca-app-pub-3940256099942544/4411468910';
  
  // Production ad units - replace these with your actual ad unit IDs from AdMob
  static const String _prodBannerAdUnitIdAndroid = 'YOUR_ANDROID_BANNER_AD_UNIT_ID';
  static const String _prodBannerAdUnitIdiOS = 'YOUR_IOS_BANNER_AD_UNIT_ID';
  static const String _prodInterstitialAdUnitIdAndroid = 'YOUR_ANDROID_INTERSTITIAL_AD_UNIT_ID';
  static const String _prodInterstitialAdUnitIdiOS = 'YOUR_IOS_INTERSTITIAL_AD_UNIT_ID';
  
  bool _isInitialized = false;
  
  // Initialize the service
  Future<void> init() async {
    if (!_isInitialized) {
      await MobileAds.instance.initialize();
      _isInitialized = true;
    }
    notifyListeners();
  }
  
  // Get the appropriate ad unit ID based on platform and mode
  String get bannerAdUnitId {
    if (_testMode) {
      return Platform.isAndroid ? _testBannerAdUnitIdAndroid : _testBannerAdUnitIdiOS;
    } else {
      return Platform.isAndroid ? _prodBannerAdUnitIdAndroid : _prodBannerAdUnitIdiOS;
    }
  }
  
  String get interstitialAdUnitId {
    if (_testMode) {
      return Platform.isAndroid ? _testInterstitialAdUnitIdAndroid : _testInterstitialAdUnitIdiOS;
    } else {
      return Platform.isAndroid ? _prodInterstitialAdUnitIdAndroid : _prodInterstitialAdUnitIdiOS;
    }
  }
  
  // Create a banner ad
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => debugPrint('Ad loaded: ${ad.adUnitId}'),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Ad failed to load: ${ad.adUnitId}, $error');
        },
      ),
    );
  }
  
  // Load and show an interstitial ad
  Future<void> showInterstitialAd(BuildContext context) async {
    // Check if user has removed ads
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    if (subscriptionService.removeAds) {
      return;
    }
    
    InterstitialAd? interstitialAd;
    
    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd = ad;
            interstitialAd!.show();
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial ad failed to load: $error');
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading interstitial ad: $e');
    }
  }
}

// Banner ad widget that respects subscription status
class AdBanner extends StatefulWidget {
  const AdBanner({Key? key}) : super(key: key);

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final adService = Provider.of<AdService>(context, listen: false);
    _bannerAd = adService.createBannerAd();
    _bannerAd?.load().then((value) {
      setState(() {
        _isAdLoaded = true;
      });
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionService = Provider.of<SubscriptionService>(context);
    
    // Don't show ads for premium users
    if (subscriptionService.removeAds) {
      return const SizedBox.shrink();
    }
    
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        alignment: Alignment.center,
        child: AdWidget(ad: _bannerAd!),
      );
    }
    
    // Return a placeholder while the ad is loading
    return SizedBox(
      height: 50,
      child: Center(
        child: Text(
          'Advertisement',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
