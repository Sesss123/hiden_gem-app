import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'session_quarantine.dart';

/// [EmergencyControlService] — The Zenith Panic Room.
/// 
/// This service connects directly to Firebase Remote Config to allow
/// instant administrative control over the app's security posture.
/// 
/// DURING AN ATTACK:
/// 1. Activate `kill_switch_active` to block all entry.
/// 2. Set `min_app_version` to force users onto a patched build.
/// 3. use `disabled_features` to granularly shut down compromised modules.
class EmergencyControlService {
  static final EmergencyControlService _instance = EmergencyControlService._internal();
  factory EmergencyControlService() => _instance;
  EmergencyControlService._internal();

  final _config = FirebaseRemoteConfig.instance;

  // --- Initialization ---

  Future<void> init() async {
    try {
      await _config.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
      ));

      // Default safety values
      await _config.setDefaults({
        'kill_switch_active': false,
        'min_app_version': '1.0.0',
        'disabled_features': '[]',
        'slow_mode_enabled': false,
        'force_reauth_active': false,
        'maintenance_status_msg': 'The system is undergoing security maintenance.',
      });

      await _config.fetchAndActivate();
      
      // Post-activation: Check for immediate critical actions
      _evaluateEmergencySignals();
    } catch (e) {
      debugPrint('[PanicRoom] Initialization error: $e');
    }
  }

  // --- Public Controls ---

  bool get isKillSwitchActive => _config.getBool('kill_switch_active');
  
  String get maintenanceMessage => _config.getString('maintenance_status_msg');

  bool isFeatureAllowed(String featureId) {
    if (isKillSwitchActive) return false;
    
    final disabledRaw = _config.getString('disabled_features');
    try {
      final List disabledList = json.decode(disabledRaw);
      return !disabledList.contains(featureId);
    } catch (_) {
      return true;
    }
  }

  Future<bool> isVersionAllowed() async {
    final minVersion = _config.getString('min_app_version');
    final actualVersion = (await PackageInfo.fromPlatform()).version;
    
    // Simple semver comparison (1.2.3 -> 10203)
    return _parseVersion(actualVersion) >= _parseVersion(minVersion);
  }

  bool get shouldApplySlowMode => _config.getBool('slow_mode_enabled');

  // --- Internal ---

  void _evaluateEmergencySignals() {
    // 🛡️ POINT 12: Force re-auth if flag is set globally
    if (_config.getBool('force_reauth_active')) {
      debugPrint('[PanicRoom] GLOBAL SIGNAL: Force Re-Auth triggered.');
      SessionQuarantine().evaluate(); // This will trigger sign-out if risk is high
    }
  }

  int _parseVersion(String v) {
    try {
      final parts = v.split('.');
      int total = 0;
      if (parts.isNotEmpty) total += int.parse(parts[0]) * 10000;
      if (parts.length >= 2) total += int.parse(parts[1]) * 100;
      if (parts.length >= 3) total += int.parse(parts[2]);
      return total;
    } catch (_) {
      return 0;
    }
  }
}
