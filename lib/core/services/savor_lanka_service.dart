import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/secure_logger.dart';
import '../../data/models/food_model.dart';
import '../../core/config/app_config.dart';

class SavorLankaService {
  static final String _modelName = AppConfig.llmModelName; 
  final String apiKey;
  GenerativeModel? _model;

  SavorLankaService({required this.apiKey}) {
    if (apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: _modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );
    }
  }

  Future<FoodModel?> identifyFood(File imageFile, {
    String spicePreference = 'Medium',
    String userMode = 'Tourist',
  }) async {
    // 🏛️ Self-Hosted BYOM Custom Model Integration (D:\ai model\food_scan_ai)
    if (apiKey.isEmpty || _model == null) {
      return _callCustomByomFoodScanner(imageFile, spicePreference, userMode);
    }
    try {
      final bytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart(_buildUltimatePrompt(spicePreference, userMode)),
          DataPart('image/jpeg', bytes),
        ])
      ];

      // BUG-079: Limit generative AI call with 15s timeout to prevent freezing the camera UI
      final response = await _model!.generateContent(content).timeout(
        const Duration(seconds: 15),
      );
      final text = response.text;

      if (text == null) {
        return _callCustomByomFoodScanner(imageFile, spicePreference, userMode);
      }

      final Map<String, dynamic> data = json.decode(text);
      return FoodModel.fromJson(data);
    } on TimeoutException catch (e) {
      SecureLogger.error('Savor Lanka Commercial LLM timed out (15s limit). Falling back to BYOM scanner.', e);
      return _callCustomByomFoodScanner(imageFile, spicePreference, userMode);
    } catch (e) {
      SecureLogger.warning('Savor Lanka Commercial LLM skipped or failed: $e');
      return _callCustomByomFoodScanner(imageFile, spicePreference, userMode);
    }
  }


  Future<FoodModel?> _callCustomByomFoodScanner(File imageFile, String spicePreference, String userMode) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      
      // BUG-099: Validate image file integrity before starting conversions/GZIP encoding
      if (imageBytes.isEmpty || imageBytes.length < 4) {
        SecureLogger.warning("Custom BYOM Scanner: Image file is empty or corrupted. Aborting scan.");
        return null;
      }

      final compressedBytes = GZipCodec().encode(imageBytes);
      final base64Image = base64Encode(compressedBytes);

      final response = await http.post(
        Uri.parse('${AppConfig.pythonUrl}/food/scan'),
        headers: {
          'Content-Type': 'application/json',
          'Content-Encoding': 'gzip', // Signal to server that payload is compressed
        },
        body: json.encode({
          'image_base64': base64Image,
          'user_mode': userMode,
          'spice_preference': spicePreference,
          'compressed': true,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // BUG-139: Validate that the response is actually JSON before decoding.
        // Servers under load may return HTML error pages or empty bodies.
        final contentType = response.headers['content-type'] ?? '';
        final body = response.body.trim();
        if (body.isEmpty || !contentType.contains('application/json')) {
          SecureLogger.warning(
            'Custom BYOM Scanner: unexpected response format '
            '(content-type: $contentType, body length: ${body.length}). Skipping decode.',
          );
          return null;
        }
        final Map<String, dynamic> data = json.decode(body);
        return FoodModel.fromJson(data);
      }
    } on TimeoutException catch (e) {
      SecureLogger.error('Custom BYOM Food Scanner timed out (15s limit)', e);
    } on HttpException catch (e) {
      SecureLogger.error('Custom BYOM Food Scanner HTTP protocol error', e);
    } on SocketException catch (e) {
      SecureLogger.error('Custom BYOM Food Scanner connection failed: Network unreachable', e);
    } catch (e) {
      SecureLogger.warning('Custom BYOM Food Scanner offline or unreachable: $e');
    }
    return null;
  }

  String _buildUltimatePrompt(String spicePref, String userMode) {
    return '''
    You are a world-class Culinary Intelligence System specializing in Sri Lankan cuisine. 
    Analyze the provided image through 6 distinct Neural Intelligence Phases:

    ### PHASE 1: Dynamic Spice Customization
    - Refactor the traditional recipe for the user's Profile: $userMode with $spicePref spice preference.
    - Provide "personalizedSteps" and "spiceRefactorAdvice" (e.g., "Milder ratios for $userMode palette").

    ### PHASE 2: Visual Freshness & Maturity
    - Analyze visual markers (vibrancy, steam, texture).
    - Provide "freshnessIndex" (0-100) and "freshnessNote".

    ### PHASE 3: Visual Cross-Match Substitution
    - Identify dishes that look visually similar but are different (e.g., Polos vs Meat).
    - Provide "alternateMatches" and "substitutionReasoning" explaining the visual logic.

    ### PHASE 4: Cultural Storyteller (Heritage)
    - Provide "verifiedHeritage" (Facts), "regionalTradition", and "folkloreNarrative" (Myths).

    ### PHASE 5: Culinary Gap Detection
    - Identify missing essential accompaniments.
    - Provide "missingCompanions" and "pairingNotes".

    ### PHASE 6: Visual Hygiene & Presentation Integrity
    - Analyze plating cleanliness, presentation style, and food integrity.
    - Provide "hygieneScore", "presentationScore", and "presentationAnalysis".

    ### JSON Structure:
    {
      "dishName": "...",
      "description": "...",
      "culturalSignificance": "...",
      "healthBenefits": ["..."],
      "ingredients": ["..."],
      "confirmedIngredients": ["..."],
      "likelyIngredients": ["..."],
      "optionalIngredients": ["..."],
      "preparationSteps": ["..."],
      "personalizedSteps": ["..."],
      "preparationStepsSi": ["..."],
      "prepTimeMinutes": 20,
      "cookTimeMinutes": 30,
      "difficultyLevel": "Easy/Medium/Hard",
      "servingsCount": 2,
      "estimatedCalories": 350,
      "protein": 12.5,
      "carbs": 45.0,
      "fat": 15.0,
      "fiber": 5.0,
      "healthRating": 8,
      "proTips": ["..."],
      "substitutions": ["..."],
      "region": "...",
      "primaryRegion": "...",
      "secondaryInfluences": ["..."],
      "spiceLevelValue": 7,
      "dietaryBadges": ["..."],
      "voiceSummary": "...",
      "voiceSummarySi": "...",
      "alternateMatches": ["..."],
      "substitutionReasoning": "...",
      "confidence": 0.95,
      "detectionBasis": "...",
      "confidenceLabel": "...",
      "authenticityScore": 92,
      "culinaryStyle": "Traditional",
      "variationNote": "...",
      "nutritionReliability": "High",
      "reliabilityReason": "...",
      "mealContext": "Standalone",
      "supportingItems": ["..."],
      "allergenTags": ["..."],
      "freshnessIndex": 85,
      "freshnessNote": "...",
      "verifiedHeritage": "...",
      "regionalTradition": "...",
      "folkloreNarrative": "...",
      "spiceRefactorAdvice": "...",
      "missingCompanions": ["..."],
      "pairingNotes": "...",
      "suggestedAdditions": ["..."],
      "hygieneScore": 98,
      "presentationScore": 95,
      "presentationAnalysis": "..."
    }
    ''';
  }
}
