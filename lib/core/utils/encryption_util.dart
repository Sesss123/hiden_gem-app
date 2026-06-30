import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'secure_logger.dart';

class EncryptionUtil {
  // SHARED KEYS FOR CROSS-PLATFORM DATA (HIDDEN GEMS)
  // In production, these should be fetched from a secure backend or KMS.
  static const String _sharedAesKeyBase64 = String.fromEnvironment(
    'SHARED_AES_KEY',
    defaultValue: 'uN7U8L4f3k8P8m9Qz2Wp5X7r9tBy1C3v5X7r9tBy1C3=', 
  );
  static const String _sharedHmacKeyBase64 = String.fromEnvironment(
    'SHARED_HMAC_KEY',
    defaultValue: 'kP5v8N2m4Q9z1X3r7tBy9C1v3X5r7tBy9C1v3X5r7tB=',
  );

  static enc.Key? _cachedKey;
  static List<int>? _cachedHmacKey;

  /// Call this at app startup to pre-load keys. 
  /// Note: Shared keys are used for public database records (Hidden Gems).
  static Future<void> init() async {
    _cachedKey = enc.Key.fromBase64(_sharedAesKeyBase64);
    _cachedHmacKey = base64.decode(_sharedHmacKeyBase64);
  }

  static Future<enc.Key> _getOrCreateKey() async {
    if (_cachedKey != null) return _cachedKey!;
    return enc.Key.fromBase64(_sharedAesKeyBase64);
  }

  static Future<List<int>> _getOrCreateHmacKey() async {
    if (_cachedHmacKey != null) return _cachedHmacKey!;
    return base64.decode(_sharedHmacKeyBase64);
  }

  /// Encrypts data using AES-256 GCM and adds an HMAC signature.
  static Future<String> encrypt(String plainText) async {
    try {
      final key = await _getOrCreateKey();
      final iv = enc.IV.fromSecureRandom(16);
      
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
      SecureLogger.error("Encryption Failure. Operating in fallback.", e);
      return plainText;
    }
  }

  /// Synchronous encryption for use in models (requires init() to have been called)
  static String encryptSync(String plainText) {
    if (_cachedKey == null || _cachedHmacKey == null) {
      SecureLogger.error("EncryptionUtil not initialized! Returning plain text.", null);
      return plainText;
    }
    try {
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(_cachedKey!, mode: enc.AESMode.gcm));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      
      final payload = '${iv.base64}:${encrypted.base64}';
      final hmac = Hmac(sha256, _cachedHmacKey!);
      final signature = hmac.convert(utf8.encode(payload));
      
      return '$payload:${signature.toString()}';
    } catch (e) {
      return plainText;
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
      
      if (signature != expectedSignature) {
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
      if (signature != hmac.convert(utf8.encode(payloadToVerify)).toString()) {
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
    } catch (_) {
      return '{}';
    }
  }
}
