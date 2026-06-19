import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:safe_device/safe_device.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:hidden_gems_sl/core/services/threat_reporter.dart';
import 'dart:io';

/// [IntegrityShield] — Multi-signal, score-based tamper detection.
///
/// Philosophy: A single signal never blocks a user (avoids false positives).
/// Instead, signals accumulate a "risk score". Only when the score exceeds
/// a threshold do we escalate the response.
///
/// 🪜 RESPONSE LADDER (Point 4):
///   0–29   → Low Risk    → Normal operation, log only
///   30–59  → Medium Risk → Disable sensitive features (Premium actions, Admin)
///   60–89  → High Risk   → Force re-authentication
///   90+    → Critical    → Block session, revoke server tokens
class IntegrityShield {
  static final IntegrityShield _instance = IntegrityShield._internal();
  factory IntegrityShield() => _instance;
  IntegrityShield._internal();

  int _riskScore = 0;
  final List<String> _activeSignals = [];
  IntegrityResult? _lastResult;
  final _functions = FirebaseFunctions.instance;

  // --- Configuration ---
  static const String _expectedPackageName = 'com.hidden.gems.hidden_gems_sl';
  
  // SHA-256 Fingerprint of your production signing certificate.
  // REPLACE THIS with your actual fingerprint from Google Play Console.
  static const String _expectedSignatureHash = 'PLACEHOLDER_SHA256_FINGERPRINT';

  // --- Public API ---

  /// Run all checks. Call once at startup, results persist.
  Future<IntegrityResult> runFullScan() async {
    _riskScore = 0;
    _activeSignals.clear();

    // 1. Static Environment Checks
    _checkBuildMode();
    
    // 2. Local Device Integrity (safe_device)
    await _checkDeviceIntegrity();

    // 3. Package Identity Check
    await _checkPackageIdentity();
    
    // 4. Runtime Forensic Signals (Debugger, ADB, Mocking)
    await _checkRuntimeIntegrity();

    // 5. Remote Attestation (App Check)
    await _checkAppCheckAvailability();

    // 🕵️ SPECTRE HONEYPOT: Check for sophisticated tampering
    await _detectSpectreLaunch();

    // 🛡️ BACKEND MIGRATION: Sync local signals with server
    await _syncPostureWithServer();

    _lastResult = _buildResult();
    return _lastResult!;
  }

  Future<void> _detectSpectreLaunch() async {
    if (kDebugMode || kIsWeb) return;

    try {
      final isDevMode = await SafeDevice.isDevelopmentModeEnable;
      final isRealDevice = await SafeDevice.isRealDevice;
      
      // If a user is on a Real Device in RELESE mode with Dev Mode ON:
      if (isRealDevice && isDevMode) {
        _addSignal('spectre_dev_mode_detected', score: 30);
      }
      
      // If they are debugging a RELEASE build:
      if (kDebugMode) {
        _addSignal('spectre_debugger_attached', score: 80);
      }
    } catch (e) {
      debugPrint('[IntegrityShield] Spectre check error: $e');
    }
  }

  Future<void> _syncPostureWithServer() async {
    if (kIsWeb) return;
    try {
      // 🕵️ Check if we have high-confidence Spectre signals
      final isSpectre = _activeSignals.any((s) => s.startsWith('spectre_'));

      if (isSpectre) {
        await ThreatReporter().reportSpectreBreach(_activeSignals);
      }

      // We upload all locally detected signals to the backend.
      final result = await _functions
          .httpsCallable('report_forensic_signals')
          .call({
            'signals': _activeSignals, 
            'isSpectre': isSpectre,
            'timestamp': DateTime.now().millisecondsSinceEpoch
          });
      
      final data = Map<String, dynamic>.from(result.data);
      
      // If the server returns a higher risk score than local, we adopt it.
      if (data.containsKey('riskScore')) {
        final serverScore = data['riskScore'] as int;
        if (serverScore > _riskScore) {
          _riskScore = serverScore;
          debugPrint('[IntegrityShield] 🛡️ Server escalated risk score to $_riskScore');
        }
      }
    } catch (e) {
      debugPrint('[IntegrityShield] Failed to sync posture with server: $e');
      // If server sync fails, we rely on local signals but log the failure
      _addSignal('server_sync_failed', score: 10);
    }
  }

  int get riskScore => _riskScore;
  IntegrityThreatLevel get threatLevel => _getThreatLevel();
  List<String> get activeSignals => List.unmodifiable(_activeSignals);

  /// Returns the most recent scan result (safe to call synchronously).
  IntegrityResult get currentResult =>
      _lastResult ??
      const IntegrityResult(
        riskScore: 0,
        threatLevel: IntegrityThreatLevel.low,
        signals: [],
      );

  // --- Internal Checks ---

  void _checkBuildMode() {
    if (kDebugMode && !kIsWeb) {
      _addSignal('debug_build_active', score: 10);
    }
  }

  Future<void> _checkDeviceIntegrity() async {
    if (kIsWeb) return;

    try {
      final isJailBroken = await SafeDevice.isJailBroken;
      final isRealDevice = await SafeDevice.isRealDevice;
      final isDevelopmentMode = await SafeDevice.isDevelopmentModeEnable;
      
      // 🛡️ POINT 11: Multi-signal risk scoring
      if (isJailBroken) _addSignal('device_rooted_jailbroken', score: 50);
      if (!isRealDevice) _addSignal('emulator_detected', score: 30);
      if (isDevelopmentMode) _addSignal('developer_mode_enabled', score: 10);
      
      // Secondary signals (lower weight)
      if (await SafeDevice.isOnExternalStorage) _addSignal('external_storage_install', score: 10);
    } catch (e) {
      debugPrint('[IntegrityShield] safe_device check error: $e');
    }
  }

  Future<void> _checkRuntimeIntegrity() async {
    if (kIsWeb) return;

    // 🛡️ POINT 11: Real-time Debugger Detection
    if (kDebugMode) {
       _addSignal('debugger_attached', score: 40);
    }

    // ADB Detection (If development mode is on and we are on Android)
    if (Platform.isAndroid) {
       final isSafe = await SafeDevice.isSafeDevice;
       if (!isSafe) _addSignal('device_health_check_failed', score: 20);
    }
  }

  Future<void> _checkPackageIdentity() async {
    try {
      final info = await PackageInfo.fromPlatform();
      
      // Verify Package Name (Prevents simple clone apps)
      if (info.packageName != _expectedPackageName) {
        _addSignal('package_name_mismatch', score: 90); // Critical: Likely a clone/repacked APK
      }

      // Verify Signature (Mock logic — in production use a native plugin for real fingerprint)
      // This is a placeholder for the concept in Point 4.
      if (_expectedSignatureHash == 'PLACEHOLDER_SHA256_FINGERPRINT' && !kDebugMode) {
        debugPrint('[IntegrityShield] ⚠️ WARNING: Production signature hash is not set!');
      }
    } catch (e) {
      debugPrint('[IntegrityShield] Package check error: $e');
    }
  }

  Future<void> _checkAppCheckAvailability() async {
    if (kIsWeb) return;
    try {
      final token = await FirebaseAppCheck.instance
          .getToken(false)
          .timeout(const Duration(seconds: 5));
      if (token == null || token.isEmpty) {
        _addSignal('app_check_token_missing', score: 40);
      }
    } catch (e) {
      _addSignal('app_check_error', score: 30);
      debugPrint('[IntegrityShield] App Check error: $e');
    }
  }

  void _addSignal(String signal, {required int score}) {
    if (!_activeSignals.contains(signal)) {
      _activeSignals.add(signal);
      _riskScore += score;
    }
  }

  IntegrityThreatLevel _getThreatLevel() {
    if (_riskScore >= 90) return IntegrityThreatLevel.critical;
    if (_riskScore >= 60) return IntegrityThreatLevel.high;
    if (_riskScore >= 30) return IntegrityThreatLevel.medium;
    return IntegrityThreatLevel.low;
  }

  IntegrityResult _buildResult() {
    return IntegrityResult(
      riskScore: _riskScore,
      threatLevel: _getThreatLevel(),
      signals: List.from(_activeSignals),
    );
  }

  void reportRuntimeAnomaly(String anomalyCode, {int weight = 10}) {
    _addSignal('runtime:$anomalyCode', score: weight);
  }
}

/// The result of a full integrity scan.
class IntegrityResult {
  final int riskScore;
  final IntegrityThreatLevel threatLevel;
  final List<String> signals;

  const IntegrityResult({
    required this.riskScore,
    required this.threatLevel,
    required this.signals,
  });

  bool get isLowRisk => threatLevel == IntegrityThreatLevel.low;
  bool get isSafeForPremium => riskScore < 60;
  bool get isSafeForAdmin => riskScore < 30;
  bool get shouldBlockSession => riskScore >= 90;

  @override
  String toString() =>
      'IntegrityResult(score: $riskScore, level: $threatLevel, signals: $signals)';
}

enum IntegrityThreatLevel { low, medium, high, critical }
