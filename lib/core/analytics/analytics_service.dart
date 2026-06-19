import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    final Map<String, Object>? safeParams = _truncateParameters(parameters);
    await _analytics.logEvent(name: name, parameters: safeParams);
    debugPrint("[Analytics] Logged Event: $name | Params: $safeParams");
  }

  Map<String, Object>? _truncateParameters(Map<String, Object>? params) {
    if (params == null) return null;
    return params.map((key, value) {
      if (value is String && value.length > 500) {
        return MapEntry(key, '${value.substring(0, 497)}...');
      }
      return MapEntry(key, value);
    });
  }

  Future<void> logPlanGenerated({
    required String destination,
    required String style,
    required int days,
    required int verifiedScore,
  }) async {
    await logEvent('plan_generated', parameters: {
      'destination': destination,
      'style': style,
      'days': days,
      'verified_score': verifiedScore,
    });
  }

  Future<void> logPremiumPurchased(String productId) async {
    await logEvent('premium_purchased', parameters: {
      'product_id': productId,
    });
  }

  Future<void> logLandmarkScanUsed(String landmark) async {
    await logEvent('landmark_scan_used', parameters: {
      'landmark_name': landmark,
    });
  }

  Future<void> logPlanBTriggered(String city) async {
    await logEvent('plan_b_clicked', parameters: {
      'city': city,
    });
  }

  Future<void> setUserProperties({required String userId, required String role}) async {
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'user_role', value: role);
  }

  // Phase 9: AR Mode Analytics
  Future<void> logARSessionStarted({
    required String placeName,
    required int tier,
    required String mode, // 'full', 'demo', 'fallback'
  }) async {
    await logEvent('ar_session_started', parameters: {
      'place_name': placeName,
      'ar_tier': tier,
      'mode': mode,
    });
  }

  Future<void> logARPhotoShared({
    required String placeName,
    required String platform,
  }) async {
    await logEvent('ar_photo_shared', parameters: {
      'place_name': placeName,
      'platform': platform,
    });
  }

  Future<void> logARHotspotTapped({
    required String placeName,
    required String hotspotId,
  }) async {
    await logEvent('ar_hotspot_tapped', parameters: {
      'place_name': placeName,
      'hotspot_id': hotspotId,
    });
  }

  Future<void> logARUpgradeClicked({
    required String placeName,
    required String source, // 'details', 'viewer', 'demo'
  }) async {
    await logEvent('ar_upgrade_clicked', parameters: {
      'place_name': placeName,
      'source': source,
    });
  }
}
