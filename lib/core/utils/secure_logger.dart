import 'package:flutter/foundation.dart';

class LogEntry {
  final DateTime timestamp;
  final String level;
  final String tag;
  final String message;
  final dynamic error;
  final bool isBackground;

  LogEntry(this.level, this.tag, this.message, [this.error, this.isBackground = false]) : timestamp = DateTime.now();

  @override
  String toString() {
    final timeStr = "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}";
    final typeAligned = level.padRight(12);
    final tagAligned = tag.length > 15 ? tag.substring(0, 15) : tag.padRight(15);
    final bgTag = isBackground ? "[⚙️ BG]" : "[📱 FG]";
    return "[$timeStr] $bgTag $typeAligned [$tagAligned] 💬 $message${error != null ? ' | Error: $error' : ''}";
  }
}

class SecureLogger {
  static final List<LogEntry> _history = [];
  static const int maxHistory = 200;

  static void _record(String level, String tag, String message, [dynamic error, StackTrace? st, bool isBackground = false]) {
    if (!kDebugMode) return;
    
    final entry = LogEntry(level, tag, message, error, isBackground);
    _history.add(entry);
    if (_history.length > maxHistory) {
      _history.removeAt(0);
    }

    if (level == '🔴 ERROR') {
      debugPrint('╔══════════════════════════════════════════════════════════════════════════════');
      debugPrint('║ $level [${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}.${entry.timestamp.millisecond.toString().padLeft(3, '0')}] ${isBackground ? "[⚙️ BG]" : "[📱 FG]"} Tag: [$tag]');
      debugPrint('║ 💬 Message: $message');
      if (error != null) debugPrint('║ ❌ Error Details: $error');
      if (st != null)    debugPrint('║ 📚 StackTrace:\n$st');
      debugPrint('╚══════════════════════════════════════════════════════════════════════════════');
    } else {
      debugPrint(entry.toString());
      if (error != null && level != '🔴 ERROR') {
        debugPrint('   ↳ Details: $error');
      }
      if (st != null && level != '🔴 ERROR') {
        debugPrint('   ↳ StackTrace: $st');
      }
    }
  }

  /// Generic informational logs
  static void info(String message, {String tag = 'App', bool isBackground = false}) => _record('🟢 INFO', tag, message, null, null, isBackground);

  /// Foreground UI interactions, screen transitions, and user actions
  static void uiEvent(String message, {String tag = 'UI'}) => _record('📱 UI-EVENT', tag, message, null, null, false);

  /// Background jobs, timer syncs, silent data updates, and background AI processing
  static void bgTask(String message, {String tag = 'Background'}) => _record('⚙️ BG-TASK', tag, message, null, null, true);

  /// App lifecycle transitions (initState, resumed, paused, detached)
  static void lifecycle(String message, {String tag = 'Lifecycle', bool isBackground = false}) => _record('⚡ LIFECYCLE', tag, message, null, null, isBackground);

  /// Major architectural or feature milestones (creates a visual divider in USB console)
  static void milestone(String title, {String tag = 'Milestone', bool isBackground = false}) {
    if (!kDebugMode) return;
    debugPrint('──────────────────────────────────────────────────────────────────────────────');
    _record('⭐ MILESTONE', tag, title, null, null, isBackground);
    debugPrint('──────────────────────────────────────────────────────────────────────────────');
  }

  /// Network requests, responses, and API interactions
  static void network(String message, {String tag = 'Network', bool isBackground = false}) => _record('🌐 NETWORK', tag, message, null, null, isBackground);

  /// Database, cache, and local storage operations
  static void storage(String message, {String tag = 'Storage', bool isBackground = false}) => _record('🗄️ STORAGE', tag, message, null, null, isBackground);

  /// Security and integrity shield evaluations
  static void security(String message, {String tag = 'Security', bool isBackground = false}) => _record('🛡️ SECURITY', tag, message, null, null, isBackground);

  /// Potential issues or degradations
  static void warning(String message, {String tag = 'Warning', bool isBackground = false}) => _record('🟡 WARNING', tag, message, null, null, isBackground);

  /// Critical errors or failures
  static void error(String message, [dynamic error, StackTrace? stackTrace, String tag = 'Error', bool isBackground = false]) {
    _record('🔴 ERROR', tag, message, error, stackTrace, isBackground);
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
