import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/monetization_service.dart';
import '../../core/services/secure_entitlements.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  final AdSize adSize;
  const BannerAdWidget({super.key, this.adSize = AdSize.banner});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isPremium = true; // Assume premium until verified

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
    _bannerAd = await MonetizationService().createBannerAd();
    if (mounted) {
      setState(() {
        _isLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPremium || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
