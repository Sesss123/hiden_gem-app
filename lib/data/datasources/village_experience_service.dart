import '../models/village_experience.dart';

class VillageExperienceService {

  static Future<List<VillageExperience>> getNearbyExperiences({
    required double lat,
    required double lng,
  }) async {
    try {
      // In a real scenario, we'd use GeoHash or within-range query
      // For Stage 3 Demonstration, we provide high-quality mock data
      return [
        VillageExperience(
          id: "v1",
          name: "Traditional Clay Cooking Classes",
          district: "Matale",
          hostName: "Amma's Kitchen",
          experienceType: "Cooking",
          price: 2500,
          lat: 7.4675,
          lng: 80.6234,
          imageUrl: "https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?q=80&w=600&auto=format&fit=crop",
          description: "Learn to cook authentic Sri Lankan curries using traditional clay pots and firewood stoves.",
        ),
        VillageExperience(
          id: "v2",
          name: "Organic Rice Harvesting Experience",
          district: "Polonnaruwa",
          hostName: "Gamini Silva",
          experienceType: "Farming",
          price: 1500,
          lat: 7.9403,
          lng: 81.0188,
          imageUrl: "https://images.unsplash.com/photo-1546708973-b339540b5162?q=80&w=600&auto=format&fit=crop",
          description: "Join local farmers in the paddy fields and learn about traditional harvesting techniques.",
        ),
        VillageExperience(
          id: "v3",
          name: "Handmade Pottery Workshop",
          district: "Kandy",
          hostName: "Kumbakarana Artisans",
          experienceType: "Crafting",
          price: 3000,
          lat: 7.2906,
          lng: 80.6337,
          imageUrl: "https://images.unsplash.com/photo-1588598108426-e49053cbf995?q=80&w=600&auto=format&fit=crop",
          description: "Create your own clay masterpiece under the guidance of 3rd generation master potters.",
        ),
      ];
    } catch (e) {
      return [];
    }
  }
}
