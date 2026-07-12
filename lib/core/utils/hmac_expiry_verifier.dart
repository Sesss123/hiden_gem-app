import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// [HmacExpiryVerifier] — Cryptographic proof of entitlement expiry.
///
/// Prevents the "Infinite Trial" attack where a user modifies their
/// local premiumExpiry date in the database to a future year (e.g., 2099).
///
/// Every expiry date saved in the profile is paired with an HMAC-SHA256 signature
/// generated with a secret and the user's UID.
///
/// KNOWN LIMITATION (security audit, not fixed here — needs a deployment
/// decision, not a code change): the signature this class verifies must
/// have been generated SERVER-SIDE by functions/index.ts's
/// verify_entitlements Cloud Function (using its own HMAC_SECRET env var) —
/// generateSignature() below exists only so verify() can recompute and
/// compare, it must never be called to *produce* a signature that gets
/// trusted as if server-issued. Two consequences:
/// 1. AppConfig.hmacExpirySecret (HMAC_EXPIRY_SECRET dart-define, compiled
///    into the app binary) and the Cloud Function's HMAC_SECRET are
///    DIFFERENT env vars that must be set to the SAME real secret value for
///    this to ever validate a real server signature. As shipped, neither
///    has a real value configured anywhere in this repo (both fall back to
///    their respective placeholder defaults) — meaning verify() currently
///    fails for every real premium user, silently (secure_entitlements.dart
///    logs the mismatch but doesn't hard-block on it, since verifyPremium()
///    also independently checks the server's isPremium claim). Fix: set
///    both to the same real secret in their respective deployment configs.
/// 2. Because the secret is compiled into the app binary, it's extractable
///    via decompilation — an attacker who has it can compute a signature
///    that passes THIS client-side check on its own. This does not bypass
///    SecureEntitlements.verifyPremium() as a whole (it independently
///    re-checks the server's isPremium claim on every call), but it does
///    defeat this specific local-only defense-in-depth layer used by
///    SecurityOrchestrator's offline/cached checks. Closing this fully
///    would require never trusting a client-recomputed signature at all —
///    i.e. always hitting verify_entitlements fresh — which is a larger
///    architecture change than this audit pass, not a drop-in patch.
class HmacExpiryVerifier {
  static String get _defaultSecret => AppConfig.hmacExpirySecret;

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

    final isValid = safeEqual(expected, signature);
    
    if (!isValid) {
      debugPrint('[HmacExpiry] 🚨 ALERT: Signature mismatch! Expiry date has been tampered with.');
    }
    
    return isValid;
  }
}
