import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/secure_logger.dart';
import '../../data/models/food_model.dart';
import '../../core/config/app_config.dart';

class SavorLankaService {
  // Uses Firebase AI Logic pipeline with Gemini Multimodal Model
  static final String _modelName = AppConfig.llmModelName; 
  final String apiKey;
  late final GenerativeModel _model;

  SavorLankaService({required this.apiKey}) {
    if (apiKey.isEmpty) {
      SecureLogger.error('SavorLankaService: API Key is empty! AI identification will fail.');
    }
    _model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  Future<FoodModel?> identifyFood(File imageFile, {
    String spicePreference = 'Medium',
    String userMode = 'Tourist',
  }) async {
    if (apiKey.isEmpty) {
      SecureLogger.error('Savor Lanka: Cannot identify food because API Key is empty.');
      return null;
    }
    try {
      final bytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart(_buildUltimatePrompt(spicePreference, userMode)),
          DataPart('image/jpeg', bytes),
        ])
      ];

      final response = await _model.generateContent(content);
      final text = response.text;

      if (text == null) {
        SecureLogger.error('Savor Lanka: Empty response from Gemini');
        return null;
      }

      final Map<String, dynamic> data = json.decode(text);
      return FoodModel.fromJson(data);
    } catch (e) {
      SecureLogger.error('Savor Lanka Identification Error: $e');
      return null;
    }
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
