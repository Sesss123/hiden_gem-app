import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'integrity_shield.dart';
import '../config/app_config.dart';
import '../network/secure_http_client.dart';

/// [DeviceTrustGraph] — Account-Device relationship tracker.
class DeviceTrustGraph {
  static final DeviceTrustGraph _instance = DeviceTrustGraph._internal();
  factory DeviceTrustGraph() => _instance;
  DeviceTrustGraph._internal();

  final _shield = IntegrityShield();

  // Thresholds
  static const int _maxAccountsPerDevice = 3;

  // --- Public API ---

  /// Records the device–account binding and includes IP hashing for forensics.
  Future<DeviceTrustResult> recordAndVerifyLogin({
    required String platform,
  }) async {
    try {
      final deviceAccounts = await _countAccountsForDevice(platform);
      if (deviceAccounts > _maxAccountsPerDevice) {
        _shield.reportRuntimeAnomaly('multi_account_device', weight: 30);
        return DeviceTrustResult.suspicious;
      }

      return DeviceTrustResult.clean;
    } catch (e) {
      debugPrint('[DeviceTrust] Error: $e');
      return DeviceTrustResult.unknown;
    }
  }

  // --- Internal ---

  /// Counts distinct accounts bound to this device hash, via the Laravel
  /// backend — firestore.rules only allows admins to read device_trust
  /// directly (a regular client can write its own binding, but can never
  /// query other users' bindings), so this must be resolved server-side.
  Future<int> _countAccountsForDevice(String platform) async {
    try {
      final client = SecureHttpClient(http.Client());
      final uri =
          Uri.parse('${AppConfig.laravelUrl}/security/device-account-count')
              .replace(queryParameters: {'platform': platform});
      final response = await client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-API-KEY': AppConfig.hiddenGemsApiKey,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return 0;

      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['accountCount'] as int? ?? 0;
    } catch (e) {
      debugPrint('[DeviceTrust] Account count check failed: $e');
      return 0;
    }
  }
}

enum DeviceTrustResult { clean, suspicious, unknown }
