import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../utils/secure_logger.dart';

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
  /// On some devices (custom ROMs, a Keystore left in a bad state after a
  /// factory reset) reading/writing secure storage can throw instead of
  /// just returning null. Without a fallback, that exception would
  /// otherwise propagate uncaught into every signed HTTP request this
  /// service backs — so on failure, delete the corrupt entry and generate
  /// a fresh key rather than leaving the app unable to sign any request.
  static Future<String> _getSigningKey() async {
    if (_cachedKey != null) return _cachedKey!;

    try {
      String? key = await _storage.read(key: _signingKeyName);

      if (key == null) {
        key = _generateRandomKey();
        await _storage.write(key: _signingKeyName, value: key);
      }

      _cachedKey = key;
      return key;
    } catch (e) {
      SecureLogger.warning('VaultService: secure storage read/write failed for signing key ($e). Resetting and regenerating.');
      final key = _generateRandomKey();
      try {
        await _storage.delete(key: _signingKeyName);
        await _storage.write(key: _signingKeyName, value: key);
      } catch (e2) {
        SecureLogger.warning('VaultService: signing key reset also failed ($e2). Using in-memory-only key for this session.');
      }
      _cachedKey = key;
      return key;
    }
  }

  static String _generateRandomKey() {
    // Generate a secure random 256-bit (32-byte) key
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Retrieves or generates a persistent unique Device ID. Same reset-on-
  /// failure behavior as _getSigningKey() — see that method's comment.
  static Future<String> _getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      String? id = await _storage.read(key: _deviceIdKeyName);
      if (id == null) {
        id = const Uuid().v4();
        await _storage.write(key: _deviceIdKeyName, value: id);
      }

      _cachedDeviceId = id;
      return id;
    } catch (e) {
      SecureLogger.warning('VaultService: secure storage read/write failed for device ID ($e). Resetting and regenerating.');
      final id = const Uuid().v4();
      try {
        await _storage.delete(key: _deviceIdKeyName);
        await _storage.write(key: _deviceIdKeyName, value: id);
      } catch (e2) {
        SecureLogger.warning('VaultService: device ID reset also failed ($e2). Using in-memory-only ID for this session.');
      }
      _cachedDeviceId = id;
      return id;
    }
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
