import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../data/datasources/monetization_service.dart';
import '../../core/services/secure_entitlements.dart';
import '../../core/theme/oracle_ui_system.dart';
import 'banner_ad_widget.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isPremium = true;

  @override
  void initState() {
    super.initState();
    MonetizationService().adsEnabledListenable.addListener(_onAdsToggleChanged);
    _checkEntitlements();
  }

  void _onAdsToggleChanged() {
    if (!mounted) return;
    if (!MonetizationService().isAdsEnabled) {
      _nativeAd?.dispose();
      setState(() { _nativeAd = null; _isLoaded = false; });
    } else if (!_isPremium && _nativeAd == null) {
      _loadAd();
    }
  }

  Future<void> _checkEntitlements() async {
    final isPremium = await SecureEntitlements().verifyPremium();
    final isAdsEnabled = MonetizationService().isAdsEnabled;
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
      });
      if (!isPremium && isAdsEnabled) {
        _loadAd();
      }
    }
  }

  void _loadAd() async {
    if (kIsWeb) return; // Native ads are not supported on web
    if (!MonetizationService().isAdsEnabled) return;

    try {
      _nativeAd = await MonetizationService().createNativeAd(
        onAdLoaded: () {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailed: () {
          if (mounted) setState(() => _isLoaded = false);
        },
      );
    } catch (_) {
      // Graceful fallback
    }
  }

  @override
  void dispose() {
    MonetizationService().adsEnabledListenable.removeListener(_onAdsToggleChanged);
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!MonetizationService().isAdsEnabled || _isPremium) {
      return const SizedBox.shrink();
    }

    if (kIsWeb) {
      return const BannerAdWidget(adSize: AdSize.mediumRectangle);
    }

    if (!_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return OracleUI.glassContainer(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: EdgeInsets.zero,
      // The native layout only contains wrap-content headline/body fields.
      // Keeping a 300dp host produced a large blank block in the feed.
      height: 88,
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
