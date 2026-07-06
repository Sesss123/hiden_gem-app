import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

/// [SecureHttpClient] — Hardened network layer with signing and replay protection.
///
/// FEATURES:
/// 1. **HTTPS Enforcement**: Strictly blocks non-secure `http://` calls.
/// 2. **Replay Attack Protection**: Nonce + Timestamp headers on every request.
/// 3. **Request Integrity**: HMAC-SHA256 signature of the payload and metadata.
/// 4. **Standard Interface**: Wraps `http.Client` for drop-in replacement.
class SecureHttpClient extends http.BaseClient {
  final http.Client _inner;
  final String _sharedSecret;
  final _uuid = const Uuid();

  /// Create a secure client. 
  /// The [sharedSecret] must match the key on your backend validation layer.
  SecureHttpClient(this._inner, {String? sharedSecret}) 
      : _sharedSecret = sharedSecret ?? AppConfig.sharedSecret;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 1. Force HTTPS (Point 1)
    if (request.url.scheme != 'https') {
      final isLocal = request.url.host.contains('localhost') || request.url.host.contains('127.0.0.1') || request.url.host.contains('10.0.2.2') || request.url.host.startsWith('192.168.');
      if (!isLocal) {
        if (!kDebugMode) {
          throw SecurityException("Insecure HTTP requests are strictly prohibited in production: ${request.url}");
        } else {
          debugPrint('WARNING: Non-secure HTTP request to ${request.url}');
        }
      }
    }

    // 2. Prepare Replay Protection Metadata
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String nonce = _uuid.v4();

    // 3. Generate Request Signature
    // We sign the combination of Method, Path, Timestamp, Nonce, and SHA-256 Body Hash
    // to ensure an attacker cannot modify the payload without breaking the signature.
    final String body = await _getRequestBody(request);
    final String bodyHash = sha256.convert(utf8.encode(body)).toString();
    final String payloadToSign = '${request.method}|${request.url.path}|$timestamp|$nonce|$bodyHash';
    
    final String signature = _calculateHMAC(payloadToSign);

    // 4. Inject Security Headers
    request.headers['X-Zenith-Timestamp'] = timestamp;
    request.headers['X-Zenith-Nonce'] = nonce;
    request.headers['X-Zenith-Signature'] = signature;
    request.headers['X-Zenith-Version'] = '1.0';

    // BUG-QA-001 Fix: Inject Sanctum Auth Token for Laravel APIs
    // Only inject if it exists and the request is going to our API host
    if (request.url.host.contains('hiddengemssl.com') || request.url.host.contains('10.0.2.2')) {
      final authToken = await _getSanctumToken();
      if (authToken != null && !request.headers.containsKey('Authorization')) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
    }

    debugPrint('[SecureHTTP] Sending ${request.method} to ${request.url.path} | Signed: true');

    return _inner.send(request);
  }

  Future<String?> _getSanctumToken() async {
    // Importing dynamically to avoid circular dependencies if any, 
    // but a direct import is cleaner. For this file, we can just use the storage package directly 
    // or rely on UserPreferenceService.
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'auth_token');
  }

  // --- Internal Helpers ---

  String _calculateHMAC(String data) {
    final key = utf8.encode(_sharedSecret);
    final bytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  Future<String> _getRequestBody(http.BaseRequest request) async {
    if (request is http.Request) {
      return request.body;
    } else if (request is http.MultipartRequest) {
      // BUG-009 Fix: Include multipart form fields and file metadata in HMAC signature
      final fieldsStr = request.fields.entries.map((e) => '${e.key}=${e.value}').join('&');
      final filesStr = request.files.map((f) => '${f.field}:${f.filename}:${f.length}').join('&');
      return '$fieldsStr|$filesStr';
    }
    return ''; 
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  @override
  String toString() => 'SecurityException: $message';
}
