import 'package:flutter/material.dart';
import '../../data/models/trip_plan_model.dart';
import '../../core/utils/secure_logger.dart';

class DynamicItineraryService {
  static final ValueNotifier<TripPlan?> currentPlan = ValueNotifier(null);

  static void setPlan(TripPlan plan) {
    currentPlan.value = plan;
  }

  /// Mutates the current plan based on a specific logic type
  /// e.g., 'relax', 'add_gem', 'skip'
  static Future<void> mutatePlan(String mutationType, {Map<String, dynamic>? data}) async {
    if (currentPlan.value == null) return;

    final plan = currentPlan.value!;
    final List<ItineraryDay> updatedItinerary = List.from(plan.itinerary);

    try {
      switch (mutationType) {
        case 'relax':
          _applyRelaxMode(updatedItinerary);
          break;
        case 'add_gem':
          if (data != null && data['gem'] != null) {
            _addGemToItinerary(updatedItinerary, data['gem']);
          }
          break;
        case 'optimize_route':
          // Future: Logic to reorder items based on current location
          break;
      }

      currentPlan.value = TripPlan(
        tripSummary: plan.tripSummary,
        itinerary: updatedItinerary,
        planB: plan.planB,
        styleVariants: plan.styleVariants,
        safetyTip: plan.safetyTip,
        humanText: "The Oracle has adjusted your path for a better journey.",
        verifiedScore: plan.verifiedScore,
        kbCitations: plan.kbCitations,
        cachedAt: DateTime.now(),
      );
      
      SecureLogger.info('Itinerary Mutated: $mutationType');
    } catch (e) {
      SecureLogger.error('Mutation Error: $e');
    }
  }

  static void _applyRelaxMode(List<ItineraryDay> itinerary) {
    // Stage 5: Logic to swap high-intensity (trek/long walk) with low-intensity (rest/cafe)
    for (var day in itinerary) {
      for (int i = 0; i < day.items.length; i++) {
        final item = day.items[i];
        if (item.notes.toLowerCase().contains("trek") || item.durationMin > 180) {
          day.items[i] = ItineraryItem(
            time: item.time,
            title: "Relax & Recharge",
            type: 'rest',
            durationMin: 60,
            costLkr: 0,
            lat: item.lat,
            lng: item.lng,
            notes: "The Oracle suggests a break here to regain your vitality.",
          );
        }
      }
    }
  }

  static void _addGemToItinerary(List<ItineraryDay> itinerary, dynamic gem) {
    // Logic to add a hidden gem to the closest timeframe
    if (itinerary.isNotEmpty) {
      final firstDay = itinerary.first;
      firstDay.items.add(ItineraryItem(
        time: "16:00",
        title: gem['name'] ?? "Hidden Gem",
        type: gem['type'] ?? 'attraction',
        durationMin: 60,
        costLkr: 0,
        lat: gem['lat'] ?? 0.0,
        lng: gem['lng'] ?? 0.0,
        notes: gem['description'] ?? "Discovered by the Oracle.",
      ));
    }
  }
}
