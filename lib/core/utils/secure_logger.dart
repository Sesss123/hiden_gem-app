import 'package:flutter/foundation.dart';

class SecureLogger {
  /// Use this for generic non-sensitive debugging information
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  /// Use this for errors that might be helpful during development, 
  /// but should be hidden in production unless specifically integrated 
  /// with a secure crash reporting tool like Crashlytics.
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint(error.toString());
      if (stackTrace != null) debugPrint(stackTrace.toString());
    }
  }

  /// Use this for warnings that indicate potential issues.
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('[WARNING] $message');
    }
  }

  /// Use this for sensitive operations (Tokens, HTTP payloads, User Data).
  /// It only logs in strict debug mode and warns the developer.
  static void sensitive(String tag, String data) {
    if (kDebugMode) {
      debugPrint('[SENSITIVE] $tag: $data');
      debugPrint('WARNING: Ensure this log is not pushed to production!');
    }
  }
}
