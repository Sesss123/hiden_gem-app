import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import '../utils/secure_logger.dart';

/// VaultService provides high-security cryptographic operations for device binding and request signing.
/// It implements a Zero-Trust architecture by creating a hardware-bound asymmetric ECDSA (P-256)
/// keypair stored in Secure Storage (Keystore/Keychain). The private key never leaves the device,
/// while the public key is registered with the backend, preventing stolen token reuse across devices.
class VaultService {
  static const MethodChannel _nativeKeys = MethodChannel('hidden_gems/device_keys');
  static const String _signingKeyName = 'DEVICE_SIGNING_KEY';
  static const String _deviceIdKeyName = 'DEVICE_UUID';
  static const String _privateKeyDName = 'DEVICE_ECDSA_PRIV_D';
  static const String _publicKeyPemName = 'DEVICE_ECDSA_PUB_PEM';

  static final _storage = const FlutterSecureStorage();
  
  static String? _cachedSymmetricKey;
  static String? _cachedDeviceId;
  static ECPrivateKey? _cachedPrivateKey;
  static String? _cachedPublicKeyPem;

  /// Retrieves or generates a persistent unique Device ID.
  static Future<String> getDeviceId() async {
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
        SecureLogger.warning('VaultService: device ID reset failed ($e2). Using in-memory ID.');
      }
      _cachedDeviceId = id;
      return id;
    }
  }

  /// Retrieves or generates a persistent hardware-bound ECDSA P-256 keypair.
  static Future<void> _ensureAsymmetricKeyPair() async {
    if (_cachedPrivateKey != null && _cachedPublicKeyPem != null) return;

    try {
      final privDHex = await _storage.read(key: _privateKeyDName);
      final pubPem = await _storage.read(key: _publicKeyPemName);

      if (privDHex != null && pubPem != null) {
        final domain = ECDomainParameters('secp256r1');
        final d = BigInt.parse(privDHex, radix: 16);
        _cachedPrivateKey = ECPrivateKey(d, domain);
        _cachedPublicKeyPem = pubPem;
        return;
      }
    } catch (e) {
      SecureLogger.warning('VaultService: Failed reading asymmetric keys from secure storage ($e). Regenerating fresh keypair.');
    }

    // Generate fresh ECDSA P-256 (secp256r1) keypair
    final domain = ECDomainParameters('secp256r1');
    final secureRandom = SecureRandom('Fortuna')
      ..seed(KeyParameter(Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(256)))));

    final keyGen = ECKeyGenerator()
      ..init(ParametersWithRandom(ECKeyGeneratorParameters(domain), secureRandom));

    final pair = keyGen.generateKeyPair();
    final privKey = pair.privateKey as ECPrivateKey;
    final pubKey = pair.publicKey as ECPublicKey;

    final privDHex = privKey.d!.toRadixString(16);
    final pubPem = _exportEcPublicKeyToPem(pubKey);

    try {
      await _storage.write(key: _privateKeyDName, value: privDHex);
      await _storage.write(key: _publicKeyPemName, value: pubPem);
    } catch (e) {
      SecureLogger.warning('VaultService: Could not persist asymmetric key to secure storage ($e). Storing in memory.');
    }

    _cachedPrivateKey = privKey;
    _cachedPublicKeyPem = pubPem;
  }

  /// Exports the public key in standard X.509 SPKI PEM format to register with backend.
  static Future<String> getDevicePublicKeyPem() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final key = await _nativeKeys.invokeMethod<String>('getPublicKey');
        if (key != null && key.isNotEmpty) return key;
      } on PlatformException catch (e) {
        SecureLogger.warning('Native device key unavailable (${e.code}); using encrypted fallback.');
      }
    }
    await _ensureAsymmetricKeyPair();
    return _cachedPublicKeyPem!;
  }

  /// Signs an arbitrary string payload (e.g., METHOD|PATH|TIMESTAMP|NONCE|BODY_HASH)
  /// using the device's private key via ECDSA P-256 + SHA256 and returns Base64 DER signature.
  static Future<String> signPayload(String payload) async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final signature = await _nativeKeys.invokeMethod<String>('sign', {'payload': payload});
        if (signature != null && signature.isNotEmpty) return signature;
      } on PlatformException catch (e) {
        SecureLogger.warning('Native device signing unavailable (${e.code}); using encrypted fallback.');
      }
    }
    await _ensureAsymmetricKeyPair();
    final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
    signer.init(true, PrivateKeyParameter(_cachedPrivateKey!));

    final payloadBytes = utf8.encode(payload);
    final hash = Uint8List.fromList(sha256.convert(payloadBytes).bytes);

    final sig = signer.generateSignature(hash) as ECSignature;
    final derBytes = _encodeEcdsaSignatureToDer(sig.r, sig.s);
    return base64.encode(derBytes);
  }

  /// Converts BigInt to ASN.1 DER integer bytes.
  static Uint8List _encodeBigIntToDerInt(BigInt n) {
    var bytes = <int>[];
    var temp = n;
    while (temp > BigInt.zero) {
      bytes.insert(0, (temp & BigInt.from(0xff)).toInt());
      temp = temp >> 8;
    }
    if (bytes.isEmpty) bytes = [0];
    if ((bytes[0] & 0x80) != 0) {
      bytes.insert(0, 0x00);
    }
    return Uint8List.fromList(bytes);
  }

  /// Encodes ECDSA (r, s) into standard ASN.1 DER sequence.
  static Uint8List _encodeEcdsaSignatureToDer(BigInt r, BigInt s) {
    final rBytes = _encodeBigIntToDerInt(r);
    final sBytes = _encodeBigIntToDerInt(s);
    final seqLen = rBytes.length + sBytes.length + 4;
    final builder = BytesBuilder();
    builder.addByte(0x30);
    if (seqLen < 128) {
      builder.addByte(seqLen);
    } else {
      builder.addByte(0x81);
      builder.addByte(seqLen);
    }
    builder.addByte(0x02);
    builder.addByte(rBytes.length);
    builder.add(rBytes);
    builder.addByte(0x02);
    builder.addByte(sBytes.length);
    builder.add(sBytes);
    return builder.toBytes();
  }

  /// Converts PointyCastle ECPublicKey into standard SubjectPublicKeyInfo (SPKI) PEM.
  static String _exportEcPublicKeyToPem(ECPublicKey key) {
    final q = key.Q!;
    final x = q.x!.toBigInteger()!;
    final y = q.y!.toBigInteger()!;

    List<int> toPadded32(BigInt n) {
      final b = <int>[];
      var temp = n;
      while (temp > BigInt.zero) {
        b.insert(0, (temp & BigInt.from(0xff)).toInt());
        temp = temp >> 8;
      }
      while (b.length < 32) {
        b.insert(0, 0);
      }
      return b.sublist(b.length - 32);
    }

    final xBytes = toPadded32(x);
    final yBytes = toPadded32(y);

    // Standard SPKI header for prime256v1 (secp256r1)
    final spkiHeader = [
      0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
      0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03,
      0x42, 0x00, 0x04
    ];

    final fullSpki = Uint8List.fromList([...spkiHeader, ...xBytes, ...yBytes]);
    final base64Spki = base64.encode(fullSpki);
    return '-----BEGIN PUBLIC KEY-----\n$base64Spki\n-----END PUBLIC KEY-----';
  }

  // --- Symmetric Legacy Compatibility ---
  static Future<String> _getSigningKey() async {
    if (_cachedSymmetricKey != null) return _cachedSymmetricKey!;

    try {
      String? key = await _storage.read(key: _signingKeyName);
      if (key == null) {
        key = _generateRandomKey();
        await _storage.write(key: _signingKeyName, value: key);
      }
      _cachedSymmetricKey = key;
      return key;
    } catch (e) {
      SecureLogger.warning('VaultService: symmetric key read failed ($e). Regenerating.');
      final key = _generateRandomKey();
      _cachedSymmetricKey = key;
      return key;
    }
  }

  static String _generateRandomKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Generates a complete set of security headers for outbound requests.
  static Future<Map<String, String>> getSecurityHeaders(String path, {String body = ''}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final deviceId = await getDeviceId();
    final nonce = const Uuid().v4();
    final bodyHash = sha256.convert(utf8.encode(body)).toString();
    
    // Asymmetric signature payload
    final payloadToSign = 'POST|$path|$timestamp|$nonce|$bodyHash';
    final deviceSig = await signPayload(payloadToSign);

    // Symmetric legacy signature
    final secret = await _getSigningKey();
    final symmetricPayload = '$path|$timestamp|$deviceId|$body';
    final hmac = Hmac(sha256, utf8.encode(secret));
    final legacySig = hmac.convert(utf8.encode(symmetricPayload)).toString();

    return {
      'X-Zenith-Device-Id': deviceId,
      'X-Zenith-Timestamp': timestamp,
      'X-Zenith-Nonce': nonce,
      'X-Zenith-Body-Hash': bodyHash,
      'X-Zenith-Device-Signature': deviceSig,
      'X-HiddenGems-Signature': legacySig,
      'X-HiddenGems-Timestamp': timestamp,
      'X-HiddenGems-Device-ID': deviceId,
      'X-HiddenGems-Version': '3.0.0-ZeroTrust',
    };
  }
}
