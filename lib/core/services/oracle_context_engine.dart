import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/utils/secure_logger.dart';

enum UserEnergyLevel { low, medium, high }

class OracleContextEngine {
  static const _storage = FlutterSecureStorage();
  static const _contextKey = 'oracle_user_context';

  static Future<Map<String, dynamic>> getFullContext(String currentQuery) async {
    final stored = await _storage.read(key: _contextKey);
    Map<String, dynamic> context = stored != null ? json.decode(stored) : {};

    // Detect mood/energy from current query (Simplified NLP)
    final energy = _detectEnergy(currentQuery);
    if (energy != null) {
      context['energy_level'] = energy.name;
    }

    return {
      'energy_level': context['energy_level'] ?? 'medium',
      'last_mood': context['last_mood'] ?? 'neutral',
      'query_sentiment': _analyzeSentiment(currentQuery),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  static UserEnergyLevel? _detectEnergy(String query) {
    final q = query.toLowerCase();
    if (q.contains('tired') || q.contains('exhausted') || q.contains('low energy') || q.contains('lazy')) {
      return UserEnergyLevel.low;
    }
    if (q.contains('excited') || q.contains('energetic') || q.contains('hiking') || q.contains('fast')) {
      return UserEnergyLevel.high;
    }
    return null;
  }

  static String _analyzeSentiment(String query) {
    final q = query.toLowerCase();
    if (q.contains('love') || q.contains('great') || q.contains('amazing') || q.contains('happy')) {
      return 'positive';
    }
    if (q.contains('hate') || q.contains('bad') || q.contains('annoying') || q.contains('boring')) {
      return 'negative';
    }
    return 'neutral';
  }

  static Future<void> updateContext(Map<String, dynamic> newContext) async {
    try {
      final existing = await _storage.read(key: _contextKey);
      Map<String, dynamic> data = existing != null ? json.decode(existing) : {};
      data.addAll(newContext);
      await _storage.write(key: _contextKey, value: json.encode(data));
    } catch (e) {
      SecureLogger.error('OracleContextEngine Error: $e');
    }
  }
}
