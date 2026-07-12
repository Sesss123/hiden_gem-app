import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/user_profile.dart';
import '../../data/datasources/user_preference_service.dart';
import '../../data/datasources/trip_cache_service.dart';
import 'secure_entitlements.dart';

class UsageLimiterService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Plan limits (Firestore `plans/{planId}`) change only when an admin
  // edits a tier — not per-user, not per-action. Caching them in memory
  // avoids a fresh Firestore read on every AI-trip/AR-session/offline-download
  // check and every UsageMeterWidget mount, which otherwise re-fetches the
  // same 3 possible plan docs constantly within a session.
  static final Map<String, Map<String, dynamic>> _planLimitsCache = {};
  static final Map<String, DateTime> _planLimitsCachedAt = {};
  static const Duration _planLimitsCacheWindow = Duration(hours: 1);

  /// Clears the cached plan-limits map. Call this whenever the user's
  /// premium/plan status changes mid-session (e.g. a RevenueCat purchase
  /// completes) so the next limit check re-fetches the correct plan's
  /// limits instead of serving a stale entry for up to an hour.
  static void invalidatePlanLimitsCache() {
    _planLimitsCache.clear();
    _planLimitsCachedAt.clear();
  }

  // Default Fallback Constraints if Firestore fails
  static const Map<String, Map<String, dynamic>> _defaultLimits = {
    'user': {
      'ai_plans_per_month': 3,
      'saved_plans': 2,
      'offline_downloads_per_month': 2,
      'ar_sessions_per_month': 1,
    },
    'explorer': {
      'ai_plans_per_month': 20,
      'saved_plans': 10,
      'offline_downloads_per_month': 10,
      'ar_sessions_per_month': 3,
    },
    'premium': {
      'ai_plans_per_month': 50,
      'saved_plans': 25,
      'offline_downloads_per_month': 9999, // Unlimited
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
    final bool hasValidPremium = await _isPremiumValid(profile);
    final String effectivePlan = hasValidPremium ? (profile.premiumPlan ?? 'premium') : 'user';

    final limits = await _getPlanLimits(effectivePlan);
    if (limits != null && limits.containsKey(featureKey)) {
      return limits[featureKey] as int;
    }

    // Fallback if remote fetch fails
    final fallbackPlan = _defaultLimits.containsKey(effectivePlan) ? effectivePlan : 'user';
    return _defaultLimits[fallbackPlan]![featureKey];
  }

  /// Returns `plans/{planId}.limits`, served from an in-memory cache when
  /// fresh. Falls back to Firestore on a cache miss/expiry.
  static Future<Map<String, dynamic>?> _getPlanLimits(String planId) async {
    final cachedAt = _planLimitsCachedAt[planId];
    if (cachedAt != null && DateTime.now().difference(cachedAt) < _planLimitsCacheWindow) {
      return _planLimitsCache[planId];
    }

    try {
      final doc = await _firestore.collection('plans').doc(planId).get();
      final limits = doc.exists ? (doc.data()?['limits'] as Map<String, dynamic>?) : null;
      if (limits != null) {
        _planLimitsCache[planId] = limits;
        _planLimitsCachedAt[planId] = DateTime.now();
      }
      return limits;
    } catch (e) {
      debugPrint("UsageLimiterService: Fallback triggered. Error fetching Firestore limits: $e");
      return _planLimitsCache[planId]; // Serve stale cache over hitting fallback constants, if we have it
    }
  }

  /// Checks if AI generation is allowed within the user's limit constraints
  static Future<bool> canGenerateAiTrip() async {
    final profile = UserPreferenceService.getProfile();
    await checkAndResetLimits(profile);

    final limit = await _getLimitForFeature('ai_plans_per_month', profile);
    return profile.aiTripsUsedThisMonth < limit;
  }

  /// Atomically checks-and-increments a monthly usage counter field inside a
  /// Firestore transaction, so N parallel calls (rapid-tap, scripted replay)
  /// can never all read the same "under limit" snapshot and all succeed —
  /// each transaction serializes against the real committed count. Returns
  /// true if the increment was allowed (and applied), false if the limit was
  /// already reached (no write happens). Falls back to allowing the action
  /// if there's no signed-in user (matches the prior local-only behavior for
  /// guest/offline use — the local profile counter below still applies).
  static Future<bool> _atomicCheckAndIncrement({
    required String counterField,
    required int limit,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return true;

    final docRef = _firestore.collection('users').doc(user.uid);
    try {
      return await _firestore.runTransaction<bool>((tx) async {
        final snap = await tx.get(docRef);
        final current = (snap.data()?[counterField] as int?) ?? 0;
        if (current >= limit) return false;
        tx.update(docRef, {counterField: current + 1});
        return true;
      });
    } catch (e) {
      debugPrint("UsageLimiterService: Atomic increment failed for $counterField: $e");
      return false;
    }
  }

  /// Marks a trip as generated and increments the meter. Atomic against
  /// concurrent calls — see _atomicCheckAndIncrement. Returns whether the
  /// increment was actually allowed (the quota might have been exhausted by
  /// a concurrent call between canGenerateAiTrip()'s check and this call).
  static Future<bool> incrementAiTrip() async {
    final profile = UserPreferenceService.getProfile();
    await checkAndResetLimits(profile);
    final limit = await _getLimitForFeature('ai_plans_per_month', profile);

    final allowed = await _atomicCheckAndIncrement(counterField: 'aiTripsUsedThisMonth', limit: limit);
    if (allowed) {
      profile.aiTripsUsedThisMonth++;
      await UserPreferenceService.saveProfile(profile);
    }
    return allowed;
  }

  /// Checks if the user's premium status is active and not expired.
  ///
  /// SECURITY: This is the gate for every usage limit in this service, so it
  /// must not trust the raw local profile alone — a locally-patched profile
  /// (rooted device, tampered APK) could otherwise set isPremium: true and
  /// bypass every AI-trip/AR-session/offline-download/saved-plan limit.
  /// SecureEntitlements().verifyPremium() re-validates against the server
  /// (with its own 5-minute memory / 24-hour disk cache, so this isn't a
  /// fresh network call on every check) and cryptographically verifies the
  /// expiry signature before trusting it.
  static Future<bool> _isPremiumValid(UserProfile profile) async {
    if (!profile.isPremium) return false;
    return SecureEntitlements().verifyPremium();
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
    if (await _isPremiumValid(profile)) return true;
    
    await checkAndResetLimits(profile);
    final limit = await _getLimitForFeature('ar_sessions_per_month', profile);
    return profile.arSessionsUsedThisMonth < limit;
  }

  /// Marks an AR session as launched and increments the usage meter.
  /// Atomic against concurrent calls — see _atomicCheckAndIncrement. Returns
  /// whether the increment was actually allowed.
  static Future<bool> incrementArSession() async {
    final profile = UserPreferenceService.getProfile();
    if (await _isPremiumValid(profile)) {
      final allowed = await _atomicCheckAndIncrement(counterField: 'arSessionsUsedThisMonth', limit: 9999);
      if (allowed) {
        profile.arSessionsUsedThisMonth++;
        await UserPreferenceService.saveProfile(profile);
      }
      return allowed;
    }

    await checkAndResetLimits(profile);
    final limit = await _getLimitForFeature('ar_sessions_per_month', profile);
    final allowed = await _atomicCheckAndIncrement(counterField: 'arSessionsUsedThisMonth', limit: limit);
    if (allowed) {
      profile.arSessionsUsedThisMonth++;
      await UserPreferenceService.saveProfile(profile);
    }
    return allowed;
  }

  // --- Saved Plans ---

  /// Checks whether the tourist can save another trip plan. Unlike the AI
  /// trip / AR session / offline download counters, saved plans don't reset
  /// monthly — the limit is a running total of how many plans exist in
  /// TripCacheService.savedPlanCount, which is decremented naturally when
  /// the tourist deletes an old saved plan.
  static Future<bool> canSavePlan() async {
    final profile = UserPreferenceService.getProfile();
    if (await _isPremiumValid(profile)) return true;

    final limit = await _getLimitForFeature('saved_plans', profile);
    return TripCacheService.savedPlanCount < limit;
  }

  // --- Offline Downloads ---

  /// Checks if offline download is allowed
  static Future<bool> canDownloadOffline() async {
    final profile = UserPreferenceService.getProfile();
    if (await _isPremiumValid(profile)) return true;
    
    await checkAndResetLimits(profile);
    // Use 'offline_downloads_per_month' explicitly rather than 'saved_plans' key
    final limit = await _getLimitForFeature('offline_downloads_per_month', profile);
    return profile.offlineDownloadsUsed < limit;
  }

  /// Increments offline download counter. Atomic against concurrent calls —
  /// see _atomicCheckAndIncrement. Returns whether the increment was
  /// actually allowed.
  static Future<bool> incrementOfflineDownload() async {
    final profile = UserPreferenceService.getProfile();
    if (await _isPremiumValid(profile)) {
      final allowed = await _atomicCheckAndIncrement(counterField: 'offlineDownloadsUsed', limit: 9999);
      if (allowed) {
        profile.offlineDownloadsUsed++;
        await UserPreferenceService.saveProfile(profile);
      }
      return allowed;
    }

    await checkAndResetLimits(profile);
    final limit = await _getLimitForFeature('offline_downloads_per_month', profile);
    final allowed = await _atomicCheckAndIncrement(counterField: 'offlineDownloadsUsed', limit: limit);
    if (allowed) {
      profile.offlineDownloadsUsed++;
      await UserPreferenceService.saveProfile(profile);
    }
    return allowed;
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
