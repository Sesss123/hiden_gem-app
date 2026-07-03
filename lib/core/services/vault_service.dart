import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// VaultService provides high-security cryptographic signing for all outbound requests.
/// It implements a Zero-Trust architecture by ensuring every request carries a unique 
/// HMAC-SHA256 signature, preventing replay attacks and unauthorized API access.
class VaultService {
  static const String _signingKeyName = 'DEVICE_SIGNING_KEY';
  static const String _deviceIdKeyName = 'DEVICE_UUID';
  static final _storage = const FlutterSecureStorage();
  static String? _cachedKey;
  static String? _cachedDeviceId;

  /// Retrieves or generates a persistent hardware-bound signing key.
  static Future<String> _getSigningKey() async {
    if (_cachedKey != null) return _cachedKey!;

    String? key = await _storage.read(key: _signingKeyName);
    
    if (key == null) {
      // Generate a secure random 256-bit (32-byte) key
      final random = Random.secure();
      final bytes = List<int>.generate(32, (i) => random.nextInt(256));
      key = base64Url.encode(bytes);
      await _storage.write(key: _signingKeyName, value: key);
    }
    
    _cachedKey = key;
    return key;
  }

  /// Retrieves or generates a persistent unique Device ID.
  static Future<String> _getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;
    
    String? id = await _storage.read(key: _deviceIdKeyName);
    if (id == null) {
      id = const Uuid().v4();
      await _storage.write(key: _deviceIdKeyName, value: id);
    }
    
    _cachedDeviceId = id;
    return id;
  }

  /// Generates a unique signature for a request based on path, timestamp, and device ID.
  static Future<Map<String, String>> getSecurityHeaders(String path, {String body = ''}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final deviceId = await _getDeviceId();
    final secret = await _getSigningKey();

    // Payload to sign: PATH|TIMESTAMP|DEVICE_ID|BODY
    final payload = '$path|$timestamp|$deviceId|$body';
    final hmac = Hmac(sha256, utf8.encode(secret));
    final signature = hmac.convert(utf8.encode(payload)).toString();

    return {
      'X-HiddenGems-Signature': signature,
      'X-HiddenGems-Timestamp': timestamp,
      'X-HiddenGems-Device-ID': deviceId,
      'X-HiddenGems-Version': '2.0.0-Hardened',
    };
  }
}
