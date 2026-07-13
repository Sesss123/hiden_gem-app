import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/user_profile.dart';
import '../models/guide_profile.dart';
import '../models/guide_status.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/utils/secure_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/utils/debouncer.dart';

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
  static bool _pendingFirestoreSync = false;
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  static final _firestoreSyncDebouncer = Debouncer(milliseconds: 3000);

  // ── Initialization ───────────────────────────────────────────────────────

  static Future<void> init() async {
    // Placeholder — Hive is still used for other non-sensitive caching
  }

  /// Must be called once at startup before any getProfile() calls.
  static Future<void> ensureProfileLoaded() async {
    if (_cachedProfile != null) return; // Already loaded
    _cachedProfile = await _loadFromDisk();
    
    try {
      final pendingRaw = await _secureStorage.read(key: 'pending_firestore_sync');
      _pendingFirestoreSync = pendingRaw == 'true';
    } catch (e, st) { SecureLogger.error("Exception caught: $e\n$st"); }

    await _migrateIfNeeded();
    debugPrint('[UPS] Profile loaded. uid=${_cachedProfile?.uid}');

    if (_pendingFirestoreSync) {
      debugPrint('[UPS] Pending firestore sync detected. Retrying sync in background.');
      syncToFirestore();
    }

    // BUG-043: Listen for network connectivity restoration to replay offline wishlist/itinerary mutations
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none) && _pendingFirestoreSync) {
        debugPrint('[UPS] Connectivity restored! Replaying pending offline wishlist/itinerary sync to Firestore.');
        syncToFirestore();
      }
    });
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
    // BUG-7 FIX: Force flush — trip count is user progress data that must
    // survive an app crash. The default 2-second cooldown could lose this.
    await _flushToDisk(force: true);
  }

  static Future<void> addVisitedPlace(String place) async {
    final profile = getProfile();
    if (!profile.visitedPlaces.contains(place)) {
      _mutate((p) => p.visitedPlaces.add(place));
      // BUG-7 FIX: Force flush — visited places are user progress data that
      // must survive an app crash within the default 2-second cooldown window.
      await _flushToDisk(force: true);
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
    _scheduleFirestoreSync();
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
    _scheduleFirestoreSync();
    return isNowAdded;
  }

  /// Debounces syncToFirestore() — cost fix: toggleBookmark()/
  /// toggleItinerary() previously called syncToFirestore() directly and
  /// immediately on every single tap, with no rate limiting (unlike the
  /// disk-flush path, which already coalesces via _flushCooldown). A user
  /// rapidly bookmarking/unbookmarking several places while browsing a list
  /// fired one full users/{uid} Firestore write per tap. This collapses N
  /// rapid taps within the debounce window into a single trailing write of
  /// the final state — syncToFirestore() always writes the current full
  /// bookmarkedPlaces/itineraryPlaceIds arrays (not a delta), so only the
  /// last state in a burst needs to actually reach Firestore.
  ///
  /// Trade-off: if the app is killed within the debounce window, the
  /// pending write would never fire. Mitigated by flushPendingFirestoreSync()
  /// below, called from main.dart's didChangeAppLifecycleState() on pause/
  /// detach/hidden — so backgrounding the app (the common real-world case:
  /// switching apps, a call interrupting, the screen locking) flushes any
  /// debounced write immediately instead of losing it. A true process kill
  /// with no OS pause callback at all (rare, and not guaranteed preventable
  /// on any platform) can still lose the pending write; the local disk write
  /// (_flushToDisk(force: true) above, unconditional) already happened by
  /// then, so the change survives on-device and only the Firestore mirror
  /// can lag in that narrower case. Not applied to any force:true-flushed
  /// field (premium status, terms agreement, etc.), which don't go through
  /// this debounce at all.
  static void _scheduleFirestoreSync() {
    _firestoreSyncDebouncer.run(syncToFirestore);
  }

  /// Immediately flushes a pending debounced Firestore sync, if one is
  /// scheduled. Call this from an app-lifecycle hook (pause/detach/hidden)
  /// so a backgrounded or killed app doesn't silently lose a bookmark/
  /// itinerary toggle that was still waiting out its debounce window.
  /// No-op if nothing is currently scheduled.
  static void flushPendingFirestoreSync() {
    _firestoreSyncDebouncer.flush();
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

  static Future<void> updateAppLockStatus(bool enabled) async {
    _mutate((p) => p.isAppLockEnabled = enabled);
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
      } else {
        if (p.role == 'premium_user') p.role = 'user';
        p.premiumPlan = null;
        p.premiumExpiresAt = null;
        p.premiumSignature = null;
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

      // NOTE: syncToFirestore() is NOT called here anymore. It used to fire
      // on every flush regardless of what mutated — meaning updateLanguage(),
      // updateTermsAgreement(), updatePremiumStatus() etc. were each
      // triggering a full users/{uid} write of bookmarkedPlaces/
      // itineraryPlaceIds even though those fields never changed. It's now
      // called explicitly only from toggleBookmark()/toggleItinerary(),
      // the only two mutations that actually touch those synced fields.

      _isDirty = false;
      _lastFlush = DateTime.now();
    } catch (e) {
      debugPrint('[UPS] ❌ Flush to disk failed: $e');
    }
  }

  /// Forces sync of the local profile configuration to Firestore if Firebase is ready and user is logged in
  static Future<void> syncToFirestore() async {
    final profile = _cachedProfile;
    if (profile == null) return;

    if (Firebase.apps.isNotEmpty) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set({
            'bookmarkedPlaces': profile.bookmarkedPlaces,
            'itineraryPlaceIds': profile.itineraryPlaceIds,
          }, SetOptions(merge: true));
          _pendingFirestoreSync = false;
          await _secureStorage.write(key: 'pending_firestore_sync', value: 'false');
          debugPrint('[UPS] Local profile successfully synchronized to Firestore.');
        }
      } catch (e) {
        _pendingFirestoreSync = true;
        await _secureStorage.write(key: 'pending_firestore_sync', value: 'true');
        debugPrint('[UPS] Firestore sync failed: $e. Queued update locally.');
      }
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
