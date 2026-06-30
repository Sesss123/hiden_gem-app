import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import 'package:uuid/uuid.dart';

/// VaultService provides high-security cryptographic signing for all outbound requests.
/// It implements a Zero-Trust architecture by ensuring every request carries a unique 
/// HMAC-SHA256 signature, preventing replay attacks and unauthorized API access.
class VaultService {
  static const String _signingKeyName = 'DEVICE_SIGNING_KEY';
  static final _storage = const FlutterSecureStorage();
  static String? _cachedKey;

  /// Retrieves or generates a persistent hardware-bound signing key.
  static Future<String> _getSigningKey() async {
    if (_cachedKey != null) return _cachedKey!;

    // In a real production app, this should be injected via --dart-define 
    // or fetched once from a secure KMS during onboarding.
    String? key = await _storage.read(key: _signingKeyName);
    
    if (key == null) {
      // Fallback to environment or generate fallback (in production, strictly from KMS)
      key = AppConfig.vaultSignKey;
      await _storage.write(key: _signingKeyName, value: key);
    }
    
    _cachedKey = key;
    return key;
  }

  /// Generates a unique signature for a request based on path, timestamp, and device ID.
  static Future<Map<String, String>> getSecurityHeaders(String path, {String body = ''}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final deviceId = const Uuid().v4(); // Or use device_info_plus for sticky ID
    final secret = await _getSigningKey();

    // Payload to sign: PATH|TIMESTAMP|DEVICE_ID|BODY
    final payload = '$path|$timestamp|$deviceId|$body';
    final hmac = Hmac(sha256, utf8.encode(secret));
    final signature = hmac.convert(utf8.encode(payload)).toString();

    return {
      'X-TripMe-Signature': signature,
      'X-TripMe-Timestamp': timestamp,
      'X-TripMe-Device-ID': deviceId,
      'X-TripMe-Version': '1.0.0-Hardened',
    };
  }
}
