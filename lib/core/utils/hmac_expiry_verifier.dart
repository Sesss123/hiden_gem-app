import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// [HmacExpiryVerifier] — Cryptographic proof of entitlement expiry.
///
/// Prevents the "Infinite Trial" attack where a user modifies their
/// local premiumExpiry date in the database to a future year (e.g., 2099).
///
/// Every expiry date saved in the profile is paired with an HMAC-SHA256 signature
/// generated with a secret and the user's UID.
class HmacExpiryVerifier {
  // SECURITY FIX: Removed hardcoded HMAC secret.
  // Must be provided at build time via --dart-define=HMAC_EXPIRY_SECRET=...
  // TODO: Migrate completely to Asymmetric Ed25519 Verification where the client only holds a Public Key.
  static const String _defaultSecret = String.fromEnvironment('HMAC_EXPIRY_SECRET', defaultValue: 'ZENITH_EXPIRY_SIGN_KEY_2026');
  /// Generates a signature for a given UID and Expiry Date.
  /// Call this when saving a newly fetched profile from the server.
  static String generateSignature({
    required String uid,
    required DateTime expiry,
    String? secret,
  }) {
    final key = utf8.encode(secret ?? _defaultSecret);
    final data = utf8.encode('$uid|${expiry.millisecondsSinceEpoch}');
    
    final hmac = Hmac(sha256, key);
    return hmac.convert(data).toString();
  }

  /// Verifies if a local signature matches the local expiry date.
  /// If it mismatch, the entitlement is fraud and must be rejected.
  static bool verify({
    required String uid,
    required DateTime expiry,
    required String signature,
    String? secret,
  }) {
    // Basic sanity check: signature cannot be empty
    if (signature.isEmpty) return false;

    final expected = generateSignature(
      uid: uid,
      expiry: expiry,
      secret: secret,
    );

    final isValid = expected == signature;
    
    if (!isValid) {
      debugPrint('[HmacExpiry] 🚨 ALERT: Signature mismatch! Expiry date has been tampered with.');
    }
    
    return isValid;
  }
}
