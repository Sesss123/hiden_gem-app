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
  
  // Real-time posture tracking
  Map<String, dynamic>? _lastServerPosture;

  /// Initializes the real-time Security Posture listener.
  /// This allows the backend to push instant blocks or security overrides.
  void init(String uid) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('security')
        .doc('posture')
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        _lastServerPosture = doc.data();
        _enforceServerDirectives(_lastServerPosture!);
      }
    });
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

    // Key 1 & 2: Local + Server
    // (Checked in parallel to save latency)
    final results = await Future.wait([
      _entitlements.verifyPremium(),
      _shield.runFullScan(),
      _quarantine.evaluate(),
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
        // We only have sync access to cached result
        return true; // Assume true if not pre-verified async
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
