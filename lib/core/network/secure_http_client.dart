import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../../data/datasources/sanctum_token_refresher.dart';

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
    _enforceHttps(request);

    final response = await _inner.send(await _prepareSignedRequest(request));

    if (_shouldAttemptSilentRefresh(request, response)) {
      final newToken = await SanctumTokenRefresher.refresh();
      if (newToken != null) {
        final retryRequest = _cloneRequest(request, overrideToken: newToken);
        return await _inner.send(await _prepareSignedRequest(retryRequest, skipTokenLookup: true));
      }
    }

    return response;
  }

  void _enforceHttps(http.BaseRequest request) {
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
  }

  /// Signs [request] in place (timestamp/nonce/signature headers) and
  /// attaches the Sanctum bearer token unless [skipTokenLookup] is true (the
  /// 401-retry path already has the freshly-refreshed token on the request).
  Future<http.BaseRequest> _prepareSignedRequest(http.BaseRequest request, {bool skipTokenLookup = false}) async {
    // Prepare Replay Protection Metadata
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String nonce = _uuid.v4();

    // Generate Request Signature
    // We sign the combination of Method, Path, Timestamp, Nonce, and SHA-256 Body Hash
    // to ensure an attacker cannot modify the payload without breaking the signature.
    final String body = await _getRequestBody(request);
    final String bodyHash = sha256.convert(utf8.encode(body)).toString();
    final String payloadToSign = '${request.method}|${request.url.path}|$timestamp|$nonce|$bodyHash';

    final String signature = _calculateHMAC(payloadToSign);

    // Inject Security Headers
    request.headers['X-Zenith-Timestamp'] = timestamp;
    request.headers['X-Zenith-Nonce'] = nonce;
    request.headers['X-Zenith-Signature'] = signature;
    request.headers['X-Zenith-Version'] = '1.0';

    // BUG-QA-001 Fix: Inject Sanctum Auth Token for Laravel APIs
    // Only inject if it exists and the request is going to our API host
    if (!skipTokenLookup &&
        (request.url.host == Uri.parse(AppConfig.laravelUrl).host ||
            request.url.host == Uri.parse(AppConfig.pythonUrl).host)) {
      final authToken = await _getSanctumToken();
      if (authToken != null && !request.headers.containsKey('Authorization')) {
        request.headers['Authorization'] = 'Bearer $authToken';
      }
    }

    debugPrint('[SecureHTTP] Sending ${request.method} to ${request.url.path} | Signed: true');

    return request;
  }

  /// Whether a 401 response warrants a single silent-refresh-and-retry
  /// attempt. Only applies to Laravel-hosted, token-authed, non-multipart
  /// requests that haven't already been retried once (X-Zenith-Retried) --
  /// see SanctumTokenRefresher for why: a stolen/expired Sanctum token
  /// (config/sanctum.php `expiration`) should recover transparently as long
  /// as the underlying Firebase session is still valid, without ever
  /// retrying more than once or looping.
  bool _shouldAttemptSilentRefresh(http.BaseRequest request, http.StreamedResponse response) {
    if (response.statusCode != 401) return false;
    if (request.headers['X-Zenith-Retried'] == '1') return false;
    if (request is http.MultipartRequest) return false; // v1: skip multipart retry
    if (request.url.host != Uri.parse(AppConfig.laravelUrl).host) return false;
    if (!request.headers.containsKey('Authorization')) return false;
    return true;
  }

  /// Rebuilds an equivalent [http.Request] from the original (non-multipart)
  /// request with a fresh Authorization header and a retry marker. The
  /// original request's body/headers were already consumed by the first
  /// send() call, so this reconstructs from what's still available on the
  /// BaseRequest object (method/url/headers/body — [_getRequestBody] reads
  /// [http.Request.body] directly rather than draining a stream).
  http.Request _cloneRequest(http.BaseRequest original, {required String overrideToken}) {
    final clone = http.Request(original.method, original.url);
    clone.headers.addAll(original.headers);
    clone.headers.remove('X-Zenith-Timestamp');
    clone.headers.remove('X-Zenith-Nonce');
    clone.headers.remove('X-Zenith-Signature');
    clone.headers['Authorization'] = 'Bearer $overrideToken';
    clone.headers['X-Zenith-Retried'] = '1';
    if (original is http.Request) {
      clone.bodyBytes = Uint8List.fromList(original.bodyBytes);
    }
    return clone;
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
