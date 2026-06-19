import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trip_plan_model.dart';
import '../datasources/user_preference_service.dart';
import '../../core/config/app_config.dart';
import 'live_events_service.dart';
import 'dynamic_content_service.dart';
import '../../core/network/secure_http_client.dart';

class AiTripService {
  static String get _baseUrl => AppConfig.baseUrl;
  static bool get ragEnabled => AppConfig.ragEnabled;
  static String get _apiKey => AppConfig.tripMeApiKey;

  // We reuse the secure client instance
  static final _client = SecureHttpClient(http.Client());

  static Future<TripPlan> generateTrip({
    required String origin,
    required double fromLat,
    required double fromLng,
    required String destination,
    required int days,
    required String startDate,
    required String groupType,
    required String pace,
    required int budgetLkr,
    required String style,
    required List<String> interests,
    required String transportPreference,
    required List<String> constraints,
    required List<String> mustInclude,
    required List<String> avoid,
  }) async {
    final url = Uri.parse("$_baseUrl/trip/plan");
    final userProfile = UserPreferenceService.getProfile();
    
    // 1. Fetch dynamic events for real-time AI grounding
    final dynamicEvents = await DynamicContentService.fetchEvents();

    final body = {
      "origin": origin,
      "destination": destination,
      "days": days,
      "start_date": startDate,
      "group_type": groupType,
      "pace": pace,
      "budget_lkr": budgetLkr,
      "style": style,
      "transport_preference": transportPreference,
      "interests": interests,
      "constraints": constraints,
      "must_include": mustInclude,
      "avoid": avoid,
      "language_code": userProfile.languageCode ?? "en",
      "user_context": {
        ...userProfile.toJson(),
        "live_cultural_events": LiveEventsService.getEventsForDates(
          startDate, 
          days, 
          dynamicEvents: dynamicEvents
        ),
      },
    };

    // Phase 3: Contextual AI Memory — inject past trip history into AI prompt
    final tripHistory = userProfile.tripHistory;
    if (tripHistory.isNotEmpty) {
      body['user_context'] = {
        ...(body['user_context'] as Map<String, dynamic>),
        'memory_context': {
          'visited_recently': tripHistory.take(5).toList(),
          'avoid_repeat_destinations': tripHistory.isNotEmpty,
        },
      };
    }

    int retryCount = 0;
    const maxRetries = 2;

    while (retryCount <= maxRetries) {
      try {
        final response = await _client.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "X-TripMe-Key": _apiKey,
          },
          body: json.encode(body),
        ).timeout(const Duration(seconds: 45));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          final plan = TripPlan.fromJson(data);
          // Save destination to trip history for future AI memory
          await _saveTripToHistory(destination);
          return plan;
        } else if (response.statusCode == 429) {
          throw Exception("Rate limit reached. Try again soon.");
        } else if (response.statusCode >= 500) {
          if (retryCount < maxRetries) {
            retryCount++;
            await Future.delayed(Duration(seconds: 2 * retryCount));
            continue;
          }
          throw Exception("TripMe.ai is experiencing issues. Please try again later.");
        } else {
          String errorMessage = "Unknown API error (${response.statusCode})";
          try {
            final errorData = json.decode(response.body) as Map<String, dynamic>;
            errorMessage = errorData['detail']?['message'] as String? ?? errorMessage;
          } catch (_) {}
          throw Exception("TripMe.ai: $errorMessage");
        }
      } catch (e) {
        if (retryCount < maxRetries && (e.toString().contains('SocketException') || e.toString().contains('Timeout'))) {
          retryCount++;
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        }
        throw Exception("Could not connect to TripMe.ai. Check your connection.");
      }
    }
    throw Exception("Maximum retries reached.");
  }

  // Local extraction logic no longer needed as backend returns clean JSON
  // static String _extractJson(String text) { ... }

  /// Save trip destination to user's memory history (Phase 3)
  static Future<void> _saveTripToHistory(String destination) async {
    try {
      final profile = UserPreferenceService.getProfile();
      if (!profile.tripHistory.contains(destination)) {
        profile.tripHistory.insert(0, destination); // most recent first
        if (profile.tripHistory.length > 20) {
          profile.tripHistory.removeLast(); // cap at 20
        }
        await UserPreferenceService.saveProfile(profile);
      }
    } catch (_) {} // Non-critical, never block generation
  }
}


