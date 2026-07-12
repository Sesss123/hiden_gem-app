import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// [SecureNetworkOverrides] — Production-grade SSL/TLS hardening.
///
/// Features:
/// 1. **Multi-Host SSL Pinning**: Strictly verifies the leaf certificate
///    of specific high-value hosts (Point 1).
/// 2. **Zero-Trust Verification**: Unconditionally rejects all invalid/self-signed 
///    certificates across all build environments (Debug, Profile, Release).
/// 3. **Audit Logging**: Logs detailed certificate validation errors when
///    running in debug mode.
class SecureNetworkOverrides extends HttpOverrides {
  
  /// SSL Fingerprints (SHA-256) of your production server leaf certificates.
  /// Format: { "hostname": ["fingerprint1", "fingerprint2"] }
  ///
  /// SECURITY FIX: api.hiddengemssl.com / ai.hiddengemssl.com previously had
  /// HARDCODED PLACEHOLDER fingerprints here (literal filler hex, not real
  /// certificate hashes) — since pinnedContext below trusts no CA roots,
  /// badCertificateCallback fires on every connection to these hosts, and a
  /// pin that can never match a real cert means every connection was always
  /// rejected. That's not "pinning to a wrong value" (still dangerous) —
  /// it's a self-inflicted denial of service against the app's own
  /// production API, worse than having no pinning at all. Real fingerprints
  /// need to be obtained (e.g. `openssl s_client -connect
  /// api.hiddengemssl.com:443 | openssl x509 -fingerprint -sha256 -noout`)
  /// and set via --dart-define before these two hosts can be safely
  /// re-added here. Until then, only the SSL_PIN_HOST/SSL_PIN_FINGERPRINT
  /// env-var pair (a single pin for whichever host you actually configure
  /// it for) is pinned — every other host uses the standard
  /// trusted-CA-roots client below, same as normal HTTPS.
  static const String _sslHost = String.fromEnvironment('SSL_PIN_HOST', defaultValue: '');
  static const String _sslFingerprint = String.fromEnvironment('SSL_PIN_FINGERPRINT', defaultValue: '');

  static final Map<String, List<String>> _pinnedHosts = {
    if (_sslHost.isNotEmpty && _sslFingerprint.isNotEmpty)
      _sslHost: [_sslFingerprint],
  };

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // 1. Context that trusts standard roots (for external APIs like google.com check)
    final SecurityContext standardContext = SecurityContext(withTrustedRoots: true);
    final HttpClient standardClient = super.createHttpClient(standardContext);
    
    // 2. Context that does NOT trust standard roots (forces verification callback for every connection)
    final SecurityContext pinnedContext = SecurityContext(withTrustedRoots: false);
    final HttpClient pinnedClient = super.createHttpClient(pinnedContext);

    standardClient.connectionTimeout = const Duration(seconds: 10);
    pinnedClient.connectionTimeout = const Duration(seconds: 10);

    // Setup strict certificate verification callback on the pinned client
    pinnedClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
      if (_pinnedHosts.containsKey(host)) {
        final fingerprint = sha256.convert(cert.der).toString();
        final pins = _pinnedHosts[host]!;
        if (pins.contains(fingerprint)) {
          debugPrint('[Security] SSL Pin Match for $host');
          return true; // Trusted by PIN
        }
        
        debugPrint('[Security] 🚨 SSL PIN MISMATCH for $host! Expected: $pins Got: $fingerprint');
        return false; // REJECT: Possible MITM
      }
      return false; // REJECT all others
    };

    // Setup standard client certificate validation rules
    standardClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
      if (kDebugMode) {
        debugPrint('[Security] WARNING: Invalid SSL certificate encountered for $host:$port.');
      }
      return false; // Strictly reject invalid SSL certificates in all environments
    };

    return SecureHttpClientWrapper(standardClient, pinnedClient, _pinnedHosts);
  }
}

/// A wrapper around standard HttpClients to route pinned domains through a hardened zero-trust context.
class SecureHttpClientWrapper implements HttpClient {
  final HttpClient _inner;
  final HttpClient _pinnedClient;
  final Map<String, List<String>> _pinnedHosts;

  SecureHttpClientWrapper(this._inner, this._pinnedClient, this._pinnedHosts);

  HttpClient _getClientForUri(Uri uri) {
    if (_pinnedHosts.containsKey(uri.host)) {
      return _pinnedClient;
    }
    return _inner;
  }

  @override
  bool get autoUncompress => _inner.autoUncompress;
  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;

  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;
  @override
  set connectionTimeout(Duration? value) {
    _inner.connectionTimeout = value;
    _pinnedClient.connectionTimeout = value;
  }

  @override
  set idleTimeout(Duration value) {
    _inner.idleTimeout = value;
    _pinnedClient.idleTimeout = value;
  }
  @override
  Duration get idleTimeout => _inner.idleTimeout;

  @override
  set connectionFactory(Future<ConnectionTask<Socket>> Function(Uri url, String? proxyHost, int? proxyPort)? f) {
    _inner.connectionFactory = f;
    _pinnedClient.connectionFactory = f;
  }

  @override
  set keyLog(Function(String line)? callback) {
    _inner.keyLog = callback;
    _pinnedClient.keyLog = callback;
  }

  @override
  set maxConnectionsPerHost(int? value) {
    _inner.maxConnectionsPerHost = value;
    _pinnedClient.maxConnectionsPerHost = value;
  }
  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;

  @override
  set userAgent(String? value) {
    _inner.userAgent = value;
    _pinnedClient.userAgent = value;
  }
  @override
  String? get userAgent => _inner.userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {
    _getClientForUri(url).addCredentials(url, realm, credentials);
  }

  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {
    _inner.addProxyCredentials(host, port, realm, credentials);
    _pinnedClient.addProxyCredentials(host, port, realm, credentials);
  }

  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) {
    _inner.badCertificateCallback = callback;
  }

  @override
  set findProxy(String Function(Uri url)? f) {
    _inner.findProxy = f;
    _pinnedClient.findProxy = f;
  }

  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) {
    _inner.authenticate = f;
    _pinnedClient.authenticate = f;
  }

  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) {
    _inner.authenticateProxy = f;
    _pinnedClient.authenticateProxy = f;
  }

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) {
    if (_pinnedHosts.containsKey(host)) {
      return _pinnedClient.open(method, host, port, path);
    }
    return _inner.open(method, host, port, path);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    return _getClientForUri(url).openUrl(method, url);
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) => open("GET", host, port, path);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl("GET", url);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) => open("POST", host, port, path);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl("POST", url);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) => open("PUT", host, port, path);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl("PUT", url);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) => open("DELETE", host, port, path);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl("DELETE", url);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) => open("HEAD", host, port, path);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl("HEAD", url);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) => open("PATCH", host, port, path);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl("PATCH", url);

  @override
  void close({bool force = false}) {
    _inner.close(force: force);
    _pinnedClient.close(force: force);
  }
}
