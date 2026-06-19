import 'package:cloud_firestore/cloud_firestore.dart';

class RiskConfigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Default configuration for risk detection thresholds.
  static const Map<String, dynamic> _defaultConfig = {
    'promoRedemptionBurstLimit': 5, // 5 per min
    'repeatedSosThreshold': 3, // 3 in 10 mins
    'impossibleLocationJumpKmH': 300.0, // Commercial flight speed? or high speed?
    'maxSessionsPerHour': 1, // per guide
    'maxReviewFlagsBeforeHide': 3,
    'reviewWindowDaysToExpiry': 14,
    'minAvgRatingForWatchlist': 3.5,
  };

  /// Collection: risk_rules
  Future<Map<String, dynamic>> getConfig() async {
    final doc = await _firestore.collection('config').doc('risk_rules').get();
    if (!doc.exists) return _defaultConfig;
    return doc.data()!;
  }

  Future<void> updateConfig(Map<String, dynamic> newConfig) async {
    await _firestore.collection('config').doc('risk_rules').set(newConfig, SetOptions(merge: true));
  }

  /// Helper to get a specific threshold value with default fallback.
  Future<T> getThreshold<T>(String key, T defaultValue) async {
    final config = await getConfig();
    return (config[key] ?? defaultValue) as T;
  }
}
