import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'integrity_shield.dart';
import 'secure_entitlements.dart';

/// [SessionQuarantine] — Automatic suspicious session containment.
///
/// When the IntegrityShield risk score reaches critical levels,
/// this engine automatically restricts the session without immediately
/// exposing the restriction to the user.
///
/// QUARANTINE LEVELS:
///
///   Level 0 — Normal       (score < 30):  Full access
///   Level 1 — Soft Limit   (score 30-59): Limit some features silently
///   Level 2 — Restricted   (score 60-89): Block premium/admin, log heavily  
///   Level 3 — Quarantined  (score 90+):   Force re-auth, revoke server session
///
/// DESIGN PHILOSOPHY:
/// We avoid "hard blocking early" because:
/// - False positives hurt real users
/// - Attackers who get blocked immediately know their tool was detected
/// - A quarantined attacker who "seems" to work wastes their time
/// 
/// The BEST outcome is: attacker thinks they bypassed security,
/// but their session is silently marked as suspicious and all
/// actions are server-rejected or forensically logged.
class SessionQuarantine {
  static final SessionQuarantine _instance = SessionQuarantine._internal();
  factory SessionQuarantine() => _instance;
  SessionQuarantine._internal();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _shield = IntegrityShield();
  final _entitlements = SecureEntitlements();

  QuarantineLevel _currentLevel = QuarantineLevel.normal;

  // --- Public API ---

  /// Evaluate and apply the appropriate quarantine level based on current risk.
  /// Call this after any major integrity event (login, scan, anomaly detected).
  Future<QuarantineResult> evaluate() async {
    final score = _shield.riskScore;
    final previousLevel = _currentLevel;

    if (score >= 90) {
      _currentLevel = QuarantineLevel.quarantined;
    } else if (score >= 60) {
      _currentLevel = QuarantineLevel.restricted;
    } else if (score >= 30) {
      _currentLevel = QuarantineLevel.softLimit;
    } else {
      _currentLevel = QuarantineLevel.normal;
    }

    // If level escalated, take action
    if (_currentLevel.index > previousLevel.index) {
      await _onLevelEscalated(_currentLevel);
    }

    return QuarantineResult(
      level: _currentLevel,
      canUsePremium: _currentLevel.index < QuarantineLevel.restricted.index,
      canUseAdmin: _currentLevel.index < QuarantineLevel.softLimit.index,
      shouldForceReauth: _currentLevel == QuarantineLevel.quarantined,
      riskScore: score,
    );
  }

  /// Quick sync check (no async) for guard gates in the UI.
  QuarantineResult get currentStatus => QuarantineResult(
    level: _currentLevel,
    canUsePremium: _currentLevel.index < QuarantineLevel.restricted.index,
    canUseAdmin: _currentLevel.index < QuarantineLevel.softLimit.index,
    shouldForceReauth: _currentLevel == QuarantineLevel.quarantined,
    riskScore: _shield.riskScore,
  );

  bool get isPremiumAllowed =>
      _currentLevel.index < QuarantineLevel.restricted.index;

  bool get isAdminAllowed =>
      _currentLevel.index < QuarantineLevel.softLimit.index;

  // --- Internal ---

  Future<void> _onLevelEscalated(QuarantineLevel newLevel) async {
    final uid = _auth.currentUser?.uid;

    debugPrint('[SessionQuarantine] ⚠️ Level escalated to: $newLevel (score: ${_shield.riskScore})');

    // Record the quarantine event in Firestore
    if (uid != null) {
      _firestore.collection('security_events').add({
        'uid': uid,
        'code': 'session_quarantine_escalated',
        'quarantineLevel': newLevel.name,
        'riskScore': _shield.riskScore,
        'signals': _shield.activeSignals,
        'category': 'session_quarantine',
        'platform': kIsWeb ? 'web' : 'mobile',
        'createdAt': FieldValue.serverTimestamp(),
      }).catchError((e) {
        // Silently ignore Firestore write errors — quarantine still applies
        debugPrint('[SessionQuarantine] Firestore write failed: $e');
        return _firestore.collection('security_events').doc(); // Return dummy ref
      });
    }

    switch (newLevel) {
      case QuarantineLevel.softLimit:
        // Silent — no user notification. Features start silently degrading.
        debugPrint('[SessionQuarantine] Soft limits applied silently.');
        break;

      case QuarantineLevel.restricted:
        // Silently revoke premium/admin in the server entitlements cache.
        // Local UI might still show premium but server will deny all gated calls.
        _entitlements.forceRefresh();
        debugPrint('[SessionQuarantine] Session restricted — server entitlements refreshed.');
        break;

      case QuarantineLevel.quarantined:
        // Mark session as quarantined in Firestore + notify admin
        if (uid != null) {
          await _firestore.collection('quarantined_sessions').doc(uid).set({
            'uid': uid,
            'startedAt': FieldValue.serverTimestamp(),
            'riskScore': _shield.riskScore,
            'signals': _shield.activeSignals,
            'requiresAdminReview': true,
            'autoResolved': false,
          }, SetOptions(merge: true));
        }

        debugPrint('[SessionQuarantine] 🔒 Session QUARANTINED. Force re-auth required.');
        
        // 🔒 POINT 5: Force re-authentication by signing out
        await _auth.signOut();
        _entitlements.forceRefresh();
        break;

      case QuarantineLevel.normal:
        break;
    }
  }
}

enum QuarantineLevel {
  normal,     // 0
  softLimit,  // 1
  restricted, // 2
  quarantined // 3
}

class QuarantineResult {
  final QuarantineLevel level;
  final bool canUsePremium;
  final bool canUseAdmin;
  final bool shouldForceReauth;
  final int riskScore;

  const QuarantineResult({
    required this.level,
    required this.canUsePremium,
    required this.canUseAdmin,
    required this.shouldForceReauth,
    required this.riskScore,
  });

  bool get isNormal => level == QuarantineLevel.normal;
  bool get isQuarantined => level == QuarantineLevel.quarantined;

  @override
  String toString() =>
      'QuarantineResult(level: $level, score: $riskScore, premium: $canUsePremium)';
}
