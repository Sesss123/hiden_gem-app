import 'dart:async';
import 'package:flutter/foundation.dart';

/// [Debouncer] — Limits the frequency of high-cost operations.
/// 
/// Use this for search fields, filter changes, or any rapid UI event 
/// that triggers Firestore queries.
/// 
/// Example:
/// ```dart
/// final _debouncer = Debouncer(milliseconds: 500);
/// 
/// void onSearchChanged(String query) {
///   if (query.length < 2) return; // Minimum 2-char threshold
///   _debouncer.run(() => _search(query));
/// }
/// ```
class Debouncer {
  final int milliseconds;
  VoidCallback? _lastAction;
  Timer? _timer;

  Debouncer({this.milliseconds = 500});

  void run(VoidCallback action) {
    _lastAction = action;
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), () {
      _lastAction?.call();
      _lastAction = null;
    });
  }

  /// Immediately cancels any pending action.
  void cancel() {
    _timer?.cancel();
    _lastAction = null;
  }

  /// If an action is currently pending (scheduled but not yet fired), runs
  /// it immediately and cancels the timer. No-op if nothing is pending.
  /// Use this to flush a debounced call on app pause/dispose instead of
  /// silently losing it when the timer never gets to fire.
  void flush() {
    if (_timer == null || !_timer!.isActive) return;
    _timer!.cancel();
    final action = _lastAction;
    _lastAction = null;
    action?.call();
  }

  /// Disposes the debouncer — call in widget dispose().
  void dispose() {
    _timer?.cancel();
  }
}
