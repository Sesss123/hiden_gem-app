import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/forensic_payload.dart';

/// [SecurityAlertService] — Admin Notification & Incident Response Engine.
/// 
/// Escalates automated security events into actionable administrative alerts.
class SecurityAlertService {
  static final SecurityAlertService _instance = SecurityAlertService._internal();
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

    // 2. Determine Notification Escalation (Point 13 - Push Policy)
    if (severity == SecuritySeverity.critical) {
      await _sendPushNotification(
        id: docRef.id,
        title: '🔴 CRITICAL SECURITY INCIDENT',
        body: 'Immediate attention required: $code',
        severity: severity,
      );
    } else if (severity == SecuritySeverity.high) {
      if (_shouldSendHighAlert(code)) {
        await _sendPushNotification(
          id: docRef.id,
          title: '🟠 High Severity Alert',
          body: 'Pattern detected: $code',
          severity: severity,
        );
      }
    }
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

  Future<void> _sendPushNotification({
    required String id,
    required String title,
    required String body,
    required SecuritySeverity severity,
  }) async {
    try {
      // 🛡️ POINT 13 Architecture Pattern: Topic-based escalation
      // NOTE: In production, the actual HTTP send is done via Firebase Admin SDK (Node.js/Go)
      // because you cannot securely send FCM messages directly from the client.
      // We log the INTENT here, which a Cloud Function will pick up and execute.
      
      await _firestore.collection('pending_notifications').add({
        'topic': 'security-admins',
        'title': title,
        'body': body,
        'data': {
          'alertId': id,
          'severity': severity.name,
          'type': 'security_incident',
        },
        'status': 'queued',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[SecurityAlert] Escalated $severity alert to pending_notifications.');
    } catch (e) {
      debugPrint('[SecurityAlert] FCM Escalation failed: $e');
    }
  }
}
