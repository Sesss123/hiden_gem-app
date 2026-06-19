import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'integrity_shield.dart';

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

  Future<int> _countAccountsForDevice(String deviceHash) async {
    final snapshot = await _firestore
        .collection('device_trust')
        .where('deviceHash', isEqualTo: deviceHash)
        .get();
    return snapshot.docs.map((d) => d.get('uid')).toSet().length;
  }
}

enum DeviceTrustResult { clean, suspicious, unknown }
