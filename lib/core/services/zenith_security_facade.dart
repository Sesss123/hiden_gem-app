import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import 'integrity_shield.dart';
import 'secure_entitlements.dart';
import 'behavior_analytics_engine.dart';
import 'device_trust_graph.dart';
import 'session_quarantine.dart';
import 'vault_service.dart';
import 'step_up_auth_service.dart';
import 'session_token_manager.dart';

export 'integrity_shield.dart';
export 'secure_entitlements.dart';
export 'behavior_analytics_engine.dart';
export 'device_trust_graph.dart';
export 'session_quarantine.dart';
export 'vault_service.dart';
export 'step_up_auth_service.dart';

/// [ZenithSecurityFacade] — Single entry point for the entire Zero-Trust security stack.
///
/// THE FULL ZERO-TRUST SECURITY STACK:
///
/// ┌─────────────────────────────────────────────────────────────┐
/// │                   ZenithSecurityFacade                      │
/// ├─────────────────────────────────────────────────────────────┤
/// │  IntegrityShield      → Multi-signal risk scoring           │
/// │  SecureEntitlements   → Server-verified Premium/Admin       │
/// │  BehaviorAnalytics    → Silent forensic telemetry           │
/// │  DeviceTrustGraph     → Account-device abuse detection      │
/// │  SessionQuarantine    → Automatic session containment       │
/// │  VaultService         → Device-bound Asymmetric ECDSA Keys │
/// │  StepUpAuthService    → High-risk operation challenge gates │
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
  final StepUpAuthService stepUp = StepUpAuthService();

  static const _storage = FlutterSecureStorage();
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
  /// Binds hardware ECDSA public key to user record on the backend (Zero-Trust Phase 1).
  Future<void> onUserLogin({
    required String deviceHash,
    required String platform,
  }) async {
    // Register before any API call that requires a device-bound session.
    try {
      final deviceId = await VaultService.getDeviceId();
      final pubKeyPem = await VaultService.getDevicePublicKeyPem();
      final token=await _storage.read(key:'auth_token');
      final response=await http.post(Uri.parse('${AppConfig.laravelUrl}/security/device-key'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token','X-API-KEY':AppConfig.hiddenGemsApiKey},body:jsonEncode({'deviceId':deviceId,'publicKeyPem':pubKeyPem,'platform':platform})).timeout(const Duration(seconds:15));
      if(response.statusCode!=200) throw StateError('Device registration failed (${response.statusCode}).');
      debugPrint('[ZenithSecurity] Device key registered successfully.');
      await SessionTokenManager.startNewSession();
    } catch (e) {
      debugPrint('[ZenithSecurity] Device key registration notice: $e');
      rethrow;
    }

    await deviceTrust.recordAndVerifyLogin(
      deviceHash: deviceHash,
      platform: platform,
    );

    // 3. Re-evaluate quarantine level with new device signals
    await shield.runFullScan();
    await quarantine.evaluate();

    // 4. Pre-warm entitlements cache
    entitlements.forceRefresh();
  }

  /// Call on logout to clean up session state and step-up grants.
  void onUserLogout() {
    entitlements.forceRefresh();
    stepUp.clearGrants();
    SessionTokenManager.clear();
  }

  /// Revoke current session on server.
  Future<void> revokeCurrentSession(String sessionId) async {
    try {
      await _postSecurity('/security/session/revoke', {'sessionId':sessionId});
    } catch (e) {
      debugPrint('[ZenithSecurity] Session revocation error: $e');
    }
  }

  /// Revoke all sessions across all devices (Remote Kill / Force Logout).
  Future<void> revokeAllSessions() async {
    try {
      await _postSecurity('/security/sessions/revoke-all', const {});
      onUserLogout();
    } catch (e) {
      debugPrint('[ZenithSecurity] Revoke all sessions error: $e');
    }
  }

  Future<void> _postSecurity(String path, Map<String,dynamic> body) async {
    final token=await _storage.read(key:'auth_token');
    final response=await http.post(Uri.parse('${AppConfig.laravelUrl}$path'),headers:{'Content-Type':'application/json','Authorization':'Bearer $token','X-API-KEY':AppConfig.hiddenGemsApiKey},body:jsonEncode(body)).timeout(const Duration(seconds:15));
    if(response.statusCode!=200) throw StateError('Security request failed (${response.statusCode}).');
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
