import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import '../../core/utils/secure_logger.dart';

class ARSupportService {
  static Future<bool> isARCoreSupported() async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }
    try {
      final bool isInstalled = await ArCoreController.checkArCoreAvailability();
      final bool isSupported = await ArCoreController.checkIsArCoreInstalled();
      
      SecureLogger.info("ARCore Check: Installed=$isInstalled, Supported=$isSupported");
      return isInstalled && isSupported;
    } catch (e) {
      SecureLogger.error("ARCore Availability Check Failed", e);
      return false;
    }
  }

  static void showCinematicARError(dynamic context) {
    // This will be implemented as a premium glassmorphic dialog
    // calling a standard helper in the UI layer.
  }
}
