import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MonetizationService {
  static final MonetizationService _instance = MonetizationService._internal();
  factory MonetizationService() => _instance;
  MonetizationService._internal();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Real Ad Units would go here. For dev, we use test IDs.
  String get bannerAdUnitId => kDebugMode 
    ? ((!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ? 'ca-app-pub-3940256099942544/6300978111' : 'ca-app-pub-3940256099942544/2934735716')
    : 'YOUR_REAL_BANNER_ID';

  String get interstitialAdUnitId => kDebugMode
    ? ((!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ? 'ca-app-pub-3940256099942544/1033173712' : 'ca-app-pub-3940256099942544/4411468910')
    : 'YOUR_REAL_INTERSTITIAL_ID';

  String get rewardedAdUnitId => kDebugMode
    ? ((!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ? 'ca-app-pub-3940256099942544/5224354917' : 'ca-app-pub-3940256099942544/1712485313')
    : 'YOUR_REAL_REWARDED_ID';

  String get nativeAdUnitId => kDebugMode
    ? ((!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ? 'ca-app-pub-3940256099942544/2247696110' : 'ca-app-pub-3940256099942544/3986624511')
    : 'YOUR_REAL_NATIVE_ID';

  // --- Banner Ads ---
  Future<BannerAd> createBannerAd() async {
    final ad = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => debugPrint("Banner Loaded: ${ad.adUnitId}"),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint("Banner Failed to Load: $error");
        },
      ),
    );
    await ad.load();
    return ad;
  }

  // --- Native Ads ---
  Future<NativeAd> createNativeAd({required Function() onAdLoaded, required Function() onAdFailed}) async {
    final ad = NativeAd(
      adUnitId: nativeAdUnitId,
      factoryId: 'adFactoryExample', // This needs to be implemented on native side for custom UI, or use default
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint("Native Ad Loaded");
          onAdLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint("Native Ad Failed: $error");
          onAdFailed();
        },
      ),
    );
    await ad.load();
    return ad;
  }

  // --- Interstitial Ads ---
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              // Delay preloading next interstitial to save user data
              Future.delayed(const Duration(seconds: 5), () {
                loadInterstitialAd();
              });
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              Future.delayed(const Duration(seconds: 10), () {
                loadInterstitialAd();
              });
            },
          );
        },
        onAdFailedToLoad: (err) => debugPrint("Interstitial failed: $err"),
      ),
    );
  }

  void showInterstitialAd({BuildContext? context}) {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aethereal connection buffering... Please wait for ad to preload.")),
        );
      }
      loadInterstitialAd();
    }
  }

  // --- Rewarded Ads ---
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (err) => debugPrint("Rewarded failed: $err"),
      ),
    );
  }

  void showRewardedAd({required Function(RewardItem) onRewardEarned, BuildContext? context}) {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          Future.delayed(const Duration(seconds: 5), () {
            loadRewardedAd();
          });
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          Future.delayed(const Duration(seconds: 10), () {
            loadRewardedAd();
          });
        },
      );
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) => onRewardEarned(reward));
      _rewardedAd = null;
    } else {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Oracle reward loading... Please try again in a moment.")),
        );
      }
      loadRewardedAd();
    }
  }
}
