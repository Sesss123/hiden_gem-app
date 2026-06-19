import 'package:equatable/equatable.dart';

class FoodModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String culturalLegacy;
  final List<String> healthBenefits;
  final List<String> ingredients;
  final List<String> recipeSteps;
  final List<String>? recipeStepsSi;

  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final String difficultyLevel;
  final int servingsCount;

  final int estimatedCalories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final int healthRating;

  final List<String> proTips;
  final List<String> substitutions;
  
  final String region;
  final int spiceLevelValue;
  final List<String> dietaryBadges;
  final String voiceSummary;
  final String? voiceSummarySi;
  final List<String> alternateMatches;
  final double confidence;

  // SL 3.0 Intelligence Layers
  final String detectionBasis;
  final String confidenceLabel;
  final List<String> confirmedIngredients;
  final List<String> likelyIngredients;
  final List<String> optionalIngredients;
  
  final double authenticityScore;
  final String culinaryStyle;
  final String variationNote;
  
  final String nutritionReliability;
  final String reliabilityReason;
  
  final String primaryRegion;
  final List<String> secondaryInfluences;
  
  final String mealContext;
  final List<String> supportingItems;
  final List<String> allergenTags;
  
  // SL 3.0 Intelligence Engines
  final int freshnessIndex;
  final String visualQuality;
  final String visualTextureStatus;
  final String freshnessNote;
  
  final String verifiedHeritage;
  final String regionalTradition;
  final String folkloreNarrative;
  
  final String spiceRefactorAdvice;
  final List<String> personalizedSteps;
  
  final List<String> missingCompanions;
  final String pairingNotes;
  final List<String> suggestedAdditions;
  
  // Phase 1-6 Neural Compliance
  final String substitutionReasoning;
  final int hygieneScore;
  final int presentationScore;
  final String presentationAnalysis;

  final String imageUrl;

  const FoodModel({
    required this.id,
    required this.name,
    required this.description,
    required this.culturalLegacy,
    required this.healthBenefits,
    required this.ingredients,
    required this.recipeSteps,
    this.recipeStepsSi,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.difficultyLevel,
    this.servingsCount = 2,
    required this.estimatedCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.healthRating,
    required this.proTips,
    required this.substitutions,
    required this.region,
    required this.spiceLevelValue,
    required this.dietaryBadges,
    required this.voiceSummary,
    this.voiceSummarySi,
    this.alternateMatches = const [],
    required this.confidence,
    
    // SL 3.0 Intelligence
    this.detectionBasis = '',
    this.confidenceLabel = 'Exact Match',
    this.confirmedIngredients = const [],
    this.likelyIngredients = const [],
    this.optionalIngredients = const [],
    this.authenticityScore = 7.5,
    this.culinaryStyle = 'Traditional',
    this.variationNote = '',
    this.nutritionReliability = 'High',
    this.reliabilityReason = '',
    this.primaryRegion = 'Sri Lanka',
    this.secondaryInfluences = const [],
    this.mealContext = 'Standalone',
    this.supportingItems = const [],
    this.allergenTags = const [],
    
    // SL 3.0 Super Intelligence
    this.freshnessIndex = 100,
    this.visualQuality = 'Good',
    this.visualTextureStatus = 'Optimal',
    this.freshnessNote = '',
    this.verifiedHeritage = '',
    this.regionalTradition = '',
    this.folkloreNarrative = '',
    this.spiceRefactorAdvice = '',
    this.personalizedSteps = const [],
    this.missingCompanions = const [],
    this.pairingNotes = '',
    this.suggestedAdditions = const [],
    
    // Compliance 4.0
    this.substitutionReasoning = '',
    this.hygieneScore = 100,
    this.presentationScore = 100,
    this.presentationAnalysis = '',
    
    this.imageUrl = '',
  });

  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['dishName'] ?? json['name'] ?? 'Unknown Dish',
      description: json['description'] ?? '',
      culturalLegacy: json['culturalSignificance'] ?? json['culturalLegacy'] ?? '',
      healthBenefits: List<String>.from(json['healthBenefits'] is List ? json['healthBenefits'] : [json['healthBenefits'] ?? '']),
      ingredients: List<String>.from(json['ingredients'] ?? []),
      recipeSteps: List<String>.from(json['preparationSteps'] ?? json['recipeSteps'] ?? []),
      recipeStepsSi: json['preparationStepsSi'] != null ? List<String>.from(json['preparationStepsSi']) : null,
      prepTimeMinutes: (json['prepTimeMinutes'] ?? 20).toInt(),
      cookTimeMinutes: (json['cookTimeMinutes'] ?? 15).toInt(),
      difficultyLevel: json['difficultyLevel'] ?? json['difficulty'] ?? 'Medium',
      servingsCount: (json['servingsCount'] ?? 2).toInt(),
      estimatedCalories: (json['estimatedCalories'] ?? json['calories'] ?? 250).toInt(),
      protein: (json['protein'] ?? 0.0).toDouble(),
      carbs: (json['carbs'] ?? 0.0).toDouble(),
      fat: (json['fat'] ?? 0.0).toDouble(),
      fiber: (json['fiber'] ?? 0.0).toDouble(),
      healthRating: (json['healthRating'] ?? 7).toInt(),
      proTips: List<String>.from(json['proTips'] ?? []),
      substitutions: List<String>.from(json['substitutions'] ?? []),
      region: json['region'] ?? 'Sri Lanka',
      spiceLevelValue: (json['spiceLevelValue'] ?? 5).toInt(),
      dietaryBadges: List<String>.from(json['dietaryBadges'] ?? []),
      voiceSummary: json['voiceSummary'] ?? '',
      voiceSummarySi: json['voiceSummarySi'],
      alternateMatches: List<String>.from(json['alternateMatches'] ?? []),
      confidence: (json['confidence'] ?? (json['confidenceScore'] ?? 0.0)).toDouble(),
      
      // SL 3.0 Logic Parsing
      detectionBasis: json['detectionBasis'] ?? '',
      confidenceLabel: json['confidenceLabel'] ?? 'Exact Match',
      confirmedIngredients: List<String>.from(json['confirmedIngredients'] ?? []),
      likelyIngredients: List<String>.from(json['likelyIngredients'] ?? []),
      optionalIngredients: List<String>.from(json['optionalIngredients'] ?? []),
      authenticityScore: (json['authenticityScore'] ?? 7.5).toDouble(),
      culinaryStyle: json['culinaryStyle'] ?? 'Traditional',
      variationNote: json['variationNote'] ?? '',
      nutritionReliability: json['nutritionReliability'] ?? 'High',
      reliabilityReason: json['reliabilityReason'] ?? '',
      primaryRegion: json['primaryRegion'] ?? json['region'] ?? 'Sri Lanka',
      secondaryInfluences: List<String>.from(json['secondaryInfluences'] ?? []),
      mealContext: json['mealContext'] ?? 'Standalone',
      supportingItems: List<String>.from(json['supportingItems'] ?? []),
      allergenTags: List<String>.from(json['allergenTags'] ?? []),
      
      // SL 3.0 Super Intelligence Refinement
      freshnessIndex: (json['freshnessIndex'] ?? 100).toInt(),
      visualQuality: json['visualQuality'] ?? 'Good',
      visualTextureStatus: json['visualTextureStatus'] ?? 'Optimal',
      freshnessNote: json['freshnessNote'] ?? '',
      verifiedHeritage: json['verifiedHeritage'] ?? json['culturalLegacy'] ?? '',
      regionalTradition: json['regionalTradition'] ?? '',
      folkloreNarrative: json['folkloreNarrative'] ?? json['heritageFolklore'] ?? '',
      spiceRefactorAdvice: json['spiceAdjustmentAdvice'] ?? json['spiceRefactorAdvice'] ?? '',
      personalizedSteps: List<String>.from(json['personalizedSteps'] ?? []),
      missingCompanions: List<String>.from(json['missingCompanions'] ?? json['missingEssentials'] ?? []),
      pairingNotes: json['pairingNotes'] ?? '',
      suggestedAdditions: List<String>.from(json['suggestedAdditions'] ?? json['suggestedSubstitutes'] ?? []),
      
      // Compliance 4.0
      substitutionReasoning: json['substitutionReasoning'] ?? json['variationNote'] ?? '',
      hygieneScore: (json['hygieneScore'] ?? 95).toInt(),
      presentationScore: (json['presentationScore'] ?? 90).toInt(),
      presentationAnalysis: json['presentationAnalysis'] ?? json['visualQuality'] ?? '',
      
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id, name, description, culturalLegacy, healthBenefits, ingredients, recipeSteps, recipeStepsSi,
        prepTimeMinutes, cookTimeMinutes, difficultyLevel, servingsCount,
        estimatedCalories, protein, carbs, fat, fiber, healthRating,
        proTips, substitutions, region, spiceLevelValue, dietaryBadges,
        voiceSummary, voiceSummarySi, alternateMatches, confidence,
        detectionBasis, confidenceLabel, confirmedIngredients, likelyIngredients, optionalIngredients,
        authenticityScore, culinaryStyle, variationNote, nutritionReliability, reliabilityReason,
        primaryRegion, secondaryInfluences, mealContext, supportingItems, allergenTags,
        freshnessIndex, visualQuality, visualTextureStatus, freshnessNote,
        verifiedHeritage, regionalTradition, folkloreNarrative,
        missingCompanions, pairingNotes, suggestedAdditions,
        substitutionReasoning, hygieneScore, presentationScore, presentationAnalysis,
        imageUrl,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'culturalLegacy': culturalLegacy,
      'healthBenefits': healthBenefits,
      'ingredients': ingredients,
      'recipeSteps': recipeSteps,
      'recipeStepsSi': recipeStepsSi,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'difficultyLevel': difficultyLevel,
      'servingsCount': servingsCount,
      'estimatedCalories': estimatedCalories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'healthRating': healthRating,
      'proTips': proTips,
      'substitutions': substitutions,
      'region': region,
      'spiceLevelValue': spiceLevelValue,
      'dietaryBadges': dietaryBadges,
      'voiceSummary': voiceSummary,
      'voiceSummarySi': voiceSummarySi,
      'alternateMatches': alternateMatches,
      'confidence': confidence,
      'detectionBasis': detectionBasis,
      'confidenceLabel': confidenceLabel,
      'confirmedIngredients': confirmedIngredients,
      'likelyIngredients': likelyIngredients,
      'optionalIngredients': optionalIngredients,
      'authenticityScore': authenticityScore,
      'culinaryStyle': culinaryStyle,
      'variationNote': variationNote,
      'nutritionReliability': nutritionReliability,
      'reliabilityReason': reliabilityReason,
      'primaryRegion': primaryRegion,
      'secondaryInfluences': secondaryInfluences,
      'mealContext': mealContext,
      'supportingItems': supportingItems,
      'allergenTags': allergenTags,
      'freshnessIndex': freshnessIndex,
      'visualQuality': visualQuality,
      'visualTextureStatus': visualTextureStatus,
      'freshnessNote': freshnessNote,
      'verifiedHeritage': verifiedHeritage,
      'regionalTradition': regionalTradition,
      'folkloreNarrative': folkloreNarrative,
      'spiceRefactorAdvice': spiceRefactorAdvice,
      'personalizedSteps': personalizedSteps,
      'missingCompanions': missingCompanions,
      'pairingNotes': pairingNotes,
      'suggestedAdditions': suggestedAdditions,
      'substitutionReasoning': substitutionReasoning,
      'hygieneScore': hygieneScore,
      'presentationScore': presentationScore,
      'presentationAnalysis': presentationAnalysis,
      'imageUrl': imageUrl,
    };
  }

  FoodModel copyWith({
    String? id,
    String? name,
    String? description,
    String? culturalLegacy,
    List<String>? healthBenefits,
    List<String>? ingredients,
    List<String>? recipeSteps,
    List<String>? recipeStepsSi,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    String? difficultyLevel,
    int? servingsCount,
    int? estimatedCalories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    int? healthRating,
    List<String>? proTips,
    List<String>? substitutions,
    String? region,
    int? spiceLevelValue,
    List<String>? dietaryBadges,
    String? voiceSummary,
    String? voiceSummarySi,
    List<String>? alternateMatches,
    double? confidence,
    String? detectionBasis,
    String? confidenceLabel,
    List<String>? confirmedIngredients,
    List<String>? likelyIngredients,
    List<String>? optionalIngredients,
    double? authenticityScore,
    String? culinaryStyle,
    String? variationNote,
    String? nutritionReliability,
    String? reliabilityReason,
    String? primaryRegion,
    List<String>? secondaryInfluences,
    String? mealContext,
    List<String>? supportingItems,
    List<String>? allergenTags,
    int? freshnessIndex,
    String? visualQuality,
    String? visualTextureStatus,
    String? freshnessNote,
    String? verifiedHeritage,
    String? regionalTradition,
    String? folkloreNarrative,
    String? spiceRefactorAdvice,
    List<String>? personalizedSteps,
    List<String>? missingCompanions,
    String? pairingNotes,
    List<String>? suggestedAdditions,
    String? substitutionReasoning,
    int? hygieneScore,
    int? presentationScore,
    String? presentationAnalysis,
    String? imageUrl,
  }) {
    return FoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      culturalLegacy: culturalLegacy ?? this.culturalLegacy,
      healthBenefits: healthBenefits ?? this.healthBenefits,
      ingredients: ingredients ?? this.ingredients,
      recipeSteps: recipeSteps ?? this.recipeSteps,
      recipeStepsSi: recipeStepsSi ?? this.recipeStepsSi,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      servingsCount: servingsCount ?? this.servingsCount,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      healthRating: healthRating ?? this.healthRating,
      proTips: proTips ?? this.proTips,
      substitutions: substitutions ?? this.substitutions,
      region: region ?? this.region,
      spiceLevelValue: spiceLevelValue ?? this.spiceLevelValue,
      dietaryBadges: dietaryBadges ?? this.dietaryBadges,
      voiceSummary: voiceSummary ?? this.voiceSummary,
      voiceSummarySi: voiceSummarySi ?? this.voiceSummarySi,
      alternateMatches: alternateMatches ?? this.alternateMatches,
      confidence: confidence ?? this.confidence,
      detectionBasis: detectionBasis ?? this.detectionBasis,
      confidenceLabel: confidenceLabel ?? this.confidenceLabel,
      confirmedIngredients: confirmedIngredients ?? this.confirmedIngredients,
      likelyIngredients: likelyIngredients ?? this.likelyIngredients,
      optionalIngredients: optionalIngredients ?? this.optionalIngredients,
      authenticityScore: authenticityScore ?? this.authenticityScore,
      culinaryStyle: culinaryStyle ?? this.culinaryStyle,
      variationNote: variationNote ?? this.variationNote,
      nutritionReliability: nutritionReliability ?? this.nutritionReliability,
      reliabilityReason: reliabilityReason ?? this.reliabilityReason,
      primaryRegion: primaryRegion ?? this.primaryRegion,
      secondaryInfluences: secondaryInfluences ?? this.secondaryInfluences,
      mealContext: mealContext ?? this.mealContext,
      supportingItems: supportingItems ?? this.supportingItems,
      allergenTags: allergenTags ?? this.allergenTags,
      freshnessIndex: freshnessIndex ?? this.freshnessIndex,
      visualQuality: visualQuality ?? this.visualQuality,
      visualTextureStatus: visualTextureStatus ?? this.visualTextureStatus,
      freshnessNote: freshnessNote ?? this.freshnessNote,
      verifiedHeritage: verifiedHeritage ?? this.verifiedHeritage,
      regionalTradition: regionalTradition ?? this.regionalTradition,
      folkloreNarrative: folkloreNarrative ?? this.folkloreNarrative,
      spiceRefactorAdvice: spiceRefactorAdvice ?? this.spiceRefactorAdvice,
      personalizedSteps: personalizedSteps ?? this.personalizedSteps,
      missingCompanions: missingCompanions ?? this.missingCompanions,
      pairingNotes: pairingNotes ?? this.pairingNotes,
      suggestedAdditions: suggestedAdditions ?? this.suggestedAdditions,
      substitutionReasoning: substitutionReasoning ?? this.substitutionReasoning,
      hygieneScore: hygieneScore ?? this.hygieneScore,
      presentationScore: presentationScore ?? this.presentationScore,
      presentationAnalysis: presentationAnalysis ?? this.presentationAnalysis,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
