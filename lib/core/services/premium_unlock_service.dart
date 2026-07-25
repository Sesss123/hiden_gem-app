import 'package:flutter/foundation.dart';
import 'secure_entitlements.dart';

/// [PremiumUnlockService] — Manages temporary access to premium content.
/// 
/// In a real app, these unlocks should be persisted in local storage or 
/// backend database to survive app restarts. For this demo/task, we use
/// an in-memory set.
class PremiumUnlockService {
  static final Set<String> _unlockedPlaceIds = {};
  static final Set<String> _unlockedTripPdfIds = {};

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

  /// Whether this trip's PDF export has been unlocked via ad for a free user.
  /// Premium users always have access — checked separately at the call site
  /// (same pattern as hasAccess above) since it's already cheaply cached there.
  static bool hasTripPdfAccess(String tripId) => _unlockedTripPdfIds.contains(tripId);

  /// Temporarily unlocks PDF export for one trip plan for the current session.
  static void unlockTripPdf(String tripId) {
    _unlockedTripPdfIds.add(tripId);
    debugPrint("[PremiumUnlockService] Trip PDF $tripId unlocked via Ad.");
  }

  /// Invalidates all temporary unlocks (e.g., on subscription expiry or logout).
  static void invalidateAllUnlocks() {
    _unlockedPlaceIds.clear();
    _unlockedTripPdfIds.clear();
    debugPrint("[PremiumUnlockService] All temporary unlocks invalidated.");
  }
}
