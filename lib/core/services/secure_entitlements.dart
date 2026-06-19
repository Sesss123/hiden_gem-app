import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'integrity_shield.dart';
import 'behavior_analytics_engine.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/utils/hmac_expiry_verifier.dart';
import '../../data/datasources/user_preference_service.dart';

/// [SecureEntitlements] — Server-verified feature gating.
///
/// PERFORMANCE ARCHITECTURE:
/// - Fetches from Source.server to prevent local cache manipulation (Point 2).
/// - In-memory cache with 5-minute TTL to balance cost and security.
/// - Integrity-cross-check: Gated features are denied if the device risk
///   score is high, regardless of the user's role in the database.
class SecureEntitlements {
  static final SecureEntitlements _instance = SecureEntitlements._internal();
  factory SecureEntitlements() => _instance;
  SecureEntitlements._internal();

  final _functions = FirebaseFunctions.instance;
  final _auth = FirebaseAuth.instance;
  final _shield = IntegrityShield();
  final _analytics = BehaviorAnalyticsEngine();

  // In-memory session cache
  Map<String, dynamic>? _serverClaimsCache;
  DateTime? _cacheExpiry;

  // --- Public API ---

  /// Verifies if the user has a valid Premium role.
  /// Result is NOT trusted if it comes from the local Firestore cache.
  Future<bool> verifyPremium() async {
    final claims = await _getVerifiedClaims();
    final localProfile = UserPreferenceService.getProfile();

    if (claims == null) return false;

    // 🛡️ POINT 5: Cryptographic Proof Verification
    // Even if isPremium is true, we verify the backend-generated signature
    // for the expiry date to prevent "Local Date Patching".
    if (claims.containsKey('premiumExpiresAt') && claims.containsKey('signature')) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(claims['premiumExpiresAt']);
      final signature = claims['signature'] as String;
      
      final bool isSignatureValid = HmacExpiryVerifier.verify(
        uid: _auth.currentUser!.uid,
        expiry: expiry,
        signature: signature,
      );

      if (!isSignatureValid) {
        debugPrint('[SecureEntitlements] 🚨 Signature Mismatch: Denying premium access.');
        return false;
      }

      // Update local profile with the verified backend proof
      localProfile.premiumExpiresAt = expiry;
      localProfile.premiumSignature = signature;
      UserPreferenceService.saveProfile(localProfile);
    }

    // 🕵️ SHADOW VALIDATION TRAP (Point 4)
    // If local APK is patched to show 'premium: true' but server says false,
    // we log a forensic event. We do NOT block immediately to avoid alerting the attacker.
    if (localProfile.isPremium && claims['isPremium'] != true) {
      _analytics.reportCustomAnomaly('local_state_tamper_detected', weight: 40);
      debugPrint('[SecureEntitlements] 🕵️ Shadow Trap Triggered: Local state mismatch.');
    }

    // 1. Database Check
    final isPremium = claims['isPremium'] == true ||
        ['premium_user', 'admin', 'super_admin'].contains(claims['role']);

    if (!isPremium) return false;

    // 2. Defense-in-Depth: Integrity Check (Point 4)
    // Even if database says "Premium", deny if risk score is High/Critical.
    if (_shield.riskScore >= 60) {
      debugPrint('[SecureEntitlements] Premium DENIED due to high risk score.');
      return false;
    }

    return true;
  }

  /// Verifies if the user has an Admin role.
  /// Strictly requires server-side proof and low risk score.
  Future<bool> verifyAdmin() async {
    final claims = await _getVerifiedClaims();
    if (claims == null) return false;

    // 1. Database Check
    final isAdmin = ['admin', 'super_admin'].contains(claims['role']);
    if (!isAdmin) return false;

    // 2. Integrity Check
    // Admin features require LOW risk score (< 30).
    if (_shield.riskScore >= 30) {
      debugPrint('[SecureEntitlements] Admin DENIED due to medium/high risk score.');
      return false;
    }

    return true;
  }

  /// Returns the server-verified role string.
  Future<String> getVerifiedRole() async {
    final claims = await _getVerifiedClaims();
    return claims?['role']?.toString() ?? 'user';
  }

  /// Clears the in-memory cache, forcing the next check to hit the server.
  void forceRefresh() {
    _serverClaimsCache = null;
    _cacheExpiry = null;
  }

  // --- Internal ---

  Future<Map<String, dynamic>?> _getVerifiedClaims() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    // Serve from memory cache if valid (TTL: 5 minutes)
    if (_serverClaimsCache != null &&
        _cacheExpiry != null &&
        DateTime.now().isBefore(_cacheExpiry!)) {
      return _serverClaimsCache;
    }

    try {
      // 🛡️ BACKEND MIGRATION: Shift decision to the server.
      // Instead of reading a field, we call a dedicated verification function.
      final result = await _functions
          .httpsCallable('verify_entitlements')
          .call({'uid': uid});

      final data = Map<String, dynamic>.from(result.data);
      
      // The backend returns a data object along with a 'signature' (HMAC)
      // to prove authenticity (Point 5).
      _serverClaimsCache = data;
      _cacheExpiry = DateTime.now().add(const Duration(minutes: 5));
      
      // Auto-heal local state if server says they are clearly NOT premium
      if (_serverClaimsCache!['isPremium'] != true && 
          UserPreferenceService.getProfile().isPremium) {
        debugPrint('[SecureEntitlements] Auto-correcting mismatched local premium flag.');
        final profile = UserPreferenceService.getProfile();
        profile.isPremium = false;
        UserPreferenceService.saveProfile(profile);
      }

      return _serverClaimsCache;
    } catch (e) {
      debugPrint('[SecureEntitlements] Backend verification failed: $e');
      return null;
    }
  }
}
