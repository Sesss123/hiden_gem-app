import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'secure_logger.dart';
import '../config/app_config.dart';

class EncryptionUtil {
  static String get _sharedAesKeyBase64 => AppConfig.sharedAesKey;
  static String get _sharedHmacKeyBase64 => AppConfig.sharedHmacKey;

  /// Helper to safely derive a 32-byte AES key from either Base64 or plain string
  static enc.Key _deriveAesKey(String keyStr) {
    try {
      final decoded = base64.decode(keyStr);
      if (decoded.length == 32) return enc.Key(decoded);
    } catch (e) {
      SecureLogger.info("AES key not base64 encoded, falling back to SHA-256 derivation: $e", tag: "Encryption", isBackground: true);
    }
    final bytes = sha256.convert(utf8.encode(keyStr)).bytes;
    return enc.Key(Uint8List.fromList(bytes));
  }

  /// Helper to safely derive HMAC key bytes from either Base64 or plain string
  static List<int> _deriveHmacKey(String keyStr) {
    try {
      return base64.decode(keyStr);
    } catch (e) {
      SecureLogger.info("HMAC key not base64 encoded, falling back to UTF-8 encoding: $e", tag: "Encryption", isBackground: true);
      return utf8.encode(keyStr);
    }
  }

  /// Constant-time comparison to prevent timing attacks.
  static bool safeEqual(String a, String b) {
    final aBytes = utf8.encode(a);
    final bBytes = utf8.encode(b);
    if (aBytes.length != bBytes.length) return false;
    int result = 0;
    for (int i = 0; i < aBytes.length; i++) {
      result |= aBytes[i] ^ bBytes[i];
    }
    return result == 0;
  }

  static enc.Key? _cachedKey;
  static List<int>? _cachedHmacKey;

  /// Call this at app startup to pre-load keys. 
  /// Note: Shared keys are used for public database records (Hidden Gems).
  static Future<void> init() async {
    _cachedKey = _deriveAesKey(_sharedAesKeyBase64);
    _cachedHmacKey = _deriveHmacKey(_sharedHmacKeyBase64);
  }

  static Future<enc.Key> _getOrCreateKey() async {
    if (_cachedKey != null) return _cachedKey!;
    return _deriveAesKey(_sharedAesKeyBase64);
  }

  static Future<List<int>> _getOrCreateHmacKey() async {
    if (_cachedHmacKey != null) return _cachedHmacKey!;
    return _deriveHmacKey(_sharedHmacKeyBase64);
  }

  /// Encrypts data using AES-256 GCM and adds an HMAC signature.
  static Future<String> encrypt(String plainText) async {
    try {
      final key = await _getOrCreateKey();
      final iv = enc.IV.fromSecureRandom(12);
      
      // AES-GCM (Includes internal integrity check)
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      
      final payload = '${iv.base64}:${encrypted.base64}';
      
      // Secondary Integrity Layer: HMAC-SHA256
      final hmacKey = await _getOrCreateHmacKey();
      final hmac = Hmac(sha256, hmacKey);
      final signature = hmac.convert(utf8.encode(payload));
      
      // Final Format: IV:Cipher:Signature
      return '$payload:${signature.toString()}';
    } catch (e) {
      SecureLogger.error("Encryption Failure.", e);
      throw StateError("Encryption failed: $e");
    }
  }

  /// Synchronous encryption for use in models (requires init() to have been called)
  static String encryptSync(String plainText) {
    if (_cachedKey == null || _cachedHmacKey == null) {
      SecureLogger.error("EncryptionUtil not initialized!", null);
      throw StateError("EncryptionUtil not initialized!");
    }
    try {
      final iv = enc.IV.fromSecureRandom(12);
      final encrypter = enc.Encrypter(enc.AES(_cachedKey!, mode: enc.AESMode.gcm));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      
      final payload = '${iv.base64}:${encrypted.base64}';
      final hmac = Hmac(sha256, _cachedHmacKey!);
      final signature = hmac.convert(utf8.encode(payload));
      
      return '$payload:${signature.toString()}';
    } catch (e) {
      SecureLogger.error("Encryption Failure Sync.", e);
      throw StateError("Encryption sync failed: $e");
    }
  }

  /// Decrypts data and verifies both GCM integrity and HMAC signature.
  static Future<String> decrypt(String cipherPayload) async {
    try {
      if (!cipherPayload.contains(':')) return cipherPayload; 

      final parts = cipherPayload.split(':');
      if (parts.length < 3) {
        return _handleLegacyDecryption(cipherPayload);
      }

      final ivBase64 = parts[0];
      final cipherText = parts[1];
      final signature = parts[2];
      
      final payloadToVerify = '$ivBase64:$cipherText';
      
      // 1. Verify HMAC Signature
      final hmacKey = await _getOrCreateHmacKey();
      final hmac = Hmac(sha256, hmacKey);
      final expectedSignature = hmac.convert(utf8.encode(payloadToVerify)).toString();
      
      if (!safeEqual(signature, expectedSignature)) {
        throw Exception("HMAC Integrity Check Failed.");
      }

      // 2. Decrypt & Verify GCM Tag
      final key = await _getOrCreateKey();
      final iv = enc.IV.fromBase64(ivBase64);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      
      return encrypter.decrypt64(cipherText, iv: iv);
    } catch (e) {
      SecureLogger.error("Security Decryption Failure!", e);
      return '{}';
    }
  }

  /// Synchronous decryption for use in models (requires init() to have been called)
  static String decryptSync(String cipherPayload) {
    if (_cachedKey == null || _cachedHmacKey == null) return cipherPayload;
    if (!cipherPayload.contains(':')) return cipherPayload;

    try {
      final parts = cipherPayload.split(':');
      if (parts.length < 3) return cipherPayload;

      final ivBase64 = parts[0];
      final cipherText = parts[1];
      final signature = parts[2];
      
      final payloadToVerify = '$ivBase64:$cipherText';
      final hmac = Hmac(sha256, _cachedHmacKey!);
      final expectedSignature = hmac.convert(utf8.encode(payloadToVerify)).toString();
      if (!safeEqual(signature, expectedSignature)) {
        return '{}';
      }

      final iv = enc.IV.fromBase64(ivBase64);
      final encrypter = enc.Encrypter(enc.AES(_cachedKey!, mode: enc.AESMode.gcm));
      return encrypter.decrypt64(cipherText, iv: iv);
    } catch (e) {
      return '{}';
    }
  }

  static Future<String> _handleLegacyDecryption(String payload) async {
    try {
      final parts = payload.split(':');
      final iv = enc.IV.fromBase64(parts[0]);
      final cipherText = parts[1];
      
      // Use old key alias if versioning was different, but here we assume same key
      final key = await _getOrCreateKey(); 
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(cipherText, iv: iv);
    } catch (e) {
      SecureLogger.warning("Legacy decryption failed for payload: $e", tag: "Encryption");
      return '{}';
    }
  }
}
