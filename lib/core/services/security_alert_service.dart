import 'package:cloud_functions/cloud_functions.dart';
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
  }) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('report_security_alert');
    final response = await callable.call({'code': code, 'details': details});
    final accepted = (response.data as Map?)?['accepted'] == true;

    // A trusted Cloud Function watching this document owns FCM delivery.
    // Client code must never enqueue messages to the administrator topic.
    if (severity == SecuritySeverity.high) _shouldSendHighAlert(code);
    debugPrint(
        '[SecurityAlert] Server accepted alert: $accepted; severity is server-derived.');
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
