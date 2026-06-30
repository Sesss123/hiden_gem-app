import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'oracle_context_engine.dart';
import 'dynamic_itinerary_service.dart';
import 'lumen_ai_service.dart';
import '../../core/utils/secure_logger.dart';

enum OracleState { idle, listening, thinking, speaking }

class VoiceAssistantService {
  static final FlutterTts _tts = FlutterTts();
  static final stt.SpeechToText _stt = stt.SpeechToText();
  static final ValueNotifier<OracleState> state = ValueNotifier(OracleState.idle);
  
  static String _lastWords = "";

  static Future<void> init() async {
    await _tts.setLanguage("en-US"); 
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    
    _tts.setStartHandler(() => state.value = OracleState.speaking);
    _tts.setCompletionHandler(() => state.value = OracleState.idle);
  }

  static Future<void> speak(String text) async {
    state.value = OracleState.speaking;
    await _tts.speak(text);
  }

  static Future<void> stop() async {
    state.value = OracleState.idle;
    await _tts.stop();
  }

  static Future<Position?> getCurrentPosition() async {
     try {
       return await Geolocator.getCurrentPosition(
         locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
       );
     } catch (e) {
       SecureLogger.error('Oracle Position Fetch Failed: $e');
       return null;
     }
  }

  static Future<void> startListening({
    required Function(String) onResult,
    required VoidCallback onDone,
  }) async {
    // Stage 5: Robust Permission Guards
    final micStatus = await Permission.microphone.request();
    final locStatus = await Permission.location.request();

    if (micStatus.isDenied || locStatus.isDenied) {
      SecureLogger.error('Permissions Denied for Oracle');
      await speak("Traveler, I need your permission to hear and find you.");
      onDone();
      return;
    }

    bool available = false;
    try {
      available = await _stt.initialize(
        onStatus: (status) {
          SecureLogger.info('STT Status: $status');
          if (status == 'done' || status == 'notListening') onDone();
        },
        onError: (errorNotification) {
          SecureLogger.error('STT Error: ${errorNotification.errorMsg} (Permanent: ${errorNotification.permanent})');
          
          if (errorNotification.errorMsg == 'error_permission' || 
              errorNotification.errorMsg == 'not-allowed') {
            speak("Traveler, your browser has veiled your voice. Please allow microphone access in your settings.");
          } else if (errorNotification.errorMsg == 'error_no_match') {
            // Silently handle no match to avoid annoying the user
          } else {
            speak("The winds are too loud, I cannot hear you clearly.");
          }
          onDone();
        },
      );
    } catch (e) {
      SecureLogger.error('STT Initialization Exception: $e');
      available = false;
    }

    if (available) {
      state.value = OracleState.listening;
      _stt.listen(
        onResult: (result) async {
          _lastWords = result.recognizedWords;
          onResult(_lastWords);
          
          if (result.finalResult) {
            state.value = OracleState.thinking;
            await processCommand(_lastWords);
          }
        },
      );
    }
  }

  /// Central Hub for Oracle Commands (Stage 1 & 2)
  static Future<void> processCommand(String text, {String? locationContext}) async {
    if (text.isEmpty) return;

    try {
      SecureLogger.info('Oracle Processing: $text');
      
      // 1. Get real GPS location (Stage 3 & 5)
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
        );
      } catch (e) {
        SecureLogger.error('Position Error: $e');
      }

      final context = locationContext ?? (position != null 
        ? "Lat: ${position.latitude}, Lng: ${position.longitude}" 
        : "Current Coordinates");
      
      // 2. Process via Gemini Brain (Stage 2 & 5)
      final aiResponse = await getOracleLogic(text, context, position: position);
      
      // 3. Natural Narration Output (Stage 1 & 6)
      await speakAdvanced(aiResponse, accent: 'en_us');
      
    } catch (e) {
      SecureLogger.error('Oracle Pipeline Error: $e');
      await speak("The stars are cloudy, traveler. Please repeat your request.");
    }
  }

  static Future<void> stopListening() async {
    await _stt.stop();
  }



  // Lumen-1 Integration Layer - The Oracle Supreme
  static Future<String> getOracleLogic(String userQuery, String locationContext, {Position? position}) async {
    // Stage 5: Offline Fallback Check
    final hasInternet = await _checkConnectivity();
    if (!hasInternet) {
      return _getOfflineResponse(userQuery, position);
    }

    // Phase 4 & 5: Oracle Supreme - Emotional & Contextual Awareness
    final contextData = await OracleContextEngine.getFullContext(userQuery);
    
    await OracleContextEngine.updateContext({
      'last_query_energy': contextData['energy_level'],
      'last_query_sentiment': contextData['query_sentiment'],
    });

    // Check if Lumen-1 server is running
    final lumenAlive = await LumenAiService.isServerAlive();

    if (lumenAlive) {
      try {
        // Call Lumen-1 AI model for intelligent response
        final reply = await LumenAiService.askOracle(
          query: userQuery,
          locationContext: locationContext,
        );
        SecureLogger.info('[Oracle] Lumen-1 replied: ${reply.substring(0, reply.length.clamp(0, 80))}...');
        return reply;
      } on LumenException catch (e) {
        SecureLogger.warning('[Oracle] Lumen-1 error: $e — using fallback');
        // Fall through to local fallback logic
      } catch (e) {
        SecureLogger.error('[Oracle] Unexpected error: $e — using fallback');
        // Fall through to local fallback logic
      }
    } else {
      SecureLogger.warning('[Oracle] Lumen-1 server not reachable — using local logic');
    }

    // Local fallback logic (when Lumen-1 is unavailable)
    if (userQuery.toLowerCase().contains("tired") || contextData['energy_level'] == 'Low') {
      await DynamicItineraryService.mutatePlan('relax');
      return "I sense your vitality is low, traveler. Rest is a sacred part of the journey. I have adjusted your path to include more restorative moments.";
    }

    if (userQuery.toLowerCase().contains("food") || userQuery.toLowerCase().contains("hungry")) {
      return "The spice of Lanka awaits! Use my SavorLanka Vision to unlock the secrets of our traditional clay-pot wonders. Shall I guide you to a local tavern?";
    }

    // AR Time Travel trigger
    if (userQuery.toLowerCase().contains("show me before") ||
        userQuery.toLowerCase().contains("history view") ||
        userQuery.toLowerCase().contains("how did it look") ||
        userQuery.toLowerCase().contains("time travel")) {
      return "Close your eyes, traveler. When you open them, the past will greet you. Tap 'View in History' on any place to witness its ancient form through the AR portal.";
    }
    
    if (userQuery.toLowerCase().contains("near me") || userQuery.toLowerCase().contains("hidden gem")) {
      // Find true nearest gem using Haversine (Stage 5 Fix)
      final gem = await _findNearestGem(position);
      if (gem != null) {
        await DynamicItineraryService.mutatePlan('add_gem', data: {'gem': gem});
        return "The air hums with history here. I have added ${gem['name']} to your path. It is a hidden gem in ${gem['district']}. Should I whisper the directions?";
      }
    }

    return "The stars of Lanka align in your favor. Your question: '$userQuery' reaches the heart of the Oracle. How may I guide your spirit?";
  }

  static Future<Map<String, dynamic>?> _findNearestGem(Position? position) async {
    if (position == null) return null;

    try {
      final String response = await rootBundle.loadString('assets/places.json');
      final List<dynamic> places = json.decode(response);
      
      Map<String, dynamic>? nearest;
      double minDistance = double.infinity;

      for (var place in places) {
        final double distance = _calculateDistance(
          position.latitude, position.longitude,
          place['lat'], place['lng']
        );
        if (distance < minDistance) {
          minDistance = distance;
          nearest = place;
        }
      }
      return nearest;
    } catch (e) {
      SecureLogger.error('Error finding nearest gem: $e');
      return null;
    }
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) *
        (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  static Future<bool> _checkConnectivity() async {
    try {
      final result = await http.head(Uri.parse('https://google.com')).timeout(const Duration(seconds: 3));
      return result.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static String _getOfflineResponse(String query, Position? position) {
    if (query.toLowerCase().contains("near me")) {
      return "The air is still, but the land remains. We are currently offline, traveler. However, the ancient paths tell me a hidden gem is nearby. Please refer to your offline map.";
    }
    return "The stars are veiled by clouds. I am guiding you with ancient, offline wisdom for now. How may I serve your journey?";
  }

  /// Advanced Speech Synthesis (ElevenLabs/Google Cloud placeholder)
  /// In production, this would hit a cloud TTS endpoint for authentic accents.
  static Future<void> speakAdvanced(String text, {required String accent}) async {
    // 1. Check if ElevenLabs API key exists (AppConfig)
    // 2. Fetch audio stream from ElevenLabs (voice_id for SL accent)
    // 3. Buffer and play via just_audio
    
    // For now, fallback to high-quality system TTS
    await _tts.setPitch(0.9); // Cinematic deep tone
    await _tts.setSpeechRate(0.4); 
    await _tts.speak(text);
  }
}
