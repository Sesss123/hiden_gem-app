import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Future<void> init() async {
    await _tts.setLanguage("en-US");
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    
    _tts.setCompletionHandler(() {
      _isPlaying = false;
    });

    _tts.setErrorHandler((message) {
      _isPlaying = false;
    });

    _tts.setCancelHandler(() {
      _isPlaying = false;
    });
  }

  Future<void> speak(String text, {String languageCode = 'en-US'}) async {
    if (text.isEmpty) return;
    
    // Map app language codes to TTS language codes
    String ttsLang = "en-US";
    switch (languageCode) {
      case 'si': ttsLang = "si-LK"; break;
      case 'ta': ttsLang = "ta-LK"; break; 
      case 'ja': ttsLang = "ja-JP"; break;
      case 'ru': ttsLang = "ru-RU"; break;
      case 'ko': ttsLang = "ko-KR"; break;
      default: ttsLang = "en-US";
    }

    // Query device support for the language, default to en-US if missing
    bool isSupported = false;
    try {
      isSupported = await _tts.isLanguageAvailable(ttsLang);
    } catch (_) {}

    if (!isSupported) {
      ttsLang = "en-US";
    }

    await _tts.setLanguage(ttsLang);
    _isPlaying = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
  }
}
