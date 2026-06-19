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

  /// Disposes the debouncer — call in widget dispose().
  void dispose() {
    _timer?.cancel();
  }
}

/// [RequestGuard] — Manages cancelable async requests.
/// 
/// When a new request is fired, the previous one is automatically abandoned.
/// This prevents race conditions and wasted Firestore reads.
/// 
/// Example:
/// ```dart
/// final _guard = RequestGuard<List<GuideListing>>();
/// 
/// void onSearch(String query) {
///   _guard.execute(() => _repository.searchMarketplace(query: query));
/// }
/// ```
class RequestGuard<T> {
  Completer<T>? _activeCompleter;

  Future<T?> execute(Future<T> Function() request) async {
    // Cancel any in-flight request by abandoning its completer
    _activeCompleter = Completer<T>();
    final myCompleter = _activeCompleter!;

    try {
      final result = await request();
      // Only deliver result if this is still the active request
      if (myCompleter == _activeCompleter) {
        if (!myCompleter.isCompleted) myCompleter.complete(result);
        return result;
      }
      return null; // Abandoned — a newer request is active
    } catch (e) {
      if (myCompleter == _activeCompleter && !myCompleter.isCompleted) {
        myCompleter.completeError(e);
      }
      return null;
    }
  }

  void cancel() {
    _activeCompleter = null;
  }
}
