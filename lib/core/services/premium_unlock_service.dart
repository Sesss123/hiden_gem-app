import 'package:flutter/foundation.dart';

/// Manages temporary access to premium exports.
class PremiumUnlockService {
  static final Set<String> _unlockedTripPdfIds = {};

  /// Whether this trip's PDF export has been unlocked via ad for a free user.
  /// Premium users always have access — checked separately at the call site
  /// since it is already cheaply cached at the call site.
  static bool hasTripPdfAccess(String tripId) =>
      _unlockedTripPdfIds.contains(tripId);

  /// Temporarily unlocks PDF export for one trip plan for the current session.
  static void unlockTripPdf(String tripId) {
    _unlockedTripPdfIds.add(tripId);
    debugPrint("[PremiumUnlockService] Trip PDF $tripId unlocked via Ad.");
  }

  /// Invalidates all temporary unlocks (e.g., on subscription expiry or logout).
  static void invalidateAllUnlocks() {
    _unlockedTripPdfIds.clear();
    debugPrint("[PremiumUnlockService] All temporary unlocks invalidated.");
  }
}
