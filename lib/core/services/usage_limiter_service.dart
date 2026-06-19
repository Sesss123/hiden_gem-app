import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/user_profile.dart';
import '../../data/datasources/user_preference_service.dart';

class UsageLimiterService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Default Fallback Constraints if Firestore fails
  static const Map<String, Map<String, dynamic>> _defaultLimits = {
    'user': {
      'ai_plans_per_month': 3,
      'saved_plans': 2,
      'ar_sessions_per_month': 1,
    },
    'explorer': {
      'ai_plans_per_month': 20,
      'saved_plans': 10,
      'ar_sessions_per_month': 3,
    },
    'premium': {
      'ai_plans_per_month': 50,
      'saved_plans': 25,
      'ar_sessions_per_month': 9999, // Unlimited
    }
  };

  /// Verify and reset limits if entering a new billing month
  static Future<void> checkAndResetLimits(UserProfile profile) async {
    final now = DateTime.now();

    if (profile.usageResetDate == null || now.isAfter(profile.usageResetDate!)) {
      debugPrint("UsageLimiterService: Resetting counters for new billing period.");
      
      profile.aiTripsUsedThisMonth = 0;
      profile.arSessionsUsedThisMonth = 0;
      profile.offlineDownloadsUsed = 0;
      
      // Calculate next reset date (next 30 days)
      profile.usageResetDate = now.add(const Duration(days: 30));

      await UserPreferenceService.saveProfile(profile);

      // Sync to Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'aiTripsUsedThisMonth': 0,
          'arSessionsUsedThisMonth': 0,
          'offlineDownloadsUsed': 0,
          'usageResetDate': profile.usageResetDate?.toIso8601String(),
        });
      }
    }
  }

  /// Get the limit mapped to the current plan role
  static Future<int> _getLimitForFeature(String featureKey, UserProfile profile) async {
    final bool hasValidPremium = _isPremiumValid(profile);
    final String effectivePlan = hasValidPremium ? (profile.premiumPlan ?? 'premium') : 'user';
    
    try {
      final doc = await _firestore.collection('plans').doc(effectivePlan).get();
      if (doc.exists && doc.data() != null) {
        final limits = doc.data()!['limits'] as Map<String, dynamic>?;
        if (limits != null && limits.containsKey(featureKey)) {
          return limits[featureKey] as int;
        }
      }
    } catch (e) {
      debugPrint("UsageLimiterService: Fallback triggered. Error fetching Firestore limits: $e");
    }

    // Fallback if remote fetch fails
    final fallbackPlan = _defaultLimits.containsKey(effectivePlan) ? effectivePlan : 'user';
    return _defaultLimits[fallbackPlan]![featureKey];
  }

  /// Checks if AI generation is allowed within the user's limit constraints
  static Future<bool> canGenerateAiTrip() async {
    final profile = UserPreferenceService.getProfile();
    await checkAndResetLimits(profile);

    final limit = await _getLimitForFeature('ai_plans_per_month', profile);
    return profile.aiTripsUsedThisMonth < limit;
  }

  /// Marks a trip as generated and increments the meter
  static Future<void> incrementAiTrip() async {
    final profile = UserPreferenceService.getProfile();
    profile.aiTripsUsedThisMonth++;
    await UserPreferenceService.saveProfile(profile);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'aiTripsUsedThisMonth': profile.aiTripsUsedThisMonth,
      });
    }
  }

  /// Checks if the user's premium status is active and not expired
  static bool _isPremiumValid(UserProfile profile) {
    if (!profile.isPremium) return false;
    if (profile.premiumExpiresAt == null) return true; // Lifetime or managed elsewhere
    return DateTime.now().isBefore(profile.premiumExpiresAt!);
  }

  /// Provides one-time bonus access to AI trip generation (e.g. after watching a rewarded ad)
  static Future<void> provideBonusAiTrip() async {
    final profile = UserPreferenceService.getProfile();
    // Reduce used count (or we could use a separate bonus field, but this is simpler)
    if (profile.aiTripsUsedThisMonth > 0) {
      profile.aiTripsUsedThisMonth--;
      await UserPreferenceService.saveProfile(profile);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'aiTripsUsedThisMonth': profile.aiTripsUsedThisMonth,
        });
      }
    }
  }

  /// Provides one-time bonus access to AR session
  static Future<void> provideBonusArSession() async {
    final profile = UserPreferenceService.getProfile();
    if (profile.arSessionsUsedThisMonth > 0) {
      profile.arSessionsUsedThisMonth--;
      await UserPreferenceService.saveProfile(profile);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'arSessionsUsedThisMonth': profile.arSessionsUsedThisMonth,
        });
      }
    }
  }

  /// Checks if AR session access is allowed within the user's limit constraints
  static Future<bool> canAccessArSession() async {
    final profile = UserPreferenceService.getProfile();
    
    // Core Logic: Valid Premium users have unlimited AR
    if (_isPremiumValid(profile)) return true;
    
    await checkAndResetLimits(profile);
    final limit = await _getLimitForFeature('ar_sessions_per_month', profile);
    return profile.arSessionsUsedThisMonth < limit;
  }

  /// Marks an AR session as launched and increments the usage meter
  static Future<void> incrementArSession() async {
    final profile = UserPreferenceService.getProfile();
    profile.arSessionsUsedThisMonth++;
    await UserPreferenceService.saveProfile(profile);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'arSessionsUsedThisMonth': profile.arSessionsUsedThisMonth,
      });
    }
  }

  // --- Offline Downloads ---

  /// Checks if offline download is allowed
  static Future<bool> canDownloadOffline() async {
    final profile = UserPreferenceService.getProfile();
    if (_isPremiumValid(profile)) return true;
    
    await checkAndResetLimits(profile);
    // Use 'saved_plans' as the proxy for offline downloads if not explicitly defined in DB
    final limit = await _getLimitForFeature('saved_plans', profile);
    return profile.offlineDownloadsUsed < limit;
  }

  /// Increments offline download counter
  static Future<void> incrementOfflineDownload() async {
    final profile = UserPreferenceService.getProfile();
    profile.offlineDownloadsUsed++;
    await UserPreferenceService.saveProfile(profile);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'offlineDownloadsUsed': profile.offlineDownloadsUsed,
      });
    }
  }

  /// Provides bonus offline download via rewarded ad
  static Future<void> provideBonusOfflineDownload() async {
    final profile = UserPreferenceService.getProfile();
    if (profile.offlineDownloadsUsed > 0) {
      profile.offlineDownloadsUsed--;
      await UserPreferenceService.saveProfile(profile);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'offlineDownloadsUsed': profile.offlineDownloadsUsed,
        });
      }
    }
  }
}
