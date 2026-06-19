import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/guide_analytics_snapshot.dart';
import '../models/user_profile.dart';

final analyticsRepositoryProvider = Provider((ref) => AnalyticsRepository());

class AnalyticsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Retrieves the latest cached snapshot for a guide.
  Future<GuideAnalyticsSnapshot?> getLatestSnapshot(String guideId) async {
    final snapshot = await _firestore.collection('guide_analytics')
        .where('guideId', isEqualTo: guideId)
        .orderBy('periodEnd', descending: true)
        .limit(1)
        .get();
        
    if (snapshot.docs.isEmpty) return null;
    return GuideAnalyticsSnapshot.fromJson(snapshot.docs.first.data());
  }

  /// Generates an explainable trust score and snapshot for a guide.
  Future<GuideAnalyticsSnapshot> generateGuideSnapshot(String guideId) async {
    final userDoc = await _firestore.collection('users').doc(guideId).get();
    if (!userDoc.exists) throw Exception("GUIDE_NOT_FOUND");
    
    final user = UserProfile.fromJson(userDoc.data()!);
    final guide = user.guideProfile;
    
    // 1. Core Metrics Aggregation
    final sessions = await _firestore.collection('tour_sessions')
        .where('guideId', isEqualTo: guideId)
        .where('status', isEqualTo: 'completed')
        .get();

    final incidents = await _firestore.collection('incident_reports')
        .where('guideId', isEqualTo: guideId)
        .get();

    // 2. Component Calculations
    double docsScore = (guide?.verifiedBadge ?? false) ? 20.0 : 5.0;
    if (guide?.licenseDocUrl != null) docsScore += 5;
    if (guide?.nicDocUrl != null) docsScore += 5;
    if (docsScore > 20) docsScore = 20;

    double ratingsScore = (guide?.ratingAverage ?? 5.0) * 6; // max 30 (5 * 6 = 30)
    
    // Safety from reviews or incidents
    int criticalIncidents = 0;
    int totalIncidents = 0;
    for (var doc in incidents.docs) {
      final data = doc.data();
      totalIncidents++;
      if (data['severity'] == 'critical') criticalIncidents++;
    }
    
    double safetyScore = 20.0 - (criticalIncidents * 10.0);
    if (safetyScore < 0) safetyScore = 0;

    double completionScore = 20.0;
    if (sessions.docs.isEmpty && totalIncidents > 0) completionScore = 0;
    // (In reality, we'd compare started vs completed sessions)

    double penalties = 0.0;
    if (user.role == 'user') penalties -= 50.0; // Blocked/Downgraded role

    // 3. Final Trust Score
    double totalTrust = docsScore + ratingsScore + safetyScore + completionScore + penalties;
    int finalScore = totalTrust.clamp(0.0, 100.0).toInt();

    String tier = "Restricted";
    if (finalScore >= 90) {
      tier = "Excellent";
    } else if (finalScore >= 75) {
      tier = "Strong";
    } else if (finalScore >= 50) {
      tier = "Watchlist";
    }

    final factors = {
      'documents': docsScore,
      'ratings': ratingsScore,
      'safety': safetyScore,
      'completion': completionScore,
      'penalties': penalties,
    };

    final snapshot = GuideAnalyticsSnapshot(
      guideId: guideId,
      periodStart: DateTime.now().subtract(const Duration(days: 30)),
      periodEnd: DateTime.now(),
      completedSessions: sessions.docs.length,
      touristsServed: guide?.travelersServed ?? 0,
      avgOverallRating: guide?.ratingAverage ?? 5.0,
      incidentCount: totalIncidents,
      criticalIncidentCount: criticalIncidents,
      trustScore: finalScore,
      trustTier: tier,
      trustScoreFactors: factors,
    );

    // Save snapshot to history
    await _firestore.collection('guide_analytics').add(snapshot.toJson());
    
    return snapshot;
  }

  Stream<List<GuideAnalyticsSnapshot>> getGuideHistory(String guideId) {
    return _firestore.collection('guide_analytics')
        .where('guideId', isEqualTo: guideId)
        .orderBy('periodEnd', descending: true)
        .limit(12)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GuideAnalyticsSnapshot.fromJson(doc.data()))
            .toList());
  }

  /// Admin level leaderboard metrics
  Stream<List<Map<String, dynamic>>> getGuideLeaderboard() {
    return _firestore.collection('users')
        .where('role', isEqualTo: 'guide_approved')
        .orderBy('ratingAverage', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'uid': doc.id,
            'name': data['vibe'] ?? 'Guide',
            'rating': data['ratingAverage'] ?? 0.0,
            'served': data['totalTouristsServed'] ?? 0,
          };
        }).toList());
  }
}
