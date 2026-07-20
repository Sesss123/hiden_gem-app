import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/utils/secure_logger.dart';

class ARSupportService {
  /// ar_flutter_plugin_2 has no static "is ARCore installed" check — it
  /// only supports Android/iOS and fails at session-creation time (surfaced
  /// via ARSessionManager.onError) if the device genuinely lacks ARCore.
  /// This is a platform-level gate only; a device claiming Android+minSdk
  /// support but missing ARCore itself is caught later by that onError path.
  static Future<bool> isARCoreSupported() async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }
    try {
      return true;
    } catch (e) {
      SecureLogger.error("ARCore Availability Check Failed: $e");
      return false;
    }
  }

  static void showCinematicARError(dynamic context) {
    // This will be implemented as a premium glassmorphic dialog
    // calling a standard helper in the UI layer.
  }
}
