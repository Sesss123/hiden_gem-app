import 'package:flutter/foundation.dart';
import 'integrity_shield.dart';
import 'secure_entitlements.dart';
import 'behavior_analytics_engine.dart';
import 'device_trust_graph.dart';
import 'session_quarantine.dart';

export 'integrity_shield.dart';
export 'secure_entitlements.dart';
export 'behavior_analytics_engine.dart';
export 'device_trust_graph.dart';
export 'session_quarantine.dart';

/// [ZenithSecurityFacade] — Single entry point for the entire security stack.
///
/// Instead of importing 5 different services, consume this one facade.
///
/// USAGE:
/// ```dart
/// final security = ZenithSecurityFacade();
///
/// // On app startup:
/// await security.initialize();
///
/// // On login:
/// await security.onUserLogin(deviceHash: hash, platform: 'android');
///
/// // Before showing premium feature:
/// if (!security.quarantine.isPremiumAllowed) return;
///
/// // Track behavior:
/// security.behavior.reportSearchFired();
/// ```
///
/// THE FULL SECURITY STACK:
///
/// ┌─────────────────────────────────────────────────────────────┐
/// │                   ZenithSecurityFacade                      │
/// ├─────────────────────────────────────────────────────────────┤
/// │  IntegrityShield      → Multi-signal risk scoring           │
/// │  SecureEntitlements   → Server-verified Premium/Admin       │
/// │  BehaviorAnalytics    → Silent forensic telemetry           │
/// │  DeviceTrustGraph     → Account-device abuse detection      │
/// │  SessionQuarantine    → Automatic session containment       │
/// └─────────────────────────────────────────────────────────────┘
class ZenithSecurityFacade {
  static final ZenithSecurityFacade _instance = ZenithSecurityFacade._internal();
  factory ZenithSecurityFacade() => _instance;
  ZenithSecurityFacade._internal();

  final IntegrityShield shield = IntegrityShield();
  final SecureEntitlements entitlements = SecureEntitlements();
  final BehaviorAnalyticsEngine behavior = BehaviorAnalyticsEngine();
  final DeviceTrustGraph deviceTrust = DeviceTrustGraph();
  final SessionQuarantine quarantine = SessionQuarantine();

  bool _initialized = false;

  // --- Lifecycle ---

  /// Call once at startup (after Firebase is ready).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Run full integrity scan
    final result = await shield.runFullScan();

    // Immediately evaluate quarantine level based on scan
    await quarantine.evaluate();

    debugPrint(
      '[ZenithSecurity] Initialized. Risk: ${result.riskScore} | '
      'Level: ${quarantine.currentStatus.level}',
    );
  }

  /// Call after successful user login.
  Future<void> onUserLogin({
    required String deviceHash,
    required String platform,
  }) async {
    // 1. Check device trust
    await deviceTrust.recordAndVerifyLogin(
      deviceHash: deviceHash,
      platform: platform,
    );

    // 2. Re-evaluate quarantine level with new device signals
    await quarantine.evaluate();

    // 3. Pre-warm entitlements cache
    entitlements.forceRefresh();
  }

  /// Call on logout to clean up session state.
  void onUserLogout() {
    entitlements.forceRefresh(); // Clear cached entitlements
  }

  // --- Quick Access Guards (Synchronous) ---

  /// True if the current session is allowed to access premium features.
  bool get isPremiumSessionAllowed => quarantine.isPremiumAllowed;

  /// True if the current session is allowed to access admin features.
  bool get isAdminSessionAllowed => quarantine.isAdminAllowed;

  /// True if a re-authentication is required.
  bool get requiresReauth => quarantine.currentStatus.shouldForceReauth;

  // --- Honeypot Trigger (Call from Decoy Widgets/Routes) ---

  /// Trigger this from any "honeypot" UI element or route.
  /// Legitimate users never reach these. Bots/reverse-engineers do.
  void triggerHoneypot(String trapId) {
    behavior.reportHoneypotTriggered(trapId);
    quarantine.evaluate(); // Immediately re-evaluate after high-weight signal
  }
}
