// lumen_ai_service.dart
// Lumen-1 Local AI Model Integration for Hidden Gems SL
// Connects to the Lumen-1 FastAPI server running on the local machine.
// Android Emulator: http://10.0.2.2:8000
// Physical Device (USB/WiFi): http://<PC-LOCAL-IP>:8000

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/secure_logger.dart';

/// Lumen-1 AI Modes (matches dashboard modes)
enum LumenMode {
  defaultMode, // Travel guide assistant
  analyst,     // Data analysis
  optimizer,   // Hyperparameter optimization
  refactor,    // Code review
  database,    // JSON database queries
  security,    // Safety profiling
}

extension LumenModeExtension on LumenMode {
  String get value {
    switch (this) {
      case LumenMode.defaultMode: return 'default';
      case LumenMode.analyst:    return 'analyst';
      case LumenMode.optimizer:  return 'optimizer';
      case LumenMode.refactor:   return 'refactor';
      case LumenMode.database:   return 'database';
      case LumenMode.security:   return 'security';
    }
  }
}

class LumenAiService {
  // ── Configuration ──────────────────────────────────────────

  /// Base URL for Lumen-1 dashboard server.
  /// Android Emulator uses 10.0.2.2 to reach host PC's localhost.
  /// Physical device: change this to your PC's local network IP.
  static String get _baseUrl {
    if (kDebugMode) {
      // Android emulator: 10.0.2.2 → host PC localhost
      return 'http://10.0.2.2:8000';
    }
    return 'http://10.0.2.2:8000';
  }

  /// Lumen-1 API key (set in LUMEN_API_KEY env var on server,
  /// default: 'lumen_default_secure_api_key_2026')
  static const String _apiKey = 'lumen_default_secure_api_key_2026';

  /// Default timeout for inference calls
  static const Duration _timeout = Duration(seconds: 60);

  // ── Core Inference Method ──────────────────────────────────

  /// Send a prompt to Lumen-1 and get a response.
  ///
  /// [prompt]       - The user's input text
  /// [mode]         - AI mode to use (default: travel guide)
  /// [useRag]       - Enable RAG (Retrieval-Augmented Generation) for facts
  /// [systemPrompt] - Optional custom system prompt override
  /// [temperature]  - Creativity level 0.0–1.0 (default: 0.7)
  static Future<String> chat({
    required String prompt,
    LumenMode mode = LumenMode.defaultMode,
    bool useRag = true,
    String systemPrompt = '',
    double temperature = 0.7,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/test-model');

    final body = json.encode({
      'prompt': prompt,
      'use_rag': useRag,
      'mode': mode.value,
      'system_prompt': systemPrompt,
      'temperature': temperature,
    });

    try {
      SecureLogger.info('[Lumen] Sending prompt: ${prompt.substring(0, prompt.length.clamp(0, 50))}...');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: body,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final reply = data['response'] as String? ?? '';
        SecureLogger.info('[Lumen] Got reply (${reply.length} chars)');
        return reply.trim();
      } else if (response.statusCode == 429) {
        SecureLogger.warning('[Lumen] Rate limited');
        throw LumenException('Rate limit reached. Please wait a moment.');
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        throw LumenException('Safety check: ${data['detail'] ?? 'Invalid request'}');
      } else if (response.statusCode == 401) {
        SecureLogger.error('[Lumen] Unauthorized — check API key');
        throw LumenException('Authorization failed. Check Lumen-1 API key.');
      } else {
        SecureLogger.error('[Lumen] HTTP ${response.statusCode}');
        throw LumenException('Lumen-1 server error (${response.statusCode}).');
      }
    } on LumenException {
      rethrow;
    } catch (e) {
      SecureLogger.error('[Lumen] Connection error: $e');
      throw LumenException(
        'Cannot connect to Lumen-1. Make sure:\n'
        '• python dashboard/app.py is running\n'
        '• PC and phone are on same network\n'
        'Error: $e',
      );
    }
  }

  // ── Convenience Methods ────────────────────────────────────

  /// Oracle travel assistant query (used by Voice Oracle & chat)
  static Future<String> askOracle({
    required String query,
    String? locationContext,
  }) async {
    final prompt = locationContext != null
        ? '$query\n\nUser Location: $locationContext'
        : query;

    return chat(
      prompt: prompt,
      mode: LumenMode.defaultMode,
      useRag: true,
      temperature: 0.7,
    );
  }

  /// Generate a trip plan using Lumen-1
  static Future<String> generateTripPlan({
    required String destination,
    required int days,
    required String groupType,
    required String budget,
    List<String> interests = const [],
  }) async {
    final prompt = '''
Plan a $days-day trip to $destination, Sri Lanka for $groupType.
Budget: $budget
Interests: ${interests.join(', ')}

Please provide:
1. Day-by-day itinerary
2. Best places to visit
3. Local food recommendations
4. Travel tips
5. Estimated costs
''';

    return chat(
      prompt: prompt,
      mode: LumenMode.defaultMode,
      useRag: true,
      temperature: 0.6,
    );
  }

  /// Check if Lumen-1 server is reachable
  static Future<bool> isServerAlive() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/status'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

/// Custom exception for Lumen-1 errors
class LumenException implements Exception {
  final String message;
  const LumenException(this.message);

  @override
  String toString() => 'LumenException: $message';
}
