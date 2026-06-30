import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_profile.dart';
import '../models/guide_profile.dart';
import '../models/guide_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// [UserPreferenceService] — Hardened local profile cache.
///
/// CACHING ARCHITECTURE:
/// ┌────────────────────────────────────────────────────────────────┐
/// │ Layer 1: In-memory (_cachedProfile)                            │
/// │   → Zero I/O, synchronous read                                 │
/// │   → Mutated in-place by all update* methods                    │
/// │                                                                │
/// │ Layer 2: SecureStorage (encrypted disk)                        │
/// │   → Written on CHANGE only (dirty-flag pattern)                │
/// │   → Read once at startup via ensureProfileLoaded()             │
/// │   → Never read again during normal operation                   │
/// └────────────────────────────────────────────────────────────────┘
///
/// WRITE COALESCING:
/// Rapid consecutive updates (e.g., language change triggers 3 rebuilds)
/// are coalesced using a dirty-flag + scheduled flush. Only one disk write
/// occurs per burst, rather than one per call.
class UserPreferenceService {
  static const String _profileKey = 'current_profile';
  static const _secureStorage = FlutterSecureStorage();

  // ── Layer 1: In-Memory Cache ─────────────────────────────────────────────
  static UserProfile? _cachedProfile;
  static bool _isDirty = false;           // True if cache differs from disk
  static DateTime? _lastFlush;
  static const _flushCooldown = Duration(seconds: 2); // Minimum flush interval

  // ── Initialization ───────────────────────────────────────────────────────

  static Future<void> init() async {
    // Placeholder — Hive is still used for other non-sensitive caching
  }

  /// Must be called once at startup before any getProfile() calls.
  static Future<void> ensureProfileLoaded() async {
    if (_cachedProfile != null) return; // Already loaded
    _cachedProfile = await _loadFromDisk();
    await _migrateIfNeeded();
    debugPrint('[UPS] Profile loaded. uid=${_cachedProfile?.uid}');
  }

  // ── Public Read API ──────────────────────────────────────────────────────

  /// Synchronous cache read — zero I/O.
  /// Always returns a valid profile (never null).
  static UserProfile getProfile() {
    return _cachedProfile ?? UserProfile.defaultProfile(uid: 'NOT_LOADED');
  }

  // ── Public Write API ─────────────────────────────────────────────────────

  /// Saves a complete profile. Used for wholesale replacements (e.g., after login sync).
  static Future<void> saveProfile(UserProfile profile) async {
    _cachedProfile = profile;
    await _flushToDisk(force: true); // Full replacement — always flush immediately
  }

  static Future<void> clearProfile() async {
    _cachedProfile = null;
    _isDirty = false;
    await _secureStorage.delete(key: _profileKey);
    debugPrint('[UPS] Profile cleared.');
  }

  // ── Granular Update Methods (Coalesced Writes) ───────────────────────────

  static Future<void> updateVibe(String vibe) async {
    _mutate((p) => p.vibe = vibe);
    await _flushToDisk();
  }

  static Future<void> addTrip() async {
    _mutate((p) => p.totalTripsGenerated++);
    await _flushToDisk();
  }

  static Future<void> addVisitedPlace(String place) async {
    final profile = getProfile();
    if (!profile.visitedPlaces.contains(place)) {
      _mutate((p) => p.visitedPlaces.add(place));
      await _flushToDisk();
    }
  }

  /// Toggle bookmark on a place. Returns the new bookmarked state.
  static Future<bool> toggleBookmark(String placeId) async {
    final profile = getProfile();
    final isNowBookmarked = !profile.bookmarkedPlaces.contains(placeId);
    _mutate((p) {
      if (isNowBookmarked) {
        p.bookmarkedPlaces.add(placeId);
      } else {
        p.bookmarkedPlaces.remove(placeId);
      }
    });
    await _flushToDisk(force: true);
    return isNowBookmarked;
  }

  /// Toggle itinerary entry for a place. Returns the new added state.
  static Future<bool> toggleItinerary(String placeId) async {
    final profile = getProfile();
    final isNowAdded = !profile.itineraryPlaceIds.contains(placeId);
    _mutate((p) {
      if (isNowAdded) {
        p.itineraryPlaceIds.add(placeId);
      } else {
        p.itineraryPlaceIds.remove(placeId);
      }
    });
    await _flushToDisk(force: true);
    return isNowAdded;
  }

  static Future<void> updateLanguage(String languageCode) async {
    _mutate((p) => p.languageCode = languageCode);
    await _flushToDisk(force: true); // Language change is user-critical
  }

  static Future<void> updateProfileImagePath(String? path) async {
    _mutate((p) => p.profileImagePath = path);
    await _flushToDisk();
  }

  static Future<void> updateThemeMode(String mode) async {
    _mutate((p) => p.themeMode = mode);
    await _flushToDisk();
  }

  static Future<void> updateScreenshotMode(bool show) async {
    _mutate((p) => p.showScreenshotButton = show);
    await _flushToDisk();
  }

  static Future<void> updateTermsAgreement(bool agreed) async {
    _mutate((p) => p.hasAgreedToTerms = agreed);
    await _flushToDisk(force: true); // Legal — always flush immediately
  }

  static Future<void> updateOnboardingCompletion(bool completed) async {
    _mutate((p) => p.hasCompletedOnboarding = completed);
    await _flushToDisk(force: true);
  }

  static Future<void> updatePremiumStatus(
    bool isPremium, {
    String? plan,
    String? source,
    DateTime? expiry,
    String? signature,
  }) async {
    _mutate((p) {
      p.isPremium = isPremium;
      if (isPremium) {
        if (p.role == 'user') p.role = 'premium_user';
        p.premiumPlan = plan;
        p.premiumSource = source;
        p.premiumExpiresAt = expiry;
        p.premiumSignature = signature;
      }
    });
    await _flushToDisk(force: true); // Financial — always flush immediately
  }

  // ── Auth Token Helpers ───────────────────────────────────────────────────

  static Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  static Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  // ── Internal Engine ──────────────────────────────────────────────────────

  /// Applies a mutation to the in-memory cache and marks it dirty.
  static void _mutate(void Function(UserProfile p) mutation) {
    final profile = _cachedProfile;
    if (profile == null) {
      debugPrint('[UPS] ⚠️ mutate() called before profile was loaded!');
      return;
    }
    mutation(profile);
    _isDirty = true;
  }

  /// Writes the in-memory cache to disk.
  /// [force] = true bypasses the cooldown (use for critical changes).
  static Future<void> _flushToDisk({bool force = false}) async {
    if (!_isDirty) return; // Nothing changed — skip

    if (!force) {
      // Rate-limit non-critical flushes to avoid hammering SecureStorage
      if (_lastFlush != null &&
          DateTime.now().difference(_lastFlush!) < _flushCooldown) {
        return; // Too soon — coalesced
      }
    }

    final profile = _cachedProfile;
    if (profile == null) return;

    try {
      await _secureStorage.write(
        key: _profileKey,
        value: json.encode(profile.toJson()),
      );
      
      // Sync to Firestore if authenticated (Fix for Bug #13, #14)
      if (FirebaseAuth.instance.currentUser != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .set({
            'bookmarkedPlaces': profile.bookmarkedPlaces,
            'itineraryPlaceIds': profile.itineraryPlaceIds,
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('[UPS] Firestore sync failed: $e');
        }
      }

      _isDirty = false;
      _lastFlush = DateTime.now();
    } catch (e) {
      debugPrint('[UPS] ❌ Flush to disk failed: $e');
    }
  }

  /// Reads profile from disk — only called once at startup.
  static Future<UserProfile> _loadFromDisk() async {
    try {
      final raw = await _secureStorage.read(key: _profileKey);
      if (raw == null) {
        debugPrint('[UPS] No saved profile found. Using default.');
        return UserProfile.defaultProfile(uid: 'NEW_USER');
      }

      final Map<String, dynamic> data = json.decode(raw);
      if (data['uid'] == null) {
        debugPrint('[UPS] Null UID in saved profile — recovering.');
        data['uid'] = 'RECOVERED_UID';
      }

      return UserProfile.fromJson(data);
    } catch (e) {
      debugPrint('[UPS] Error loading profile from disk: $e. Using default.');
      return UserProfile.defaultProfile(uid: 'ERROR_FALLBACK');
    }
  }

  /// One-time data migration from legacy fields to Zenith schema.
  static Future<void> _migrateIfNeeded() async {
    final profile = getProfile();
    if (profile.hasMigratedToZenith) return;

    if (profile.guideLicense != null ||
        profile.guideBio != null ||
        profile.isGuideApproved) {
      profile.guideProfile = GuideProfile(
        licenseNumber: profile.guideLicense,
        bio: profile.guideBio,
        travelersServed: profile.totalTouristsServed,
      );
      profile.guideStatus =
          profile.isGuideApproved ? GuideStatus.approved : GuideStatus.none;
      if (profile.isGuideApproved && profile.role == 'user') {
        profile.role = 'guide_approved';
      }
    }

    profile.hasMigratedToZenith = true;
    await saveProfile(profile);
    debugPrint('[UPS] Zenith migration complete.');
  }
}
