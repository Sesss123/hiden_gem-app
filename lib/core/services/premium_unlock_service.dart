import 'package:flutter/foundation.dart';
import 'secure_entitlements.dart';

/// [PremiumUnlockService] — Manages temporary access to premium content.
/// 
/// In a real app, these unlocks should be persisted in local storage or 
/// backend database to survive app restarts. For this demo/task, we use
/// an in-memory set.
class PremiumUnlockService {
  static final Set<String> _unlockedPlaceIds = {};

  /// Checks if a place is accessible to the user.
  /// Always returns true for Premium/Admin users.
  static Future<bool> hasAccess(String placeId, {int? arTier}) async {
    // 1. Check if user is already Premium
    final isPremium = await SecureEntitlements().verifyPremium();
    if (isPremium) return true;

    // 2. Only "Heritage" sites (Tier 1) are gated for free users
    if (arTier != null && arTier > 1) return true;

    // 3. Check if temporarily unlocked via Ad
    return _unlockedPlaceIds.contains(placeId);
  }

  /// Temporarily unlocks a place for the current session.
  static void unlockPlace(String placeId) {
    _unlockedPlaceIds.add(placeId);
    debugPrint("[PremiumUnlockService] Place $placeId unlocked via Ad.");
  }
}
