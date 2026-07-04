import 'package:flutter/foundation.dart';

class LogEntry {
  final DateTime timestamp;
  final String level;
  final String tag;
  final String message;
  final dynamic error;

  LogEntry(this.level, this.tag, this.message, [this.error]) : timestamp = DateTime.now();

  @override
  String toString() {
    final timeStr = "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}";
    return "[$timeStr] $level [$tag] $message${error != null ? ' | Error: $error' : ''}";
  }
}

class SecureLogger {
  static final List<LogEntry> _history = [];
  static const int maxHistory = 150;

  static void _record(String level, String tag, String message, [dynamic error, StackTrace? st]) {
    if (!kDebugMode) return;
    
    final entry = LogEntry(level, tag, message, error);
    _history.add(entry);
    if (_history.length > maxHistory) {
      _history.removeAt(0);
    }

    debugPrint(entry.toString());
    if (error != null && level == '🔴 ERROR') {
      debugPrint('   ↳ Details: $error');
    }
    if (st != null) {
      debugPrint('   ↳ StackTrace: $st');
    }
  }

  /// Generic informational logs
  static void info(String message, {String tag = 'App'}) => _record('🟢 INFO', tag, message);

  /// Network requests, responses, and API interactions
  static void network(String message, {String tag = 'Network'}) => _record('🌐 NET ', tag, message);

  /// Database, cache, and local storage operations
  static void storage(String message, {String tag = 'Storage'}) => _record('🗄️ DATA', tag, message);

  /// Security and integrity shield evaluations
  static void security(String message, {String tag = 'Security'}) => _record('🛡️ SEC ', tag, message);

  /// Potential issues or degradations
  static void warning(String message, {String tag = 'Warning'}) => _record('🟡 WARN', tag, message);

  /// Critical errors or failures
  static void error(String message, [dynamic error, StackTrace? stackTrace, String tag = 'Error']) {
    _record('🔴 ERROR', tag, message, error, stackTrace);
  }

  /// Sensitive data debugging (Never output in release mode)
  static void sensitive(String tag, String data) {
    if (kDebugMode) {
      debugPrint('🔐 [SENSITIVE] [$tag]: $data');
    }
  }

  /// Retrieve recent logs for diagnostic UI tools
  static List<LogEntry> get history => List.unmodifiable(_history);
  
  static void clearHistory() => _history.clear();
}
