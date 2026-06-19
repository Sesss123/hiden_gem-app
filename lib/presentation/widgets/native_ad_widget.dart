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
    _checkEntitlements();
  }

  Future<void> _checkEntitlements() async {
    final isPremium = await SecureEntitlements().verifyPremium();
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
      });
      if (!isPremium) {
        _loadAd();
      }
    }
  }

  void _loadAd() async {
    if (kIsWeb) return; // Native ads are not supported on web
    
    _nativeAd = await MonetizationService().createNativeAd(
      onAdLoaded: () {
        if (mounted) setState(() => _isLoaded = true);
      },
      onAdFailed: () {
        if (mounted) setState(() => _isLoaded = false);
      },
    );
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremium) {
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
      height: 300, // Adjust based on your ad size
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
