import 'dart:convert';
import '../models/food_model.dart';
import '../datasources/trip_cache_service.dart';
import '../../core/utils/secure_logger.dart';

class FoodRepository {
  // Save a food scan result to the personal cookbook
  static Future<void> saveFood(FoodModel food) async {
    try {
      final box = TripCacheService.savedFoodsBox;
      final foodJson = jsonEncode({
        ...food.toJson(),
        'savedAt': DateTime.now().toIso8601String(),
      });
      await box.put(food.id, foodJson);
    } catch (e) {
      SecureLogger.error('[FoodRepository] Failed to save food', e);
    }
  }

  // Retrieve all saved food items
  static List<FoodModel> getSavedFoods() {
    try {
      final box = TripCacheService.savedFoodsBox;
      return box.values.map((raw) {
        final Map<String, dynamic> data = jsonDecode(raw);
        return FoodModel.fromJson(data);
      }).toList()
        ..sort((a, b) => b.id.compareTo(a.id)); // Newest first
    } catch (e) {
      SecureLogger.error('[FoodRepository] Failed to fetch saved foods', e);
      return [];
    }
  }

  // Delete a food item from the cookbook
  static Future<void> deleteFood(String id) async {
    try {
      final box = TripCacheService.savedFoodsBox;
      await box.delete(id);
    } catch (e) {
      SecureLogger.error('[FoodRepository] Failed to delete food', e);
    }
  }

  // Check if a food item is already saved
  static bool isSaved(String id) {
    try {
      final box = TripCacheService.savedFoodsBox;
      return box.containsKey(id);
    } catch (e) {
      return false;
    }
  }
}
