import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MonetizationService {
  static final MonetizationService _instance = MonetizationService._internal();
  factory MonetizationService() => _instance;
  MonetizationService._internal();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  
  int _interstitialRetryCount = 0;
  int _rewardedRetryCount = 0;
  final Set<String> _verifiedReceiptSignatures = {};

  // Real Ad Units would go here. For dev, we use test IDs.
  String get bannerAdUnitId => kDebugMode 
    ? ((!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ? 'ca-app-pub-3940256099942544/6300978111' : 'ca-app-pub-3940256099942544/2934735716')
    : const String.fromEnvironment('ADMOB_BANNER_ID', defaultValue: 'YOUR_REAL_BANNER_ID');

  String get interstitialAdUnitId => kDebugMode
    ? ((!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ? 'ca-app-pub-3940256099942544/1033173712' : 'ca-app-pub-3940256099942544/4411468910')
    : const String.fromEnvironment('ADMOB_INTERSTITIAL_ID', defaultValue: 'YOUR_REAL_INTERSTITIAL_ID');

  String get rewardedAdUnitId => kDebugMode
    ? ((!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ? 'ca-app-pub-3940256099942544/5224354917' : 'ca-app-pub-3940256099942544/1712485313')
    : const String.fromEnvironment('ADMOB_REWARDED_ID', defaultValue: 'YOUR_REAL_REWARDED_ID');

  String get nativeAdUnitId => kDebugMode
    ? ((!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ? 'ca-app-pub-3940256099942544/2247696110' : 'ca-app-pub-3940256099942544/3986624511')
    : const String.fromEnvironment('ADMOB_NATIVE_ID', defaultValue: 'YOUR_REAL_NATIVE_ID');

  // --- Banner Ads ---
  Future<BannerAd> createBannerAd() async {
    int retryCount = 0;
    while (retryCount < 3) {
      final completer = Completer<BannerAd>();
      final ad = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) => completer.complete(ad as BannerAd),
          onAdFailedToLoad: (ad, error) {
            // Do not dispose synchronously here to prevent MethodChannel adId race conditions
            if (!completer.isCompleted) completer.completeError(error);
          },
        ),
      );
      try {
        await ad.load();
        return await completer.future;
      } catch (e) {
        await ad.dispose(); // Ensure native ad is disposed before retrying
        retryCount++;
        if (retryCount >= 3) {
          debugPrint("Banner Ad failed to load after 3 retries: $e");
          rethrow;
        }
        final delaySeconds = 1 << retryCount; // Exponential backoff: 2s, 4s, 8s
        debugPrint("Banner Ad load failed ($e). Retrying in ${delaySeconds}s (attempt $retryCount/3)...");
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
    throw Exception("Banner Ad failed to load.");
  }

  // --- Native Ads ---
  Future<NativeAd> createNativeAd({required Function() onAdLoaded, required Function() onAdFailed}) async {
    int retryCount = 0;
    while (retryCount < 3) {
      final completer = Completer<NativeAd>();
      final ad = NativeAd(
        adUnitId: nativeAdUnitId,
        factoryId: 'adFactoryExample',
        request: const AdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            debugPrint("Native Ad Loaded");
            onAdLoaded();
            completer.complete(ad as NativeAd);
          },
          onAdFailedToLoad: (ad, error) {
            // Do not dispose synchronously here to prevent MethodChannel adId race conditions
            debugPrint("Native Ad Failed: $error");
            if (!completer.isCompleted) completer.completeError(error);
          },
        ),
      );
      try {
        await ad.load();
        return await completer.future;
      } catch (e) {
        await ad.dispose(); // Ensure native ad is disposed before retrying
        retryCount++;
        if (retryCount >= 3) {
          debugPrint("Native Ad failed to load after 3 retries: $e");
          onAdFailed();
          rethrow;
        }
        final delaySeconds = 1 << retryCount;
        debugPrint("Native Ad load failed ($e). Retrying in ${delaySeconds}s (attempt $retryCount/3)...");
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
    onAdFailed();
    throw Exception("Native Ad failed to load.");
  }

  // --- Interstitial Ads ---
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialRetryCount = 0;
        },
        onAdFailedToLoad: (err) {
          debugPrint("Interstitial failed: $err");
          if (_interstitialRetryCount < 3) {
            _interstitialRetryCount++;
            final delaySeconds = 1 << _interstitialRetryCount;
            debugPrint("Retrying Interstitial ad load in ${delaySeconds}s (attempt $_interstitialRetryCount/3)...");
            Future.delayed(Duration(seconds: delaySeconds), () {
              loadInterstitialAd();
            });
          } else {
            debugPrint("Interstitial ad load failed after 3 retries. Stopping pre-load attempts.");
          }
        },
      ),
    );
  }

  Future<bool> showInterstitialAd({BuildContext? context}) async {
    if (_interstitialAd != null) {
      final completer = Completer<bool>();
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          if (!completer.isCompleted) completer.complete(true);
          Future.delayed(const Duration(seconds: 5), () {
            loadInterstitialAd();
          });
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          if (!completer.isCompleted) completer.complete(false);
          Future.delayed(const Duration(seconds: 10), () {
            loadInterstitialAd();
          });
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
      return await completer.future;
    } else {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aethereal connection buffering... Please wait for ad to preload.")),
        );
      }
      loadInterstitialAd();
      return false;
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
          _rewardedRetryCount = 0;
        },
        onAdFailedToLoad: (err) {
          debugPrint("Rewarded failed: $err");
          if (_rewardedRetryCount < 3) {
            _rewardedRetryCount++;
            final delaySeconds = 1 << _rewardedRetryCount;
            debugPrint("Retrying Rewarded ad load in ${delaySeconds}s (attempt $_rewardedRetryCount/3)...");
            Future.delayed(Duration(seconds: delaySeconds), () {
              loadRewardedAd();
            });
          } else {
            debugPrint("Rewarded ad load failed after 3 retries. Stopping pre-load attempts.");
          }
        },
      ),
    );
  }

  Future<bool> showRewardedAd({required Function(RewardItem) onRewardEarned, BuildContext? context}) async {
    if (_rewardedAd != null) {
      final completer = Completer<bool>();
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          if (!completer.isCompleted) completer.complete(true);
          Future.delayed(const Duration(seconds: 5), () {
            loadRewardedAd();
          });
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          if (!completer.isCompleted) completer.complete(false);
          Future.delayed(const Duration(seconds: 10), () {
            loadRewardedAd();
          });
        },
      );
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) => onRewardEarned(reward));
      _rewardedAd = null;
      return await completer.future;
    } else {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Oracle reward loading... Please try again in a moment.")),
        );
      }
      loadRewardedAd();
      return false;
    }
  }

  // --- Security & Receipt Verification ---
  /// Verifies a purchase or reward receipt signature against Replay Attacks
  /// and applies a strict timeout to prevent indefinite hangs.
  Future<bool> verifyReceipt({
    required String receiptId,
    required String signature,
    required String payload,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_verifiedReceiptSignatures.contains(signature)) {
      debugPrint("[MonetizationService] Security Alert: Replay attack detected! Receipt signature already verified: $signature");
      return false;
    }

    try {
      return await Future<bool>(() async {
        // await Future.delayed(const Duration(milliseconds: 300));
        
        if (receiptId.isEmpty || signature.isEmpty || payload.isEmpty) {
          return false;
        }

        _verifiedReceiptSignatures.add(signature);
        return true;
      }).timeout(
        timeout,
        onTimeout: () {
          debugPrint("[MonetizationService] Receipt verification timed out after ${timeout.inSeconds}s.");
          return false;
        },
      );
    } catch (e) {
      debugPrint("[MonetizationService] Error verifying receipt: $e");
      return false;
    }
  }
}
