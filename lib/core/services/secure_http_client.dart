import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

class SecureHttpClient {
  static final SecureHttpClient _instance = SecureHttpClient._internal();
  factory SecureHttpClient() => _instance;

  SecureHttpClient._internal();

  /// Creates a pinned HTTP client using `http_certificate_pinning`.
  /// We enforce SSL pinning for our production domains.
  Future<http.Client> getClient() async {
    // If we are in debug mode, or on web, just return a normal client.
    if (kDebugMode || kIsWeb) {
      return http.Client();
    }

    // In production, we pin the certificates.
    // NOTE: You must update these hashes with the actual SHA-256 fingerprint of your SSL certificates.
    final List<String> allowedShas = [
      "PLACEHOLDER_SHA256_FINGERPRINT_FOR_API_HIDDENGEMSSL_COM", // Primary Leaf Certificate
      "PLACEHOLDER_SHA256_FINGERPRINT_FOR_BACKUP_ROOT_CA", // Backup Root CA Pin (SEC-006)
      "PLACEHOLDER_SHA256_FINGERPRINT_FOR_AI_HIDDENGEMSSL_COM",
    ];

    final secureClient = SecureHttpClientAdapter(allowedShas);
    return secureClient;
  }
}

/// A custom IO client that enforces pinning using `HttpCertificatePinning.check`.
/// This intercepts requests and performs a custom TLS check before executing them.
class SecureHttpClientAdapter extends http.BaseClient {
  final List<String> allowedShas;
  final http.Client _inner = http.Client();

  SecureHttpClientAdapter(this.allowedShas);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final host = request.url.host;
    
    // Only pin our specific backend domains.
    if (host == "api.hiddengemssl.com" || host == "ai.hiddengemssl.com") {
      try {
        final secure = await HttpCertificatePinning.check(
          serverURL: request.url.toString(),
          headerHttp: request.headers,
          sha: SHA.SHA256,
          allowedSHAFingerprints: allowedShas,
          timeout: 50,
        );

        if (!secure.contains("CONNECTION_SECURE")) {
          throw const SocketException("SSL Certificate Pinning validation failed!");
        }
      } catch (e) {
        throw SocketException("SSL Certificate Pinning validation failed: $e");
      }
    }

    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}
