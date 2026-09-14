import 'package:flutter/material.dart';

/// Represents a natural, locally-sourced Sri Lankan drink
/// that can support hydration and provides natural electrolytes.
/// rural farmers and roadside vendors.
class LocalDrinkRecommendation {
  final String id;
  final String emoji;
  final Color themeColor;

  const LocalDrinkRecommendation({
    required this.id,
    required this.emoji,
    required this.themeColor,
  });
}

class WaterSafetyRule {
  final String id;
  final String icon;
  const WaterSafetyRule(this.id, this.icon);
}

/// Drinking water safety status for places and travel trails
enum WaterSafetyLevel {
  filteredOnSite, // Visitor center / certified tap available
  carrySealedWater, // No treated water on site; carry sealed SLS 894 bottled water
  remoteWilderness, // Hiking trail / rain forest; carry purification tablets or portable filter
}

/// Comprehensive health and safe hydration intelligence engine for Sri Lanka travelers.
class HealthSafetyService {
  HealthSafetyService._();
  static final HealthSafetyService instance = HealthSafetyService._();
  /// 1. The Gold Standard: King Coconut (තැඹිලි / Thambili)
  static const LocalDrinkRecommendation kingCoconut = LocalDrinkRecommendation(
    id: 'thambili',
    emoji: '🥥',
    themeColor: Color(0xFFF59E0B),
  );

  /// 2. The Northern & Eastern Pride: Fresh Palmyrah (තල් බීම)
  static const LocalDrinkRecommendation palmyrahJuice =
      LocalDrinkRecommendation(
    id: 'palmyrah',
    emoji: '🌴',
    themeColor: Color(0xFF10B981),
  );

  /// 3. Hill Country & Sacred Sites: Herbal Infusion (බෙලිමල් / රණවරා සහ කිතුල් හකුරු)
  static const LocalDrinkRecommendation herbalInfusion =
      LocalDrinkRecommendation(
    id: 'herbal_tea',
    emoji: '☕',
    themeColor: Color(0xFF8B5CF6),
  );

  /// Returns all local hero drinks for education & promotion
  List<LocalDrinkRecommendation> getAllLocalDrinks() {
    return const [kingCoconut, palmyrahJuice, herbalInfusion];
  }

  /// Returns the best contextual drink based on district or place context
  LocalDrinkRecommendation getRecommendationForLocation({
    String? district,
    String? title,
    String? category,
  }) {
    final String query =
        '${district ?? ''} ${title ?? ''} ${category ?? ''}'.toLowerCase();

    // Northern & Eastern districts -> Palmyrah
    if (query.contains('jaffna') ||
        query.contains('mannar') ||
        query.contains('kilinochchi') ||
        query.contains('trincomalee') ||
        query.contains('batticaloa') ||
        query.contains('mullaitivu')) {
      return palmyrahJuice;
    }

    // Hill country / cool climates -> Warm herbal infusions
    if (query.contains('nuwara eliya') ||
        query.contains('kandy') ||
        query.contains('ella') ||
        query.contains('hatton') ||
        query.contains('badulla') ||
        query.contains('haputale') ||
        query.contains('knuckles') ||
        query.contains('temple') ||
        query.contains('sacred')) {
      return herbalInfusion;
    }

    // Default universal tropical lifesaver -> King Coconut
    return kingCoconut;
  }

  /// Evaluates water safety guidance based on place category & terrain
  WaterSafetyLevel getWaterSafetyLevel({
    String? category,
    String? terrain,
    String? title,
  }) {
    final String query =
        '${category ?? ''} ${terrain ?? ''} ${title ?? ''}'.toLowerCase();

    // Wilderness / Hikes / Rainforests
    if (query.contains('knuckles') ||
        query.contains('sinharaja') ||
        query.contains('hike') ||
        query.contains('trail') ||
        query.contains('waterfall') ||
        query.contains('peak') ||
        query.contains('forest') ||
        query.contains('camp')) {
      return WaterSafetyLevel.remoteWilderness;
    }

    // Major ticketed museums & botanical gardens with visitor facilities
    if (query.contains('botanical') ||
        query.contains('pinnawala') ||
        query.contains('museum') ||
        query.contains('visitor center')) {
      return WaterSafetyLevel.filteredOnSite;
    }

    // Standard heritage / beach / ancient ruins
    return WaterSafetyLevel.carrySealedWater;
  }

  /// Core bottled water & food safety rules for Sri Lanka travelers
  static const List<WaterSafetyRule> essentialWaterSafetyRules = [
    WaterSafetyRule('sealed_water', 'verified'),
    WaterSafetyRule('ice', 'ac_unit'),
    WaterSafetyRule('tap_water', 'no_drinks'),
    WaterSafetyRule('ors', 'medical_services'),
  ];
}
