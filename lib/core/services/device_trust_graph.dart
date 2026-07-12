import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _shield = IntegrityShield();

  // Thresholds
  static const int _maxAccountsPerDevice = 3;

  // --- Public API ---

  /// Records the device–account binding and includes IP hashing for forensics.
  Future<DeviceTrustResult> recordAndVerifyLogin({
    required String deviceHash,
    required String platform,
    String? rawIp, // 🛡️ POINT 13: IP Hashing Correlation
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return DeviceTrustResult.unknown;

    final hashedIp = rawIp != null ? _hashIp(rawIp) : null;

    try {
      final batch = _firestore.batch();
      final bindingRef = _firestore.collection('device_trust').doc('${deviceHash}_$uid');

      batch.set(bindingRef, {
        'uid': uid,
        'deviceHash': deviceHash,
        'hashedIp': hashedIp,
        'platform': platform,
        'lastSeenAt': FieldValue.serverTimestamp(),
        'loginCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      await batch.commit();

      final deviceAccounts = await _countAccountsForDevice(deviceHash);
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

  String _hashIp(String ip) {
    // 🛡️ POINT 13: Salted HMAC approach for IP tracking
    const salt = 'ZENITH_NET_FORENSIC_SALT_2026';
    final bytes = utf8.encode('$ip|$salt');
    return sha256.convert(bytes).toString().substring(0, 32); // Truncated for privacy
  }

  /// Counts distinct accounts bound to this device hash, via the Laravel
  /// backend — firestore.rules only allows admins to read device_trust
  /// directly (a regular client can write its own binding, but can never
  /// query other users' bindings), so this must be resolved server-side.
  Future<int> _countAccountsForDevice(String deviceHash) async {
    try {
      final client = SecureHttpClient(http.Client());
      final uri = Uri.parse('${AppConfig.laravelUrl}/security/device-account-count?deviceHash=$deviceHash');
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
