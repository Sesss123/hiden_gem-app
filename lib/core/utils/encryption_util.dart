import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'secure_logger.dart';
import '../config/app_config.dart';

class EncryptionUtil {
  static const _storage = FlutterSecureStorage();
  static const String _deviceAesKeyName = 'DEVICE_AES_KEY';
  static const String _deviceHmacKeyName = 'DEVICE_HMAC_KEY';

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

  /// Call this at app startup to load or generate secure hardware-backed keys.
  static Future<void> init() async {
    try {
      String? aesKeyStr = await _storage.read(key: _deviceAesKeyName);
      if (aesKeyStr == null) {
        final random = Random.secure();
        final bytes = List<int>.generate(32, (i) => random.nextInt(256));
        aesKeyStr = base64Url.encode(bytes);
        await _storage.write(key: _deviceAesKeyName, value: aesKeyStr);
      }
      _cachedKey = _deriveAesKey(aesKeyStr);

      String? hmacKeyStr = await _storage.read(key: _deviceHmacKeyName);
      if (hmacKeyStr == null) {
        final random = Random.secure();
        final bytes = List<int>.generate(32, (i) => random.nextInt(256));
        hmacKeyStr = base64Url.encode(bytes);
        await _storage.write(key: _deviceHmacKeyName, value: hmacKeyStr);
      }
      _cachedHmacKey = _deriveHmacKey(hmacKeyStr);
    } catch (e) {
      SecureLogger.warning("Keystore access failed, falling back to shared config: $e", tag: "Encryption");
      _cachedKey = _deriveAesKey(AppConfig.sharedAesKey);
      _cachedHmacKey = _deriveHmacKey(AppConfig.sharedHmacKey);
    }
  }

  static Future<enc.Key> _getOrCreateKey() async {
    if (_cachedKey != null) return _cachedKey!;
    await init();
    return _cachedKey!;
  }

  static Future<List<int>> _getOrCreateHmacKey() async {
    if (_cachedHmacKey != null) return _cachedHmacKey!;
    await init();
    return _cachedHmacKey!;
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
      SecureLogger.error("Encryption Failure.: $e");
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
      SecureLogger.error("Encryption Failure Sync.: $e");
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
      SecureLogger.error("Security Decryption Failure!: $e");
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

  /// Encrypts [plainText] with an arbitrary caller-supplied key (not the
  /// device-bound key) — used for family-share E2EE where the key is a
  /// per-link random secret embedded in a URL fragment, never persisted to
  /// Firestore or known server-side. Returns "ivBase64:cipherBase64" (no
  /// HMAC segment — GCM's own tag authenticates, and the recipient decrypts
  /// via plain WebCrypto JS, not this class).
  static String encryptWithKey(String plainText, String keyStr) {
    final key = _deriveAesKey(keyStr);
    final iv = enc.IV.fromSecureRandom(12);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts a payload produced by [encryptWithKey]. Returns null on any
  /// failure (bad key, tampered ciphertext, malformed payload) rather than
  /// throwing — callers treat null as "cannot display".
  static String? decryptWithKey(String payload, String keyStr) {
    try {
      final parts = payload.split(':');
      if (parts.length != 2) return null;
      final key = _deriveAesKey(keyStr);
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      return encrypter.decrypt64(parts[1], iv: iv);
    } catch (e) {
      return null;
    }
  }

  /// Legacy pre-HMAC payload format ("iv:cipher", no signature segment) —
  /// reachable only from decrypt() (the async entry point), which currently
  /// has no callers anywhere in the app; decryptSync() (the one active
  /// caller, via DiscoveryPlace.fromJson) returns 2-part payloads unchanged
  /// instead of routing here. Kept for forward/backward compatibility with
  /// any legacy-format data still on a device from before the HMAC-signed
  /// format was introduced.
  ///
  /// CBC mode has no built-in integrity check (unlike GCM's auth tag used
  /// everywhere else in this file) — a genuinely old payload decrypts fine,
  /// but corrupted or tampered ciphertext can decrypt "successfully" into
  /// garbage with no error. There's no HMAC available for this legacy
  /// format to verify against, so the only realistic hardening is to bound
  /// the strict length check below (prevents a malformed payload from being
  /// silently accepted) — callers must still treat this path's output as
  /// less trustworthy than the HMAC-verified format in decrypt().
  static Future<String> _handleLegacyDecryption(String payload) async {
    try {
      final parts = payload.split(':');
      if (parts.length != 2) return '{}';
      final ivBase64 = parts[0];
      final cipherText = parts[1];
      final iv = enc.IV.fromBase64(ivBase64);

      final key = await _getOrCreateKey();
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(cipherText, iv: iv);
    } catch (e) {
      SecureLogger.warning("Legacy decryption failed for payload: $e", tag: "Encryption");
      return '{}';
    }
  }
}
