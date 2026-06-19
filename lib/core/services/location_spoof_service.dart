import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// 📍 LocationSpoofService — Layer 4 Anti-Hack Security
///
/// Detects two types of GPS spoofing:
///   A) position.isMocked == true  (mock GPS apps detected by Android)
///   B) Physically impossible speed > [_maxSpeedKmh] km/h between pings
///
/// On detection → calls Cloud Function [detectLocationSpoof] to flag the user
/// server-side. After 3+ detections, their account is flagged and AR is blocked.
class LocationSpoofService {
  // Maximum realistic travel speed (helicopter ~300 km/h, using 200 to be safe)
  static const double _maxSpeedKmh = 200.0;

  // Minimum time gap between pings to avoid false positives on first ping
  static const Duration _minPingGap = Duration(seconds: 5);

  // Last recorded position + timestamp
  static Position? _lastPosition;
  static DateTime? _lastPingTime;

  // Cached flag status — refreshed from Firestore on each app open
  static bool _userIsFlagged = false;

  /// Initialize the service — call once at app startup.
  /// Loads the user's current flag status from Firestore.
  static Future<void> initialize(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      _userIsFlagged = doc.data()?['isFlagged'] ?? false;
      debugPrint('[LocationSpoof] Init: isFlagged=$_userIsFlagged');
    } catch (e) {
      debugPrint('[LocationSpoof] Init failed: $e');
    }
  }

  /// Returns true if the user's account is currently flagged for spoofing.
  static bool get isUserFlagged => _userIsFlagged;

  /// Record a new GPS position ping and run spoof checks.
  ///
  /// Returns [SpoofResult] with whether spoofing was detected and why.
  /// Call this every time a new GPS position is received.
  static Future<SpoofResult> recordPing(Position position) async {
    // ── Check A: isMocked flag (Android mock GPS detection) ──────────────────
    if (position.isMocked) {
      debugPrint('[LocationSpoof] 🚨 Mock location detected!');
      await _reportSpoof(
        reason: 'mock_location_app',
        lat: position.latitude,
        lng: position.longitude,
      );
      return SpoofResult(
        detected: true,
        reason: SpoofReason.mockLocationApp,
        message: 'Mock GPS detected. AR sessions blocked.',
      );
    }

    final now = DateTime.now();

    // ── Check B: Speed-based spoof detection ─────────────────────────────────
    if (_lastPosition != null && _lastPingTime != null) {
      final timeDiff = now.difference(_lastPingTime!);

      // Only check if enough time has passed to avoid false positives
      if (timeDiff >= _minPingGap) {
        final distanceM = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        final speedKmh = (distanceM / timeDiff.inSeconds) * 3.6;

        if (speedKmh > _maxSpeedKmh) {
          debugPrint('[LocationSpoof] 🚨 Impossible speed: ${speedKmh.toStringAsFixed(1)} km/h');
          await _reportSpoof(
            reason: 'impossible_speed',
            detectedSpeed: speedKmh,
            lat: position.latitude,
            lng: position.longitude,
          );

          // Update last position regardless to avoid cascading false positives
          _lastPosition = position;
          _lastPingTime = now;

          return SpoofResult(
            detected: true,
            reason: SpoofReason.impossibleSpeed,
            detectedSpeedKmh: speedKmh,
            message: 'Impossible movement speed detected. AR sessions blocked.',
          );
        }
      }
    }

    // ── No spoof detected — update last known position ────────────────────────
    _lastPosition = position;
    _lastPingTime = now;

    return SpoofResult(detected: false);
  }

  /// Report a spoof detection to the Cloud Function.
  /// Cloud Function will flag the user after 3+ reports.
  static Future<void> _reportSpoof({
    required String reason,
    double? detectedSpeed,
    required double lat,
    required double lng,
  }) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('detectLocationSpoof')
          .call({
        'reason': reason,
        'detectedSpeed': detectedSpeed,
        'lat': lat,
        'lng': lng,
      });

      final data = result.data as Map<String, dynamic>;
      _userIsFlagged = data['flagged'] ?? false;

      debugPrint('[LocationSpoof] Reported. flagged=$_userIsFlagged, count=${data['spoofCount']}');
    } catch (e) {
      debugPrint('[LocationSpoof] Report failed: $e');
    }
  }

  /// Reset state — call on user sign-out.
  static void reset() {
    _lastPosition = null;
    _lastPingTime = null;
    _userIsFlagged = false;
  }
}

// ─── Result Model ─────────────────────────────────────────────────────────────

enum SpoofReason { mockLocationApp, impossibleSpeed }

class SpoofResult {
  final bool detected;
  final SpoofReason? reason;
  final double? detectedSpeedKmh;
  final String? message;

  const SpoofResult({
    required this.detected,
    this.reason,
    this.detectedSpeedKmh,
    this.message,
  });

  @override
  String toString() => 'SpoofResult(detected=$detected, reason=$reason, speed=$detectedSpeedKmh km/h)';
}
