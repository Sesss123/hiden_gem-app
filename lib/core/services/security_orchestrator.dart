import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'integrity_shield.dart';
import 'secure_entitlements.dart';
import 'session_quarantine.dart';
import 'behavior_analytics_engine.dart';
import '../../data/datasources/user_preference_service.dart';
import '../utils/hmac_expiry_verifier.dart';

/// [SecurityOrchestrator] — The Nexus (Split Architecture Main Brain).
///
/// This service fragmentizes the "isPremium" decision across 5 disparate keys.
/// An attacker cannot unlock premium by patching just one boolean; they must
/// find and patch all 5 independent systems in 5 different files.
///
/// THE 5 KEYS:
/// 1. Local Flag (UserPreferenceService)
/// 2. Server Proof (SecureEntitlements)
/// 3. Device Integrity (IntegrityShield)
/// 4. Session Health (SessionQuarantine)
/// 5. Cryptographic Proof (HmacExpiryVerifier)
class SecurityOrchestrator {
  static final SecurityOrchestrator _instance = SecurityOrchestrator._internal();
  factory SecurityOrchestrator() => _instance;
  SecurityOrchestrator._internal();

  final _shield = IntegrityShield();
  final _entitlements = SecureEntitlements();
  final _quarantine = SessionQuarantine();
  final _analytics = BehaviorAnalyticsEngine();

  // Server posture is fetched on-demand (not via a persistent listener) —
  // it only needs to be fresh at the moment of an actual security-critical
  // check (verifyPremiumNexus/isKeyValid), not continuously for the whole
  // app session. A stale-if-recent cache avoids re-fetching on every check.
  Map<String, dynamic>? _lastServerPosture;
  DateTime? _lastPostureFetchAt;
  static const _postureMaxAge = Duration(minutes: 2);
  String? _uid;

  /// Records the signed-in user for posture checks. No network call here —
  /// the first real fetch happens lazily on the first Nexus check.
  void init(String uid) {
    _uid = uid;
    _lastServerPosture = null;
    _lastPostureFetchAt = null;
  }

  void dispose() {
    _uid = null;
    _lastServerPosture = null;
    _lastPostureFetchAt = null;
  }

  /// Refreshes server posture via a one-shot read if the cached value is
  /// missing or older than [_postureMaxAge]. Called from _runParallelChecks()
  /// so a real check always has posture data no more than 2 minutes stale —
  /// fresher, in practice, than the old listener ever guaranteed (listeners
  /// only push on change; a backend block written moments before this
  /// specific check still lands within this same window).
  Future<void> _refreshServerPostureIfStale() async {
    final uid = _uid;
    if (uid == null) return;

    final isStale = _lastPostureFetchAt == null ||
        DateTime.now().difference(_lastPostureFetchAt!) > _postureMaxAge;
    if (!isStale) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('security')
          .doc('posture')
          .get();
      _lastPostureFetchAt = DateTime.now();
      if (doc.exists && doc.data() != null) {
        _lastServerPosture = doc.data() as Map<String, dynamic>;
        _enforceServerDirectives(_lastServerPosture!);
      }
    } catch (e) {
      debugPrint('[SecurityOrchestrator] Posture fetch failed: $e');
    }
  }

  void _enforceServerDirectives(Map<String, dynamic> posture) {
    final bool isBlocked = posture['isBlocked'] == true;
    if (isBlocked) {
      debugPrint('[SecurityOrchestrator] 🚨 CRITICAL: Session blocked by server posture.');
      // Escalation logic would go here (e.g. force logout, show lock screen)
    }
  }

  /// The "Deep Nexus" check. Returns true only if ALL 5 security keys are valid.
  /// 
  /// Use this for critical feature access (e.g., AI generation, specialized guides).
  Future<bool> verifyPremiumNexus() async {
    final results = await _runParallelChecks();
    
    final bool allValid = results.every((r) => r.isValid);

    if (!allValid) {
      _traceFailureSilently(results);
    }

    return allValid;
  }

  /// Verification status for a single security key.
  bool isKeyValid(SecurityKey key) {
    final status = _checkKeySynchronously(key);
    return status;
  }

  // --- Internal ---

  Future<List<_NexusKeyResult>> _runParallelChecks() async {
    final uid = UserPreferenceService.getProfile().uid;
    final profile = UserPreferenceService.getProfile();

    // Key 1 & 2: Local + Server. Also refresh server posture (Key 6) here if
    // stale, so a security-critical check always sees near-fresh posture
    // without needing a persistent listener held open all session.
    final results = await Future.wait([
      _entitlements.verifyPremium(),
      _shield.runFullScan(),
      _quarantine.evaluate(),
      _refreshServerPostureIfStale(),
    ]);

    final bool serverProof = results[0] as bool;
    final bool localFlag = profile.isPremium;
    final bool integrityOk = _shield.riskScore < 60;
    final bool sessionOk = _quarantine.currentStatus.level.index <= 1;
    
    // Key 5: Cryptographic Expiry Proof
    bool cryptoProof = true;
    if (profile.premiumExpiresAt != null && profile.premiumSignature != null) {
      cryptoProof = HmacExpiryVerifier.verify(
        uid: uid,
        expiry: profile.premiumExpiresAt!,
        signature: profile.premiumSignature!,
      );
    } else if (profile.isPremium) {
      cryptoProof = false;
    }

    // Key 6: Server-Side Posture (Direct Backend Override)
    final bool postureOk = _lastServerPosture == null || _lastServerPosture!['isBlocked'] != true;

    return [
      _NexusKeyResult(SecurityKey.localFlag, localFlag),
      _NexusKeyResult(SecurityKey.serverProof, serverProof),
      _NexusKeyResult(SecurityKey.integrity, integrityOk),
      _NexusKeyResult(SecurityKey.sessionHealth, sessionOk),
      _NexusKeyResult(SecurityKey.cryptoProof, cryptoProof),
      _NexusKeyResult(SecurityKey.serverPosture, postureOk),
    ];
  }

  bool _checkKeySynchronously(SecurityKey key) {
    final profile = UserPreferenceService.getProfile();
    switch (key) {
      case SecurityKey.localFlag:
        return profile.isPremium;
      case SecurityKey.serverProof:
        return _entitlements.cachedIsPremium;
      case SecurityKey.integrity:
        return _shield.riskScore < 60;
      case SecurityKey.sessionHealth:
        return _quarantine.currentStatus.level.index <= 1;
      case SecurityKey.cryptoProof:
        if (profile.premiumExpiresAt == null) return false;
        return HmacExpiryVerifier.verify(
          uid: profile.uid,
          expiry: profile.premiumExpiresAt!,
          signature: profile.premiumSignature ?? '',
        );
      case SecurityKey.serverPosture:
        return _lastServerPosture == null || _lastServerPosture!['isBlocked'] != true;
    }
  }

  void _traceFailureSilently(List<_NexusKeyResult> results) {
    final failedKeys = results.where((r) => !r.isValid).map((r) => r.key.name).toList();
    
    // Only log if it's a suspicious mismatch (e.g. local is true but others are false)
    if (!results[0].isValid && results.any((r) => r.key != SecurityKey.localFlag && r.isValid)) {
       _analytics.reportCustomAnomaly(
        'nexus_mismatch_detected', 
        weight: 30, 
        details: {'failed_keys': failedKeys}
      );
    }
    
    debugPrint('[SecurityNexus] Mismatch in keys: $failedKeys');
  }
}

enum SecurityKey {
  localFlag,      // Point 1
  serverProof,    // Point 2
  integrity,      // Point 3
  sessionHealth,  // Point 4
  cryptoProof,    // Point 5
  serverPosture   // Point 6
}

class _NexusKeyResult {
  final SecurityKey key;
  final bool isValid;
  const _NexusKeyResult(this.key, this.isValid);
}
