import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/forensic_payload.dart';

/// [SecurityAlertService] — Admin Notification & Incident Response Engine.
///
/// Escalates automated security events into actionable administrative alerts.
class SecurityAlertService {
  static final SecurityAlertService _instance =
      SecurityAlertService._internal();
  factory SecurityAlertService() => _instance;
  SecurityAlertService._internal();

  final _firestore = FirebaseFirestore.instance;

  // In-memory deduplication logic (Point 13 recommendation 2)
  final Map<String, DateTime> _lastAlertSent = {};
  static const Duration _highAlertCooldown = Duration(minutes: 10);

  /// Triggers a forensic alert.
  /// - [Critical]: Immediate Push to topics.
  /// - [High]: Grouped/Deduplicated Push to topics.
  /// - [Medium/Low]: Direct to Firestore only.
  Future<void> triggerAlert({
    required String code,
    required SecuritySeverity severity,
    required Map<String, dynamic> details,
    String? userId,
  }) async {
    // 1. Persist to /security_alerts
    final alertDoc = {
      'code': code,
      'severity': severity.name,
      'details': details,
      'userId': userId,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _firestore.collection('security_alerts').add(alertDoc);

    // A trusted Cloud Function watching this document owns FCM delivery.
    // Client code must never enqueue messages to the administrator topic.
    if (severity == SecuritySeverity.high) _shouldSendHighAlert(code);
    debugPrint(
        '[SecurityAlert] Recorded alert ${docRef.id}; server evaluates escalation.');
  }

  // --- Internal ---

  bool _shouldSendHighAlert(String code) {
    final now = DateTime.now();
    final lastTime = _lastAlertSent[code];

    if (lastTime == null || now.difference(lastTime) > _highAlertCooldown) {
      _lastAlertSent[code] = now;
      return true;
    }
    return false;
  }
}
