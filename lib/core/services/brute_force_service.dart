import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// [BruteForceService] — The Zenith Guard Protector.
/// 
/// Tracks failed login attempts and manages lockout durations.
/// Uses Hive for persistence to prevent reset on app restart.
class BruteForceService {
  static const String _boxName = 'brute_force_vault';
  static const String _keyAttempts = 'failed_attempts';
  static const String _keyLockout = 'lockout_until';

  static final BruteForceService _instance = BruteForceService._internal();
  factory BruteForceService() => _instance;
  BruteForceService._internal();

  late Box _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox(_boxName);
    _initialized = true;
  }

  int get failedAttempts => _box.get(_keyAttempts, defaultValue: 0);

  DateTime? get lockoutUntil {
    final timestamp = _box.get(_keyLockout);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  bool get isLockedOut {
    final lockout = lockoutUntil;
    if (lockout == null) return false;
    return DateTime.now().isBefore(lockout);
  }

  Duration get remainingLockout => lockoutUntil?.difference(DateTime.now()) ?? Duration.zero;

  /// Records a failed attempt and calculates potential lockout.
  Future<void> recordFailure() async {
    final newAttempts = failedAttempts + 1;
    await _box.put(_keyAttempts, newAttempts);

    if (newAttempts >= 4) {
      final lockoutDuration = _calculateLockout(newAttempts);
      final lockoutTime = DateTime.now().add(lockoutDuration);
      await _box.put(_keyLockout, lockoutTime.millisecondsSinceEpoch);
      debugPrint('[ZenithGuard] Account LOCKED for ${lockoutDuration.inMinutes} mins due to $newAttempts failures.');
    }
  }

  /// Resets all counters on successful login.
  Future<void> reset() async {
    await _box.put(_keyAttempts, 0);
    await _box.delete(_keyLockout);
  }

  Duration _calculateLockout(int attempts) {
    // 4th attempt: 1 min
    // 5th attempt: 5 min
    // 6th+: Exponential (10, 20, 40...)
    if (attempts == 4) return const Duration(minutes: 1);
    if (attempts == 5) return const Duration(minutes: 5);
    
    final extraAttempts = attempts - 5;
    final minutes = 5 * (2 << (extraAttempts - 1)); // 10, 20, 40...
    return Duration(minutes: minutes);
  }
}
