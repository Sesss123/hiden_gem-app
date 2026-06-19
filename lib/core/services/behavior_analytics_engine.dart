import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'integrity_shield.dart';
import '../models/forensic_payload.dart';
import 'security_alert_service.dart';

/// [BehaviorAnalyticsEngine] — Silent forensic telemetry layer.
///
/// Tracks impossible patterns in user behavior to detect military-grade threats.
class BehaviorAnalyticsEngine {
  static final BehaviorAnalyticsEngine _instance =
      BehaviorAnalyticsEngine._internal();
  factory BehaviorAnalyticsEngine() => _instance;
  BehaviorAnalyticsEngine._internal();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _shield = IntegrityShield();

  // In-memory rate tracking (resets on app restart — intentionally ephemeral)
  final Map<String, List<DateTime>> _eventLog = {};

  // --- Public Event Reporters ---

  /// Call this every time a search query is fired.
  void reportSearchFired() {
    _trackEvent('search');
    final recentSearches = _getRecentEvents('search', const Duration(minutes: 1));
    if (recentSearches >= 20) {
      _reportAnomaly(
        code: 'search_rate_exceeded',
        severity: SecuritySeverity.low,
        weight: 15,
        details: {'searches_per_minute': recentSearches},
      );
    }
  }

  /// Call this when a user tries to access a premium feature and is denied.
  void reportPremiumProbeDenied() {
    _trackEvent('premium_probe');
    final probes = _getRecentEvents('premium_probe', const Duration(hours: 1));
    if (probes >= 5) {
      _reportAnomaly(
        code: 'premium_bypass_attempt',
        severity: SecuritySeverity.medium,
        weight: 25,
        details: {'probe_count': probes},
      );
    }
  }

  /// Call this when a user tries to directly navigate to an admin route.
  void reportAdminRouteProbeDenied(String route) {
    _trackEvent('admin_probe');
    final probes = _getRecentEvents('admin_probe', const Duration(hours: 1));
    if (probes >= 3) {
      _reportAnomaly(
        code: 'admin_route_probe',
        severity: SecuritySeverity.high,
        weight: 35,
        details: {'probe_count': probes, 'route': route},
      );
    }
  }

  /// Call this when a Firebase token refresh fails unexpectedly.
  /// 🛡️ POINT 13: Military Grade Step-Logic (3/5/8 rule)
  void reportTokenFailure() {
    _trackEvent('token_failure');
    final failures = _getRecentEvents('token_failure', const Duration(minutes: 10));
    
    SecuritySeverity severity = SecuritySeverity.low;
    int weight = 10;

    if (failures >= 8) {
      severity = SecuritySeverity.critical;
      weight = 60;
    } else if (failures >= 5) {
      // 🛡️ Contextual Escalation: 5 failures + high integrity = Critical
      severity = _shield.riskScore >= 60 ? SecuritySeverity.critical : SecuritySeverity.high;
      weight = 40;
    } else if (failures >= 3) {
      severity = SecuritySeverity.medium;
      weight = 20;
    }

    if (failures >= 3) {
      _reportAnomaly(
        code: 'repeated_token_failure',
        severity: severity,
        weight: weight,
        details: {'failure_count': failures},
      );
    }
  }

  /// Generic anomaly reporter for one-off cases.
  void reportCustomAnomaly(String code, {
    SecuritySeverity severity = SecuritySeverity.low, 
    int weight = 10, 
    Map<String, dynamic>? details
  }) {
    _reportAnomaly(
      code: code, 
      severity: severity, 
      weight: weight, 
      details: details ?? {}
    );
  }

  /// 🍯 Honeypot Triggers
  void reportHoneypotTriggered(String trapId) {
    _reportAnomaly(
      code: 'honeypot_triggered',
      severity: SecuritySeverity.critical,
      weight: 50,
      details: {'trap_id': trapId},
    );
  }

  // --- Internal ---

  void _trackEvent(String eventType) {
    _eventLog.putIfAbsent(eventType, () => []);
    _eventLog[eventType]!.add(DateTime.now());
    // Prune old events (> 1 hour)
    _eventLog[eventType]!.removeWhere(
      (t) => DateTime.now().difference(t) > const Duration(hours: 1),
    );
  }

  int _getRecentEvents(String eventType, Duration window) {
    final events = _eventLog[eventType] ?? [];
    return events.where((t) => DateTime.now().difference(t) < window).length;
  }

  void _reportAnomaly({
    required String code,
    required SecuritySeverity severity,
    required int weight,
    required Map<String, dynamic> details,
  }) {
    _shield.reportRuntimeAnomaly(code, weight: weight);
    _persistForensicTrail(code, severity, weight, details);
    
    // 🛡️ Trigger Admin Alerts for High/Critical
    if (severity == SecuritySeverity.high || severity == SecuritySeverity.critical) {
      SecurityAlertService().triggerAlert(
        code: code, 
        severity: severity, 
        details: details
      );
    }
  }

  Future<void> _persistForensicTrail(
    String code, 
    SecuritySeverity severity, 
    int weight, 
    Map<String, dynamic> details
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final appInfo = await PackageInfo.fromPlatform();
      final patterns = _deriveImpossiblePatterns();

      final payload = ForensicPayload(
        eventCode: code,
        severity: severity,
        uid: user.uid,
        deviceHash: null, // Populated by DeviceTrustGraph asynchronously if needed
        integrityScore: _shield.riskScore,
        integritySignals: _shield.activeSignals,
        appVersion: '${appInfo.version}+${appInfo.buildNumber}',
        details: details,
        impossiblePatterns: patterns,
      );

      _firestore.collection('security_events').add(payload.toJson());
    } catch (e) {
      debugPrint('[BehaviorAnalytics] Forensic persistence failed: $e');
    }
  }

  List<String> _deriveImpossiblePatterns() {
    final List<String> patterns = [];
    
    // 1. Admin Probe + High Integrity Risk
    final adminProbes = _getRecentEvents('admin_probe', const Duration(hours: 1));
    if (adminProbes > 0 && _shield.riskScore >= 60) {
      patterns.add('admin_probe_from_high_risk_device');
    }

    // 2. Token Failure Burst + Premium Bypass
    final tokenFailures = _getRecentEvents('token_failure', const Duration(minutes: 10));
    final premiumProbes = _getRecentEvents('premium_probe', const Duration(hours: 1));
    if (tokenFailures >= 5 && premiumProbes >= 3) {
      patterns.add('token_burst_plus_premium_bypass');
    }

    return patterns;
  }
}
