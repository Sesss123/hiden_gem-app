import 'dart:convert';
import '../../core/config/app_config.dart';
import '../../core/utils/secure_logger.dart';
import 'package:http/http.dart' as http;
import '../../core/network/secure_http_client.dart';
import 'voice_assistant_service.dart';

class TranslationService {
  static String get _apiKey => AppConfig.hiddenGemsApiKey;
  static String get _baseUrl => AppConfig.baseUrl;
  static final _client = SecureHttpClient(http.Client());

  /// Translates text and speaks it out in the target language
  static Future<void> translateAndSpeak(String text, String targetLang) async {
    try {
      final translatedText = await translate(text, targetLang);
      await VoiceAssistantService.speakAdvanced(translatedText, accent: targetLang == 'si' ? 'lk_sinhala' : 'en_us');
    } catch (e) {
      SecureLogger.error('TranslationService Error: $e');
    }
  }

  /// General purpose translation tool using the AI Forge bridge.
  static Future<String> translate(String text, String targetLang) async {
    if (text.isEmpty || targetLang == 'en') return text;

    try {
      final url = Uri.parse("$_baseUrl/ai/translate");
      
      final response = await _client.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "X-HiddenGems-Key": _apiKey,
        },
        body: json.encode({
          "text": text,
          "target_lang": targetLang,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['translated_text'] ?? text;
      }
      
      return _getSemanticFallback(text, targetLang);
    } catch (e) {
      SecureLogger.error('AI Translation Bridge failed: $e');
      return _getSemanticFallback(text, targetLang);
    }
  }

  static String _getSemanticFallback(String text, String lang) {
    if (lang != 'si') return text;
    
    final lower = text.toLowerCase();
    if (lower.contains("how much") || lower.contains("price")) return "මෙය කොපමණ වේද?";
    if (lower.contains("thank you")) return "ස්තූතියි";
    if (lower.contains("hello") || lower.contains("hi")) return "ආයුබෝවන්";
    if (lower.contains("waterfall")) return "දියඇල්ල";
    if (lower.contains("temple")) return "විහාරය";
    
    return text;
  }
}
