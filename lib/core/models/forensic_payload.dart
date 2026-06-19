import 'package:flutter/foundation.dart';

/// [SecuritySeverity] — Refined severity levels for forensic events.
enum SecuritySeverity { low, medium, high, critical }

/// [ForensicPayload] — Structured context for security auditing.
/// 
/// Captures the complete state of the app/device at the moment an anomaly is detected.
class ForensicPayload {
  final String eventCode;
  final SecuritySeverity severity;
  final String uid;
  final String? deviceHash;
  final String? hashedIp; // Salted/Hashed IP (Point 13 recommendation)
  final int integrityScore;
  final List<String> integritySignals;
  final String appVersion;
  final String? packageSignature;
  final Map<String, dynamic> details;
  final List<String> impossiblePatterns;
  final DateTime timestamp;

  ForensicPayload({
    required this.eventCode,
    required this.severity,
    required this.uid,
    this.deviceHash,
    this.hashedIp,
    required this.integrityScore,
    required this.integritySignals,
    required this.appVersion,
    this.packageSignature,
    this.details = const {},
    this.impossiblePatterns = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'eventCode': eventCode,
    'severity': severity.name,
    'uid': uid,
    'deviceHash': deviceHash,
    'hashedIp': hashedIp,
    'integrityScore': integrityScore,
    'integritySignals': integritySignals,
    'appVersion': appVersion,
    'packageSignature': packageSignature,
    'details': details,
    'impossiblePatterns': impossiblePatterns,
    'createdAt': timestamp.toIso8601String(),
    'isWeb': kIsWeb,
  };
}
