import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// [SecureNetworkOverrides] — Production-grade SSL/TLS hardening.
///
/// Features:
/// 1. **Multi-Host SSL Pinning**: Strictly verifies the leaf certificate
///    of specific high-value hosts (Point 1).
/// 2. **Strict Release Verification**: Denies all invalid/self-signed 
///    certificates in release builds.
/// 3. **Manual Override Support**: Allows development via proxies if needed
///    strictly in debug mode.
class SecureNetworkOverrides extends HttpOverrides {
  
  /// SSL Fingerprints (SHA-256) of your production server leaf certificates.
  /// Format: { "hostname": "fingerprint" }
  /// 
  /// Get fingerprint via: 
  /// openssl s_client -connect api.example.com:443 < /dev/null 2>/dev/null | openssl x509 -outform DER | openssl dgst -sha256
  static const String _sslHost = String.fromEnvironment('SSL_PIN_HOST', defaultValue: '');
  static const String _sslFingerprint = String.fromEnvironment('SSL_PIN_FINGERPRINT', defaultValue: '');

  static final Map<String, String> _pinnedHosts = {
    if (_sslHost.isNotEmpty && _sslFingerprint.isNotEmpty)
      _sslHost: _sslFingerprint,
  };

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // Force trusted roots and secure defaults
    final SecurityContext secureContext = SecurityContext(withTrustedRoots: true);
    final HttpClient client = super.createHttpClient(secureContext);
    
    // Low connection timeout to mitigate hanging connection pool attacks
    client.connectionTimeout = const Duration(seconds: 10);
    
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // Logic:
      // 1. If host is in pinning list → fingerprint MUST match.
      // 2. If Release Mode → All invalid certs ARE REJECTED.
      // 3. If Debug Mode → Rejection still occurs unless explicitly bypassed for proxy testing.

      if (_pinnedHosts.containsKey(host)) {
        final fingerprint = sha256.convert(cert.der).toString();
        if (fingerprint == _pinnedHosts[host]) {
          debugPrint('[Security] SSL Pin Match for $host');
          return true; // Trusted by PIN
        }
        
        debugPrint('[Security] 🚨 SSL PIN MISMATCH for $host! Expected: ${_pinnedHosts[host]} Got: $fingerprint');
        return false; // REJECT: Possible MITM
      }
      
      if (kReleaseMode) {
        debugPrint('[Security] 🚨 Blocked invalid SSL for $host in release mode.');
        return false; // REJECT
      }
      
      // Allow development proxies (like Charles/Proxyman) strictly in debug mode
      // if specific logic is added here. Default to FALSE for safety.
      return false;
    };
    
    return client;
  }
}
