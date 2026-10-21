import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// [ThreatReporter] — Real-time Security Notification System.
///
/// Pushes critical security events (like Spectre breaches) to
/// a dedicated collection for Admin monitoring.
class ThreatReporter {
  static final ThreatReporter _instance = ThreatReporter._internal();
  factory ThreatReporter() => _instance;
  ThreatReporter._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> reportSpectreBreach(List<String> signals) async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (_auth.currentUser == null) return;
      final callable =
          FirebaseFunctions.instance.httpsCallable('report_threat_probe');
      await callable.call({
        'signals': signals,
        'appVersion': info.version,
        'buildNumber': info.buildNumber,
      });

      debugPrint('[ThreatReporter] 🕷️ SPECTRE ALERT BROADCASTED.');
    } catch (e) {
      debugPrint('[ThreatReporter] Failed to report breach: $e');
    }
  }
}
