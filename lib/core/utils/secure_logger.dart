import 'package:flutter/foundation.dart';

class LogEntry {
  final DateTime timestamp;
  final String level;
  final String tag;
  final String message;
  final Object? error;
  final bool isBackground;

  LogEntry(
    this.level,
    this.tag,
    this.message, [
    this.error,
    this.isBackground = false,
  ]) : timestamp = DateTime.now();

  @override
  String toString() {
    final time = timestamp.toIso8601String();
    final context = isBackground ? 'BG' : 'FG';
    return '[$time] [$context] $level [$tag] $message'
        '${error == null ? '' : ' | Error: $error'}';
  }
}

class SecureLogger {
  static const String _errorLevel = 'ERROR';
  static final List<LogEntry> _history = [];
  static const int maxHistory = 200;

  static final RegExp _emailPattern = RegExp(
    r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
    caseSensitive: false,
  );
  static final RegExp _phonePattern = RegExp(r'(?<!\w)\+?\d[\d\s().-]{7,}\d');
  static final RegExp _bearerPattern = RegExp(
    r'\bBearer\s+[A-Za-z0-9._~+/=-]+',
    caseSensitive: false,
  );
  static final RegExp _secretPattern = RegExp(
    r'\b(api[_-]?key|token|password|secret|authorization|receipt|signature)\b\s*[:=]\s*[^\s,;]+',
    caseSensitive: false,
  );
  static final RegExp _jwtPattern = RegExp(
    r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b',
  );
  static final RegExp _urlQueryPattern = RegExp(
    r'(https?://[^\s?#]+)[?#][^\s]*',
    caseSensitive: false,
  );
  static final RegExp _coordinatePattern = RegExp(
    r'(?<!\d)-?\d{1,3}\.\d{4,}\s*[,/]\s*-?\d{1,3}\.\d{4,}(?!\d)',
  );
  static final RegExp _windowsPathPattern = RegExp(
    r'\b[A-Za-z]:\\(?:[^\s\\]+\\)*[^\s\\]+',
  );

  static String redact(String value) {
    return value
        .replaceAll(_bearerPattern, 'Bearer [REDACTED]')
        .replaceAllMapped(
          _secretPattern,
          (match) => '${match.group(1)}=[REDACTED]',
        )
        .replaceAll(_jwtPattern, '[REDACTED_TOKEN]')
        .replaceAllMapped(
          _urlQueryPattern,
          (match) => '${match.group(1)}?[REDACTED]',
        )
        .replaceAll(_emailPattern, '[REDACTED_EMAIL]')
        .replaceAll(_coordinatePattern, '[REDACTED_LOCATION]')
        .replaceAll(_phonePattern, '[REDACTED_PHONE]')
        .replaceAll(_windowsPathPattern, '[REDACTED_PATH]');
  }

  static String errorType(Object error) => error.runtimeType.toString();

  static StackTrace sanitizedStackTrace(StackTrace? stackTrace) {
    if (stackTrace == null) return StackTrace.empty;
    return StackTrace.fromString(redact(stackTrace.toString()));
  }

  static void _record(
    String level,
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
    bool isBackground = false,
  ]) {
    if (kReleaseMode && level != _errorLevel) return;

    final safeMessage = redact(message);
    final safeError = error == null
        ? null
        : kReleaseMode
            ? errorType(error)
            : redact(error.toString());
    final entry = LogEntry(level, tag, safeMessage, safeError, isBackground);
    _history.add(entry);
    if (_history.length > maxHistory) _history.removeAt(0);

    debugPrint(entry.toString());
    if (!kReleaseMode && stackTrace != null) {
      debugPrint(redact(stackTrace.toString()));
    }
  }

  static void info(String message,
          {String tag = 'App', bool isBackground = false}) =>
      _record('INFO', tag, message, null, null, isBackground);

  static void uiEvent(String message, {String tag = 'UI'}) =>
      _record('UI-EVENT', tag, message);

  static void bgTask(String message, {String tag = 'Background'}) =>
      _record('BG-TASK', tag, message, null, null, true);

  static void lifecycle(String message,
          {String tag = 'Lifecycle', bool isBackground = false}) =>
      _record('LIFECYCLE', tag, message, null, null, isBackground);

  static void milestone(String title,
      {String tag = 'Milestone', bool isBackground = false}) {
    if (!kDebugMode) return;
    _record('MILESTONE', tag, title, null, null, isBackground);
  }

  static void network(String message,
          {String tag = 'Network', bool isBackground = false}) =>
      _record('NETWORK', tag, message, null, null, isBackground);

  static void storage(String message,
          {String tag = 'Storage', bool isBackground = false}) =>
      _record('STORAGE', tag, message, null, null, isBackground);

  static void security(String message,
          {String tag = 'Security', bool isBackground = false}) =>
      _record('SECURITY', tag, message, null, null, isBackground);

  static void warning(String message,
          {String tag = 'Warning', bool isBackground = false}) =>
      _record('WARNING', tag, message, null, null, isBackground);

  static void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    String tag = 'Error',
    bool isBackground = false,
  ]) {
    _record(_errorLevel, tag, message, error, stackTrace, isBackground);
  }

  static void sensitive(String tag, String data) {
    if (kDebugMode) debugPrint('[SENSITIVE] [$tag]: ${redact(data)}');
  }

  static List<LogEntry> get history => List.unmodifiable(_history);

  static void clearHistory() => _history.clear();
}
