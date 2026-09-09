import '../models/village_experience.dart';

class VillageExperienceService {

  static Future<List<VillageExperience>> getNearbyExperiences({
    required double lat,
    required double lng,
  }) async {
    // No real village-experience backend/collection exists yet — previously
    // returned hardcoded demo listings (Amma's Kitchen, Gamini Silva, etc.)
    // that shipped to real users as if they were live data.
    return [];
  }
}
