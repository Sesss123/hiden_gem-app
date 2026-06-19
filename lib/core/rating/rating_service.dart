import 'package:in_app_review/in_app_review.dart';
import '../../data/datasources/user_preference_service.dart';
import 'package:flutter/foundation.dart';

class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  final InAppReview _inAppReview = InAppReview.instance;

  Future<void> checkAndRequestReview() async {
    final profile = UserPreferenceService.getProfile();
    final trips = profile.totalTripsGenerated;

    // Trigger review prompt after 3 generated plans
    if (trips == 3) {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        debugPrint("[Rating] In-app review requested.");
      }
    }
  }

  Future<void> forceRequestReview() async {
    if (await _inAppReview.isAvailable()) {
      await _inAppReview.requestReview();
    } else {
      await openStore();
    }
  }

  Future<void> openStore() async {
    await _inAppReview.openStoreListing(
      appStoreId: '...', // Update with real ID after submission
    );
  }
}
