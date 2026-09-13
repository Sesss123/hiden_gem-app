import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import 'vault_service.dart';

/// Maintains the short-lived, device-bound token used in addition to the
/// Firebase/Sanctum identity token. The plaintext never leaves secure storage
/// except in the TLS request header; Firestore stores only its SHA-256 hash.
class SessionTokenManager {
  SessionTokenManager._();

  static const _storage = FlutterSecureStorage();
  static const _sessionIdKey = 'ZENITH_SESSION_ID';
  static const _sessionTokenKey = 'ZENITH_SESSION_TOKEN';
  static const _sessionExpiryKey = 'ZENITH_SESSION_EXPIRY';
  static Future<void>? _rotationInFlight;

  static Future<void> ensureActiveSession({bool forceRotate = false}) async {
    final expiryRaw = await _storage.read(key: _sessionExpiryKey);
    final expiry = int.tryParse(expiryRaw ?? '');
    final token = await _storage.read(key: _sessionTokenKey);
    final shouldRotate = forceRotate || token == null || expiry == null ||
        DateTime.now().millisecondsSinceEpoch >= expiry - 5 * 60 * 1000;
    if (!shouldRotate) return;

    if (_rotationInFlight != null) return _rotationInFlight!;
    final future = _rotate(token);
    _rotationInFlight = future;
    try {
      await future;
    } finally {
      _rotationInFlight = null;
    }
  }

  static Future<void> _rotate(String? currentToken) async {
    var sessionId = await _storage.read(key: _sessionIdKey);
    sessionId ??= const Uuid().v4();
    final deviceId = await VaultService.getDeviceId();
    final presentedHash = currentToken == null
        ? ''
        : sha256.convert(utf8.encode(currentToken)).toString();

    final result = await FirebaseFunctions.instance
        .httpsCallable('rotate_session_token')
        .call(<String, dynamic>{
      'sessionId': sessionId,
      'presentedTokenHash': presentedHash,
      'deviceId': deviceId,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    final newToken = data['newToken'] as String?;
    if (newToken == null || newToken.isEmpty) {
      throw StateError('Session rotation returned no token.');
    }
    final expiresIn = (data['expiresInSeconds'] as num?)?.toInt() ?? 3600;
    await _storage.write(key: _sessionIdKey, value: sessionId);
    await _storage.write(key: _sessionTokenKey, value: newToken);
    await _storage.write(
      key: _sessionExpiryKey,
      value: (DateTime.now().millisecondsSinceEpoch + expiresIn * 1000)
          .toString(),
    );
  }

  static Future<Map<String, String>> securityHeaders() async {
    await ensureActiveSession();
    final sessionId = await _storage.read(key: _sessionIdKey);
    final token = await _storage.read(key: _sessionTokenKey);
    if (sessionId == null || token == null) return const {};
    return {
      'X-Zenith-Session-Id': sessionId,
      'X-Zenith-Session-Token': token,
    };
  }

  static Future<void> startNewSession() async {
    await clear();
    await ensureActiveSession();
  }

  static Future<String?> get currentSessionId =>
      _storage.read(key: _sessionIdKey);

  static Future<void> clear() async {
    await _storage.delete(key: _sessionIdKey);
    await _storage.delete(key: _sessionTokenKey);
    await _storage.delete(key: _sessionExpiryKey);
  }
}
